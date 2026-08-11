#!/usr/bin/env bash
# Login autostart (single entry point for the shell startup fragment):
#   1. launch firefox once (guard + capped log), then
#   2. open a Ptyxis terminal in the dotfiles repo, and
#   3. open the Guix-managed Monaco IDE (VSCodium) in the dotfiles repo.
# Referenced by stow-source/shell/.config/autostart/60-startup.desktop
set -u

LOG=/tmp/firefox-log.txt

if ! pgrep -x firefox >/dev/null && ! pgrep -x .firefox-real >/dev/null; then
  lines=0
  {
    # GNOME autostart env has no Guix PATH/LD vars, so load the profile before
    # launching `firefox` — otherwise it resolves to the /usr/bin/firefox snap
    # stub. This stays scoped to the subshell so ptyxis (a system app) runs
    # with a clean env below.
    set +u
    source "$HOME/.guix-profile/etc/profile" 2>/dev/null
    set -u
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
else
  echo "firefox already running — skip" >&2
fi

ptyxis -d "$HOME/source/repos/qimono-repos/dotfiles"

if [[ -x "$HOME/.guix-profile/bin/codium" ]]; then
  (
    set +u
    source "$HOME/.guix-profile/etc/profile" 2>/dev/null
    cd "$HOME/source/repos/qimono-repos/dotfiles"
    # --no-sandbox: Guix store files can't be setuid, so Electron's default
    # sandbox (chrome-sandbox, not SUID) hangs instead of starting the window.
    exec "$HOME/.guix-profile/bin/codium" --no-sandbox .
  )
else
  echo "vscodium not installed yet — run scripts/20-guix-pull-channels.sh" >&2
fi
