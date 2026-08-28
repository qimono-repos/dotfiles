# ~/.zshrc.d/42-fastfetch.zsh — fastfetch at shell launch and after every clear.
#
# Proper zsh mechanism (NOT an anti-pattern bare `fastfetch` appended to .zshrc):
#   * Launch  → a one-shot precmd hook runs fastfetch exactly once, before the
#               first prompt, then removes itself (so subshells/re-renders don't
#               spam it, and it won't print over the prompt cursor).
#   * Clear   → an interactive-only `clear` FUNCTION wraps the real clear and
#               reprints fastfetch. Non-interactive scripts never source this
#               (guarded below) so `clear` in scripts is untouched.
#   * `cls`   → still aliases to `clear`, which now also prints fastfetch.
#
# fastfetch itself is managed by the host package manager (apt here) — this
# snippet only wires the display beats.

# Interactive shells only (mirrors .zshrc guard; keeps scripts fast & clean).
[[ $- != *i* ]] && return
command -v fastfetch >/dev/null 2>&1 || return

# --- launch: run once, before the first prompt, then disarm ---
_fastfetch_once() {
  command fastfetch
  precmd_functions=( "${(@)precmd_functions:#_fastfetch_once}" )
}
precmd_functions+=(_fastfetch_once)

# --- every `clear` reprints it (relies on the alias `cls=clear`) ---
clear() {
  command clear
  command fastfetch
}
