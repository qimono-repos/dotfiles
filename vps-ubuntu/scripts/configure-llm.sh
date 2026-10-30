#!/usr/bin/env bash
# Qimono vps-ubuntu — wire Codex CLI + opencode to LLM providers.
#
# Secrets live in ONE gitignored file (default ~/.config/qimono/providers.env).
# Generated configs reference those vars, never the raw keys:
#   ~/.codex/config.toml            (Codex model_providers / auth mode)
#   ~/.config/opencode/opencode.json (opencode providers + model)
#   ~/.bashrc / ~/.profile / ~/.zshrc (guarded source + PATH block)
#
# Idempotent: safe to re-run after editing providers.env. Provider entries that
# are not backed by a non-empty var are skipped; other config keys are kept.
#
# Usage:
#   ./configure-llm.sh
#   ./configure-llm.sh --dry-run
#   ./configure-llm.sh --env-file ./providers.env      # install + use this copy
#   ./configure-llm.sh --codex-model gpt-6.1-sol \
#                      --opencode-model anthropic/claude-sonnet-5-5
#
# Supported vars (see ../llm/providers.env.example):
#   OPENAI_API_KEY, ANTHROPIC_API_KEY, OPENROUTER_API_KEY,
#   GOOGLE_GENERATIVE_AI_API_KEY, OPENROUTER_MODEL,
#   OLLAMA_BASE_URL, OLLAMA_API_KEY, OLLAMA_MODEL,
#   CUSTOM_BASE_URL, CUSTOM_API_KEY, CUSTOM_MODEL
# Optional selection: CODEX_PROVIDER, CODEX_MODEL, OPENCODE_MODEL

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/qimono/providers.env"
ENV_FILE="$DEFAULT_ENV_FILE"
SOURCE_ENV_FILE=""
CODEX_MODEL="${CODEX_MODEL:-}"
OPENCODE_MODEL="${OPENCODE_MODEL:-}"
CODEX_PROVIDER="${CODEX_PROVIDER:-}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)        DRY_RUN=1 ;;
    --env-file)       SOURCE_ENV_FILE="${2:?--env-file needs a path}"; shift ;;
    --codex-model)    CODEX_MODEL="${2:?--codex-model needs a value}"; shift ;;
    --opencode-model) OPENCODE_MODEL="${2:?--opencode-model needs a value}"; shift ;;
    --provider)       CODEX_PROVIDER="${2:?--provider needs a value}"; shift ;;
    -h|--help)        sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }
plan() { printf '  %-40s PLAN  %s\n' "$1" "$2"; }

has() { [[ -n "${!1:-}" ]]; }

# CLI flags win over values in providers.env.
CLI_CODEX_MODEL="$CODEX_MODEL"
CLI_OPENCODE_MODEL="$OPENCODE_MODEL"
CLI_CODEX_PROVIDER="$CODEX_PROVIDER"

CODEX_CONFIG="${CODEX_HOME:-$HOME/.codex}/config.toml"
OPENCODE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
MARK_BEGIN="# >>> qimono vps-ubuntu LLM env >>>"
MARK_END="# <<< qimono vps-ubuntu LLM env <<<"

echo "=== LLM wiring on $(hostname) — $(date '+%Y-%m-%d %H:%M') ==="
echo

# ---- 1. install / resolve the single secrets file --------------------------
if [[ -n "$SOURCE_ENV_FILE" ]]; then
  [[ -r "$SOURCE_ENV_FILE" ]] || { bad "env file" "$SOURCE_ENV_FILE not readable"; exit 1; }
  if (( DRY_RUN )); then
    plan "env file" "install $SOURCE_ENV_FILE -> $ENV_FILE"
  else
    mkdir -p "$(dirname "$ENV_FILE")"
    install -m 600 "$SOURCE_ENV_FILE" "$ENV_FILE"
    ok "env file" "$ENV_FILE (installed from $SOURCE_ENV_FILE)"
  fi
elif [[ -f "$ENV_FILE" ]]; then
  ok "env file" "$ENV_FILE"
else
  if (( DRY_RUN )); then
    plan "env file" "create $ENV_FILE from llm/providers.env.example"
  else
    mkdir -p "$(dirname "$ENV_FILE")"
    install -m 600 "$ROOT/llm/providers.env.example" "$ENV_FILE"
    ok "env file" "$ENV_FILE (created from template — fill in your keys)"
  fi
fi

