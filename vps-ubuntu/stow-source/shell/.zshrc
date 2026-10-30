# QIMONO VPS STOW: interactive shell entrypoint
export PATH="$HOME/.guix-profile/bin:$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
[[ -r "$HOME/.config/guix/current/etc/profile" ]] && source "$HOME/.config/guix/current/etc/profile"
[[ -r "$GUIX_PROFILE/etc/profile" ]] && source "$GUIX_PROFILE/etc/profile"
for _qimono_file in "$HOME"/.zshrc.d/*.zsh; do
  [[ -r "$_qimono_file" ]] && source "$_qimono_file"
done
unset _qimono_file
