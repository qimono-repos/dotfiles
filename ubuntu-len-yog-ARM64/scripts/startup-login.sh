#!/usr/bin/env bash
# Login autostart for ubuntu-len-yog-ARM64 (Snapdragon) — Ghostty ONLY.
#
# Policy: Ghostty is the only app auto-launched at login. Firefox, Alpaca, and
# everything else are opened manually when needed (see 60-startup.desktop which
# is wired through this single guarded entry point like the AMD sibling).
#
# Uses the NATIVE aarch64 Guix Ghostty (via the saayix channel), NOT the
# x86_64 flatpak shim — the ARM64 pack keeps no x86_64 blobs.
#
# Referenced by stow-source/shell/.config/autostart/60-startup.desktop.
set -u

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
GHOSTTY_BIN="$GUIX_PROFILE/bin/ghostty"
if [[ ! -x "$GHOSTTY_BIN" ]]; then
  # Guix profile not yet full (base manifest missing ghostty) — try PATH.
  GHOSTTY_BIN="$(command -v ghostty 2>/dev/null || true)"
fi
REPO_DIR="${HOME}/source/repos/qimono-repos/dotfiles"
LOGDIR_GHOSTTY=/tmp/ghostty-log.txt

if [[ -z "$GHOSTTY_BIN" ]]; then
  echo "startup-login.sh: ghostty not found (Guix profile not installed?)" >&2
  exit 1
fi

cap_log() {
  local log=$1
  if [[ -f "$log" ]]; then
    tail -n 1000 "$log" > "$log.tmp" 2>/dev/null && mv "$log.tmp" "$log"
  fi
}

# Native desktop process — visible to pgrep as the ghostty binary.
is_running() {
  pgrep -xu "$USER" -f "${GHOSTTY_BIN#/}" >/dev/null 2>&1 \
    || pgrep -xu "$USER" -x ghostty >/dev/null 2>&1
}

# Ghostty — open in the dotfiles repo (fleet habit: shells start there).
if is_running; then
  echo "ghostty already running — skip" >&2
else
  cap_log "$LOGDIR_GHOSTTY"
  (
    "$GHOSTTY_BIN" --working-directory="$REPO_DIR" >> "$LOGDIR_GHOSTTY" 2>&1
  ) &
fi

wait
