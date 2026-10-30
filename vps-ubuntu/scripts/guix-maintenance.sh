#!/usr/bin/env bash
# Explicit Guix maintenance. No automatic updates.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
GUIX="$TARGET_HOME/.config/guix/current/bin/guix"
CHANNELS="$TARGET_HOME/.config/guix/channels.scm"
LOCK="$ROOT/guix/channels.lock.scm"
SUBSTITUTES="https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org"
mkdir -p /var/log
exec > >(tee -a /var/log/qimono-guix-maintenance.log) 2>&1
as_target(){ if [[ "$TARGET_USER" == root ]]; then "$@"; else sudo -u "$TARGET_USER" -H "$@"; fi; }
[[ -x "$GUIX" ]] || { echo "No current Guix generation: $GUIX" >&2; exit 1; }
case "${1:-status}" in
 status)
  as_target "$GUIX" --version
  as_target "$GUIX" describe
  as_target "$GUIX" pull --list-generations
  as_target "$GUIX" package --list-generations --profile="$TARGET_HOME/.guix-profile"
  [[ -f "$LOCK" ]] && echo "Snapshot: $LOCK" || echo "Snapshot not yet created."
  ;;
 snapshot)
  tmp="$(mktemp)"
  as_target "$GUIX" describe -f channels > "$tmp"
  install -m 0644 "$tmp" "$LOCK"
  rm -f "$tmp"
  echo "Wrote $LOCK. Commit this file to Git."
  ;;
 refresh)
  [[ -f "$CHANNELS" ]] || { echo "Missing $CHANNELS" >&2; exit 1; }
  echo "Refreshing channels. A stationary progress display alone does not indicate failure."
  as_target "$GUIX" pull --channels="$CHANNELS" --substitute-urls="$SUBSTITUTES"
  echo "Refresh succeeded."
  ;;
 rollback)
  as_target "$GUIX" pull --roll-back
  as_target "$TARGET_HOME/.config/guix/current/bin/guix" describe
  ;;
 *) echo "Usage: sudo bash $0 {status|snapshot|refresh|rollback}" >&2; exit 2 ;;
esac