# ---- 2. load keys ----------------------------------------------------------
LOAD_FILE="$ENV_FILE"
# In a dry run we don't install --env-file yet; read it directly.
(( DRY_RUN )) && [[ -n "$SOURCE_ENV_FILE" ]] && LOAD_FILE="$SOURCE_ENV_FILE"
if [[ -f "$LOAD_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$LOAD_FILE"
  set +a
  chmod 600 "$ENV_FILE" 2>/dev/null || true
fi

[[ -n "$CLI_CODEX_MODEL" ]]    && CODEX_MODEL="$CLI_CODEX_MODEL"
[[ -n "$CLI_OPENCODE_MODEL" ]] && OPENCODE_MODEL="$CLI_OPENCODE_MODEL"
[[ -n "$CLI_CODEX_PROVIDER" ]] && CODEX_PROVIDER="$CLI_CODEX_PROVIDER"

# ---- 3. pick the Codex provider -------------------------------------------
if [[ -z "$CODEX_PROVIDER" ]]; then
  if has CUSTOM_BASE_URL; then
    CODEX_PROVIDER=custom
  elif has OPENROUTER_API_KEY; then
    CODEX_PROVIDER=openrouter
  elif has OLLAMA_BASE_URL; then
    CODEX_PROVIDER=qimono_ollama
  elif has OPENAI_API_KEY; then
    CODEX_PROVIDER=openai
  fi
fi
[[ -n "$CODEX_PROVIDER" ]] && ok "codex provider" "$CODEX_PROVIDER" || warn "codex provider" "none detected (fill providers.env)"

# If no explicit Codex model, borrow the provider's model where we have one.
if [[ -z "$CODEX_MODEL" ]]; then
  case "$CODEX_PROVIDER" in
    openrouter)    CODEX_MODEL="${OPENROUTER_MODEL:-}" ;;
    qimono_ollama) CODEX_MODEL="${OLLAMA_MODEL:-}" ;;
    custom)        CODEX_MODEL="${CUSTOM_MODEL:-}" ;;
  esac
fi
[[ -n "$CODEX_MODEL" ]] && ok "codex model" "$CODEX_MODEL"

# ---- 4. write ~/.codex/config.toml ----------------------------------------
render_codex_config() {
  local base
  echo "# Managed by vps-ubuntu/scripts/configure-llm.sh — rerun to regenerate."
  echo "# Secrets are kept in ${ENV_FILE}; this file only references env vars."
  echo

  if [[ "$CODEX_PROVIDER" == "openai" ]]; then
    echo 'forced_login_method = "api"'
  fi
  [[ -n "$CODEX_MODEL" ]] && printf 'model = "%s"\n' "$CODEX_MODEL"
  [[ -n "$CODEX_PROVIDER" ]] && printf 'model_provider = "%s"\n' "$CODEX_PROVIDER"

  case "$CODEX_PROVIDER" in
    openrouter)
      base="${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}"
      echo
      echo "[model_providers.openrouter]"
      echo 'name = "OpenRouter"'
      printf 'base_url = "%s"\n' "$base"
      echo 'env_key = "OPENROUTER_API_KEY"'
      echo 'requires_openai_auth = false'
      ;;
    qimono_ollama)
      base="${OLLAMA_BASE_URL:-http://127.0.0.1:11434/v1}"
      echo
      echo "[model_providers.qimono_ollama]"
      echo 'name = "Ollama"'
      printf 'base_url = "%s"\n' "$base"
      has OLLAMA_API_KEY && echo 'env_key = "OLLAMA_API_KEY"'
      echo 'requires_openai_auth = false'
      ;;
    custom)
      echo
      echo "[model_providers.custom]"
      printf 'name = "%s"\n' "${CUSTOM_NAME:-Custom OpenAI-compatible endpoint}"
      printf 'base_url = "%s"\n' "${CUSTOM_BASE_URL}"
      has CUSTOM_API_KEY && echo 'env_key = "CUSTOM_API_KEY"'
      echo 'requires_openai_auth = false'
      ;;
    ""|openai) : ;;
    *)
      warn "codex provider" "unknown id '${CODEX_PROVIDER}' — no provider table written"
      ;;
  esac
}

if (( DRY_RUN )); then
  plan "write codex config" "$CODEX_CONFIG"
  render_codex_config | sed 's/^/      /'
else
  mkdir -p "$(dirname "$CODEX_CONFIG")"
  if [[ -f "$CODEX_CONFIG" ]] && ! grep -q 'Managed by vps-ubuntu' "$CODEX_CONFIG" 2>/dev/null; then
    cp -p "$CODEX_CONFIG" "${CODEX_CONFIG}.pre-vps-ubuntu.$(date +%s)"
    warn "codex config" "existing file backed up before takeover"
  fi
  render_codex_config > "$CODEX_CONFIG"
  ok "write codex config" "$CODEX_CONFIG"
fi

# ---- 5. write ~/.config/opencode/opencode.json (merge, keep other keys) ----
if (( DRY_RUN )); then
  plan "write opencode config" "$OPENCODE_CONFIG (merge existing keys)"
else
  mkdir -p "$(dirname "$OPENCODE_CONFIG")"
  OPENCODE_CONFIG="$OPENCODE_CONFIG" OPENCODE_MODEL="$OPENCODE_MODEL" python3 - <<'PY'
import json, os, sys, time

path = os.environ["OPENCODE_CONFIG"]
env = os.environ
def has(k):
    return bool(env.get(k, "").strip())

cfg = {}
if os.path.exists(path):
    try:
        with open(path, encoding="utf-8") as f:
            cfg = json.load(f)
    except Exception:
        backup = f"{path}.pre-vps-ubuntu.{int(time.time())}"
        os.replace(path, backup)
        print(f"  {'existing opencode config':<40} WAIT  invalid JSON backed up to {backup}")
        cfg = {}

