#!/usr/bin/env bash
# RAMageddon fleet probe — is every node's Ollama reachable over Tailscale?
#
# Usage:
#   ./fleet-status.sh                     # probe the default known nodes
#   FLEET_HOSTS="a.tailbb5c9e.ts.net b..." ./fleet-status.sh
#   FLEET_PORT=11434 ./fleet-status.sh    # override port
#
# A node answers UP only if its Ollama API is exposed beyond 127.0.0.1
# (see llm/RAMageddon.md "Exposing Ollama to the tailnet").

set -uo pipefail

FLEET_HOSTS="${FLEET_HOSTS:-qimono-localhost.tailbb5c9e.ts.net qi-mini-pc-ubu-rr.tailbb5c9e.ts.net}"
FLEET_PORT="${FLEET_PORT:-11434}"

up()   { printf '  %-38s UP      %s\n' "$1" "$2"; }
down() { printf '  %-38s DOWN    %s\n' "$1" "$2"; }

echo "=== qimono LLM fleet on :${FLEET_PORT} — $(date '+%Y-%m-%d %H:%M') ==="
echo

FAIL=0
for host in ${FLEET_HOSTS}; do
  short="${host%%.*}"
  if ! tags="$(curl -fsS --max-time 4 "http://${host}:${FLEET_PORT}/api/tags" 2>/dev/null)"; then
    down "$short" "offline or API not tailnet-exposed"
    FAIL=1
    continue
  fi
  models="$(printf '%s' "$tags" \
            | grep -o '"name":"[^"]*"' | cut -d'"' -f4 \
            | paste -sd', ' -)"
  up "$short" "${models:-reachable, but no models pulled}"
done

echo
(( FAIL )) && echo "hint: missing nodes need tailscale up + the OLLAMA_HOST drop-in (RAMageddon P1/P2)" >&2
exit "$FAIL"
