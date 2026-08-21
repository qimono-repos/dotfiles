#!/usr/bin/env bash
# Login autostart (single entry point):
#   1. Ghostty terminal (flatpak) in the dotfiles repo,
#   2. Firefox (Guix), then
#   3. Alpaca (flatpak, via stow shim).
# Referenced by stow-source/shell/.config/autostart/60-startup.desktop.
# Pattern copied from ubuntu-hp-pro/scripts/startup-login.sh.
set -u

FP="${HOME}/.guix-profile/bin/flatpak"
REPO_DIR="${HOME}/source/repos/qimono-repos/dotfiles"
LOGDIR_GHOSTTY=/tmp/ghostty-log.txt
LOG_FIREFOX=/tmp/firefox-log.txt

# Flatpak helper daemons are wired by link-flatpak-host-services.sh; belt and
# braces for the bwrap path (Ubuntu AppArmor blesses only /usr/bin/bwrap).
export FLATPAK_BWRAP="${FLATPAK_BWRAP:-/usr/bin/bwrap}"

cap_log() {
  local log=$1
  if [[ -f "$log" ]]; then
    tail -n 1000 "$log" > "$log.tmp" 2>/dev/null && mv "$log.tmp" "$log"
  fi
}

# Flatpak processes live inside systemd-user scopes named app-flatpak-<id>-*;
# host-side pgrep cannot see their argv reliably, so ask the scope table.
flatpak_scope_active() {
  systemctl --user list-units "app-flatpak-${1}-*" \
    --no-legend --state=active 2>/dev/null | grep -q .
}

# 1. Ghostty — open in the dotfiles repo (fleet habit: shells start there).
if flatpak_scope_active com.mitchellh.ghostty; then
  echo "ghostty already running — skip" >&2
else
  cap_log "$LOGDIR_GHOSTTY"
  (
    "$FP" --user run com.mitchellh.ghostty \
      --working-directory="$REPO_DIR" >> "$LOGDIR_GHOSTTY" 2>&1
  ) &
fi

sleep 3 # stagger launches against login I/O storm

# 2. Firefox — Guix build; GNOME autostart env carries no Guix PATH/LD vars,
# so load the profile inside the launching subshell (hp-pro lesson: otherwise
# a snap stub may win resolution).
if pgrep -x firefox >/dev/null 2>&1 || pgrep -x .firefox-real >/dev/null 2>&1; then
  echo "firefox already running — skip" >&2
else
  cap_log "$LOG_FIREFOX"
  (
    set +u
    # shellcheck disable=SC1091
    source "${HOME}/.guix-profile/etc/profile" 2>/dev/null
    set -u
    exec firefox >> "$LOG_FIREFOX" 2>&1
  ) &
fi

sleep 3

# 3. Alpaca — stow shim already caps/logs to /tmp/alpaca-log.txt.
if flatpak_scope_active com.jeffser.Alpaca; then
  echo "alpaca already running — skip" >&2
else
  "${HOME}/.local/bin/alpaca" &
fi

wait
