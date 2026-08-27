# Put the opencode CLI on PATH for zsh (bash-only export missed zsh, since
# ~/.bashrc is never read by zsh). Tail so out-of-tree installs keep priority.
if [[ -d "${HOME}/.opencode/bin" ]]; then
  path=("$path[@]" "${HOME}/.opencode/bin")
  export path
fi
