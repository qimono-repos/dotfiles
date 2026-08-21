#!/usr/bin/env bash
# One-shot smoke test for the fleet LLM stack (Qimono dotfiles).
# Pulls nothing; expects `ollama` installed, service running, model pulled.
#
# Usage:
#   ./hello-llm.sh                    # test OLLAMA_MODEL (default gemma4:e2b)
#   OLLAMA_MODEL=gemma4:e4b ./hello-llm.sh

set -uo pipefail

MODEL="${OLLAMA_MODEL:-gemma4:e2b}"
PROMPT="Reply with exactly: FLEET-LLM-OK"
API="http://127.0.0.1:11434"

command -v ollama >/dev/null 2>&1 || { echo "FAIL: ollama not on PATH" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "FAIL: curl not found" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 not found" >&2; exit 1; }
ollama list 2>/dev/null | awk '{print $1}' | grep -qx -- "$MODEL" \
  || { echo "FAIL: ${MODEL} not pulled (run install-ollama-stack.sh)" >&2; exit 1; }

echo "model : ${MODEL}"
echo "prompt: ${PROMPT}"
echo

# The JSON API avoids the CLI's interactive spinner escape codes and gives
# machine-readable timing stats.
RESP="$(curl -fsS --max-time 300 "${API}/api/generate" \
  -d "{\"model\":\"${MODEL}\",\"prompt\":\"${PROMPT}\",\"stream\":false}")" || {
  echo "FAIL: API request error — is the service up? (systemctl status ollama)" >&2
  exit 1
}

PARSE='
import json, sys
d = json.load(sys.stdin)
text = (d.get("response") or "").strip()
secs = d.get("eval_duration", 0) / 1e9 or 1.0
rate = d.get("eval_count", 0) / secs
print(text)
sys.stderr.write(
    "stats: load={:.1f}s  total={:.1f}s  eval={:.1f} tokens/s\n".format(
        d.get("load_duration", 0) / 1e9,
        d.get("total_duration", 0) / 1e9,
        rate,
    )
)
'

if ! OUT="$(printf '%s' "$RESP" | python3 -c "$PARSE")"; then
  echo "FAIL: could not parse API response" >&2
  printf '%s\n' "$RESP" >&2
  exit 1
fi

printf '%s\n' "$OUT"
BODY="$(printf '%s\n' "$OUT" | head -n 1)"

echo
if [[ "$BODY" == *FLEET-LLM-OK* ]]; then
  echo "PASS: ${MODEL} answered correctly"
else
  echo "WARN: model responded but without the exact marker string"
fi

# Unload so the RAM returns to the system right away.
ollama stop "$MODEL" >/dev/null 2>&1 && echo "unloaded ${MODEL} (RAM freed; it reloads on next run)"
