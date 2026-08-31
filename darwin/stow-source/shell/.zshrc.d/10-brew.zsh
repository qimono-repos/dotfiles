# Homebrew (macOS HOST only) — initialize shellenv + completions.
if [[ "$(uname -s)" == "Darwin" ]] && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # brew completions (if present)
  # shellcheck disable=SC1090
  [[ -r /opt/homebrew/completions/zsh/_brew ]] && source /opt/homebrew/completions/zsh/_brew

  # uv (from brew) completion
  if command -v uv >/dev/null 2>&1; then
    _UV_COMPLETE=zsh_source uv 2>/dev/null | source /dev/stdin
  fi
fi