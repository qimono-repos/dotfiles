#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "error: run with sudo: sudo bash $0" >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == root ]]; then
  echo "error: run with sudo from your normal user: sudo bash $0" >&2
  exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_GROUP="$(id -gn "$TARGET_USER")"
if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
  echo "error: could not resolve home for $TARGET_USER" >&2
  exit 1
fi

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_FILE="$REPO_DIR/shell/50-power.sh"
DST_DIR="$TARGET_HOME/.bashrc.d"
DST_FILE="$DST_DIR/50-power.sh"
BASHRC="$TARGET_HOME/.bashrc"
DROPIN="/etc/sudoers.d/qimono-power"
RULE="$TARGET_USER ALL=(root) NOPASSWD: /usr/bin/systemctl reboot -i, /usr/bin/systemctl poweroff -i"

if [[ ! -f "$SRC_FILE" ]]; then
  echo "error: missing $SRC_FILE" >&2
  exit 1
fi

install -d -o "$TARGET_USER" -g "$TARGET_GROUP" -m 755 "$DST_DIR"
install -o "$TARGET_USER" -g "$TARGET_GROUP" -m 644 "$SRC_FILE" "$DST_FILE"

if [[ ! -f "$BASHRC" ]]; then
  install -o "$TARGET_USER" -g "$TARGET_GROUP" -m 644 /dev/null "$BASHRC"
fi

if ! grep -Fq '.bashrc.d' "$BASHRC"; then
  printf '\nif [ -f "$HOME/.bashrc.d/50-power.sh" ]; then\n  . "$HOME/.bashrc.d/50-power.sh"\nfi\n' >> "$BASHRC"
  chown "$TARGET_USER:$TARGET_GROUP" "$BASHRC"
fi

tmp="$(mktemp)"
if [[ -f "$DROPIN" ]]; then
  cp "$DROPIN" "$tmp"
else
  : > "$tmp"
fi
if ! grep -Fxq "$RULE" "$tmp"; then
  printf '%s\n' "$RULE" >> "$tmp"
fi

if visudo -cf "$tmp" >/dev/null; then
  install -m 440 -o root -g root "$tmp" "$DROPIN"
else
  rm -f "$tmp"
  echo "error: sudoers syntax check failed; live sudoers unchanged" >&2
  exit 1
fi
rm -f "$tmp"

echo "OK: $DST_FILE installed for $TARGET_USER"
echo "OK: $DROPIN installed and validated"
echo "Open a new shell, then run: type too"
