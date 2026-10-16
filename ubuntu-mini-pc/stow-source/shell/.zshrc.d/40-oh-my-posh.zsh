# Oh My Posh prompt initialization with Catppuccin theme
# Loaded via ~/.zshrc.local -> ~/.zshrc.d/*.zsh

# oh-my-posh lives in ~/.local/bin. Append (do NOT prepend) so the Guix
# profile bin stays rank #1 — a prepend here shadowed Guix `uv` with the
# host ~/.local/bin/uv and undid 10-guix.zsh.
if [[ -d "$HOME/.local/bin" ]]; then
  path+=("$HOME/.local/bin")
fi

if command -v oh-my-posh >/dev/null 2>&1; then
  if [[ -f "$HOME/.config/oh-my-posh/catppuccin.omp.json" ]]; then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/catppuccin.omp.json")"
  elif [[ -f "$HOME/.cache/oh-my-posh/themes/catppuccin.omp.json" ]]; then
    eval "$(oh-my-posh init zsh --config "$HOME/.cache/oh-my-posh/themes/catppuccin.omp.json")"
  else
    eval "$(oh-my-posh init zsh)"
  fi
fi
