#!/usr/bin/env bash
# Link Guix .desktop files into ~/.local/share/applications so GNOME app grid sees them.
set -euo pipefail

PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
APP_SRC="$PROFILE/share/applications"
APP_DST="$HOME/.local/share/applications"

if [[ ! -d "$APP_SRC" ]]; then
  echo "error: no applications dir at $APP_SRC — install epiphany/firefox first" >&2
  exit 1
fi

mkdir -p "$APP_DST"
# shellcheck disable=SC2045
for f in "$APP_SRC"/*.desktop; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f")"
  # skip if not browser/communication related optional filter — link all guix desktops
  ln -sfn "$f" "$APP_DST/$base"
  echo "linked $base"
done

update-desktop-database "$APP_DST" 2>/dev/null || true
update-desktop-database "$APP_SRC" 2>/dev/null || true
echo "OK. Log out/in of GNOME or press Super and search Web / Firefox."
