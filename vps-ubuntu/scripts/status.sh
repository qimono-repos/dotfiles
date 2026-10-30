#!/usr/bin/env bash
# Expected vs Actual probe for the vps-ubuntu LLM stack. Read-only.
set -u

ok()   { printf '  %-42s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-42s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-42s WAIT  %s\n' "$1" "$2"; }

ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/qimono/providers.env"
CODEX_CONFIG="${CODEX_HOME:-$HOME/.codex}/config.toml"
OPENCODE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"

echo "=== vps-ubuntu LLM status ($(hostname)) ==="
echo

# binaries
for b in codex opencode; do
  if command -v "$b" >/dev/null 2>&1; then
    ok "$b" "$(command -v "$b") ($("$b" --version 2>&1 | head -1))"
  else
    case "$b" in
      codex)    [[ -x "$HOME/.local/bin/codex" ]] && ok "$b" "$HOME/.local/bin/codex ($("$HOME/.local/bin/codex" --version 2>&1 | head -1))" || bad "$b" "not installed (./scripts/install-codex.sh)" ;;
      opencode) [[ -x "$HOME/.opencode/bin/opencode" ]] && ok "$b" "$HOME/.opencode/bin/opencode ($("$HOME/.opencode/bin/opencode" --version 2>&1 | head -1))" || bad "$b" "not installed (./scripts/install-opencode.sh)" ;;
    esac
  fi
done

# secrets file
if [[ -f "$ENV_FILE" ]]; then
  PERM="$(stat -c '%a' "$ENV_FILE" 2>/dev/null || echo '?')"
  ok "providers.env" "$ENV_FILE (mode $PERM)"
  [[ "$PERM" == "600" ]] || warn "providers.env perms" "$PERM (want 600)"
else
  bad "providers.env" "missing (./scripts/configure-llm.sh)"
fi

# keys: names only
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE" >/dev/null 2>&1
  set +a
fi
for v in OPENAI_API_KEY ANTHROPIC_API_KEY OPENROUTER_API_KEY GOOGLE_GENERATIVE_AI_API_KEY \
         OLLAMA_BASE_URL CUSTOM_BASE_URL; do
  if [[ -n "${!v:-}" ]]; then ok "$v" "set"; else warn "$v" "empty"; fi
done

# generated configs
for f in "$CODEX_CONFIG" "$OPENCODE_CONFIG"; do
  if [[ -f "$f" ]]; then
    ok "$(basename "$f")" "$f"
  else
    bad "$(basename "$f")" "missing — run ./scripts/configure-llm.sh"
  fi
done

# shell hook
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  if grep -q 'qimono vps-ubuntu LLM env' "$rc" 2>/dev/null; then
    ok "shell hook" "$rc"
  else
    warn "shell hook" "$rc missing — run ./scripts/configure-llm.sh"
  fi
done

echo
echo "Open a new shell before using codex/opencode so keys + PATH are loaded."
