#!/usr/bin/env bash
# Install Ubuntu's packaged Evil mode for the VPS's existing Emacs.
set -Eeuo pipefail
[[ "$EUID" -eq 0 ]] || { echo "Run as root: sudo bash $0" >&2; exit 1; }
command -v emacs >/dev/null 2>&1 || { echo "Emacs is not installed; refusing to add a second Emacs distribution." >&2; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y elpa-evil
emacs --version | head -n 1
echo "Evil mode package installed for the system Emacs."
