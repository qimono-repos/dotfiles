# Oh My Posh prompt initialization with Catppuccin theme
# Loaded via ~/.zshrc.local -> ~/.zshrc.d/*.zsh

export PATH="$HOME/.local/bin:$PATH"

if command -v oh-my-posh >/dev/null 2>&1; then
  if [[ -f "$HOME/.config/oh-my-posh/catppuccin.omp.json" ]]; then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/catppuccin.omp.json")"
  elif [[ -f "$HOME/.cache/oh-my-posh/themes/catppuccin.omp.json" ]]; then
    eval "$(oh-my-posh init zsh --config "$HOME/.cache/oh-my-posh/themes/catppuccin.omp.json")"
  else
    eval "$(oh-my-posh init zsh)"
  fi
fi