cfg.setdefault("$schema", "https://opencode.ai/config.json")
providers = cfg.setdefault("provider", {})

def put(pid, entry):
    base = providers.get(pid, {})
    entry.setdefault("options", {})
    base.setdefault("options", {}).update(entry["options"])
    for k, v in entry.items():
        if k != "options":
            base[k] = v
    providers[pid] = base

def models_for(model):
    return {model: {"name": model}} if model else None

if has("OPENAI_API_KEY"):
    put("openai", {"options": {"apiKey": "{env:OPENAI_API_KEY}"}})
if has("ANTHROPIC_API_KEY"):
    put("anthropic", {"options": {"apiKey": "{env:ANTHROPIC_API_KEY}"}})
if has("GOOGLE_GENERATIVE_AI_API_KEY"):
    put("google", {"options": {"apiKey": "{env:GOOGLE_GENERATIVE_AI_API_KEY}"}})
if has("OPENROUTER_API_KEY"):
    e = {
        "npm": "@ai-sdk/openai-compatible",
        "name": "OpenRouter",
        "options": {
            "baseURL": env.get("OPENROUTER_BASE_URL") or "https://openrouter.ai/api/v1",
            "apiKey": "{env:OPENROUTER_API_KEY}",
        },
    }
    m = models_for(env.get("OPENROUTER_MODEL"))
    if m:
        e["models"] = m
    put("openrouter", e)
if has("OLLAMA_BASE_URL"):
    e = {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Ollama",
        "options": {"baseURL": env["OLLAMA_BASE_URL"]},
    }
    if has("OLLAMA_API_KEY"):
        e["options"]["apiKey"] = "{env:OLLAMA_API_KEY}"
    m = models_for(env.get("OLLAMA_MODEL"))
    if m:
        e["models"] = m
    put("ollama", e)
if has("CUSTOM_BASE_URL"):
    e = {
        "npm": "@ai-sdk/openai-compatible",
        "name": env.get("CUSTOM_NAME") or "Custom endpoint",
        "options": {"baseURL": env["CUSTOM_BASE_URL"]},
    }
    if has("CUSTOM_API_KEY"):
        e["options"]["apiKey"] = "{env:CUSTOM_API_KEY}"
    m = models_for(env.get("CUSTOM_MODEL"))
    if m:
        e["models"] = m
    put("custom", e)

if env.get("OPENCODE_MODEL", "").strip():
    cfg["model"] = env["OPENCODE_MODEL"].strip()

tmp = f"{path}.tmp.{os.getpid()}"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
print(f"  {'write opencode config':<40} OK    {path}")
print(f"  {'providers':<40} OK    {', '.join(sorted(providers)) or 'none yet'}")
PY
  [[ $? -eq 0 ]] || { bad "write opencode config" "python3 merge failed"; }
fi

# ---- 6. guarded shell block: source keys + PATH ----------------------------
write_shell_block() {
  local file="$1" tmp
  tmp="$(mktemp)"
  if [[ -f "$file" ]]; then
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b {skip=1; next}
      $0==e {skip=0; next}
      !skip {print}
    ' "$file" > "$tmp"
  else
    : > "$tmp"
  fi
  {
    [[ -s "$tmp" ]] && echo
    echo "$MARK_BEGIN"
    echo "if [ -f \"$ENV_FILE\" ]; then set -a; . \"$ENV_FILE\"; set +a; fi"
    echo 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac'
    echo 'case ":$PATH:" in *":$HOME/.opencode/bin:"*) ;; *) PATH="$HOME/.opencode/bin:$PATH" ;; esac'
    echo 'export PATH'
    echo "$MARK_END"
  } >> "$tmp"
  if (( DRY_RUN )); then
    plan "shell block" "$file"
  else
    # cat (not mv) keeps symlinks intact for stow-managed dotfiles.
    cat "$tmp" > "$file"
    ok "shell block" "$file"
  fi
  rm -f "$tmp"
}

for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  write_shell_block "$rc"
done
[[ -n "${ZSH_VERSION:-}" || -f "$HOME/.zshrc" ]] && write_shell_block "$HOME/.zshrc"

# ---- 7. summary ------------------------------------------------------------
echo
echo "--- provider variables (names only; values never printed) ---"
for v in OPENAI_API_KEY ANTHROPIC_API_KEY OPENROUTER_API_KEY GOOGLE_GENERATIVE_AI_API_KEY \
         OLLAMA_BASE_URL OLLAMA_API_KEY CUSTOM_BASE_URL CUSTOM_API_KEY; do
  if has "$v"; then ok "$v" "set"; else warn "$v" "empty"; fi
done

echo
echo "Next:"
echo "  1. edit ${ENV_FILE} and paste your keys"
echo "  2. re-run: $0$( (( DRY_RUN )) && echo ' (was dry-run)')"
echo "  3. open a new shell, then: codex   |   opencode"
echo "  Verify:  $(dirname "${BASH_SOURCE[0]}")/status.sh"
