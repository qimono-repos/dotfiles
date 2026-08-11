# Startup — firefox + dotfiles repo in nvim, once per session
# Stow: shell → ~/.zshrc.d/60-startup.zsh

if ! pgrep -x firefox >/dev/null && ! pgrep -x .firefox-real >/dev/null; then
  LOG=/tmp/firefox-log.txt
  {
    tail -n 1000 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
    firefox 2>&1 | while IFS= read -r line; do
      printf '%s\n' "$line" >> "$LOG"
      (( lines++ ))
      if (( lines >= 500 )); then
        tail -n 1000 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
        lines=0
      fi
    done
  } &
fi

#if ! pgrep -x nvim >/dev/null; then
  cd "$HOME/source/repos/qimono-repos/dotfiles/" # && vi .
#fi
