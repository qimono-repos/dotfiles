#!/usr/bin/env bash
# Point GNOME at user-Flatpak desktop files + icons without apt's
# /etc/profile.d/flatpak.sh. Safe to re-run.
set -euo pipefail

EXPORTS="${HOME}/.local/share/flatpak/exports/share"
[[ -d "$EXPORTS" ]] || exit 0

mkdir -p "${HOME}/.local/share/applications"
if [[ -d "$EXPORTS/applications" ]]; then
  find "$EXPORTS/applications" -maxdepth 1 -name '*.desktop' -print0 |
    while IFS= read -r -d '' desk; do
      ln -sfn "$desk" "${HOME}/.local/share/applications/$(basename "$desk")"
    done
fi

if [[ -d "$EXPORTS/icons/hicolor" ]]; then
  # exports/icons are themselves symlinks into the app dir
  find "$EXPORTS/icons/hicolor" \( -type f -o -type l \) \( -name '*.png' -o -name '*.svg' \) -print0 |
    while IFS= read -r -d '' icon; do
      rel="${icon#"$EXPORTS/icons/hicolor/"}"
      dest="${HOME}/.local/share/icons/hicolor/${rel}"
      mkdir -p "$(dirname "$dest")"
      ln -sfn "$icon" "$dest"
    done
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  mkdir -p "${HOME}/.local/share/icons/hicolor"
  gtk-update-icon-cache -f "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "OK: linked Flatpak exports into ~/.local/share/{applications,icons}"
