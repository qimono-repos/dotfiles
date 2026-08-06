#!/usr/bin/env bash
# Install GNU Guix if missing (official installer, noninteractive where possible).
set -euo pipefail

if command -v guix >/dev/null 2>&1; then
  echo "OK: guix already present: $(command -v guix)"
  guix --version | head -1 || true
  exit 0
fi

echo "==> Installing GNU Guix (official installer)…"
echo "    You will be prompted for sudo if needed."
TMP="${TMPDIR:-/tmp}/guix-install-$$"
mkdir -p "$TMP"
# Official installer
wget -q -O "$TMP/guix-install.sh" https://guix.gnu.org/guix-install.sh
chmod +x "$TMP/guix-install.sh"

# Make sure user namespace mapping tools exist before installing Guix
if ! command -v newgidmap >/dev/null 2>&1 || ! command -v newuidmap >/dev/null 2>&1; then
  echo "Installing uidmap so Guix can configure user namespace mappings..."
  sudo apt-get update -y
  sudo apt-get install -y uidmap
fi

# Guix installer runner helpers
run_guix_installer() {
  local installer="$1"
  sudo --preserve-env=YES_TO_ALL env YES_TO_ALL=1 "$installer"
}

run_guix_installer_with_mirror() {
  local installer="$1"
  local mirror="$2"
  local local_script="$TMP/guix-install-$(echo "$mirror" | sed 's#[/:]#_#g').sh"
  cp "$installer" "$local_script"
  sed -i "s#^GNU_URL=.*#GNU_URL=\"${mirror}\"#" "$local_script"
  chmod +x "$local_script"
  run_guix_installer "$local_script"
}

run_guix_installer_with_fallback() {
  local mode="$1"
  local mirrors=(
    "https://ftp.gnu.org/gnu/guix/"
    "https://mirror.kernel.org/gnu/guix/"
    "https://ftpmirror.gnu.org/gnu/guix/"
    "https://mirror.ufs.ac.za/gnu/guix/"
  )
  local mirror

  for mirror in "${mirrors[@]}"; do
    echo "WARN: trying Guix installer with mirror $mirror"
    if run_guix_installer_with_mirror "$TMP/guix-install.sh" "$mirror"; then
      return 0
    fi
  done
  return 1
}

# Noninteractive defaults when supported by installer
export YES_TO_ALL="${YES_TO_ALL:-1}"
if ! run_guix_installer "$TMP/guix-install.sh"; then
  echo "WARN: noninteractive install returned non-zero; trying fallback mirrors..."
  if ! run_guix_installer_with_fallback noninteractive; then
    echo "WARN: all noninteractive fallback mirrors failed; trying interactive fallback mirrors..."
    if ! run_guix_installer_with_fallback interactive; then
      echo "ERROR: Guix installation failed on all mirrors"
      exit 1
    fi
  fi
fi

# Ensure daemon up
if systemctl list-unit-files 2>/dev/null | grep -q guix-daemon; then
  sudo systemctl enable --now guix-daemon 2>/dev/null || true
fi

hash -r 2>/dev/null || true
if ! command -v guix >/dev/null 2>&1; then
  export PATH="/usr/local/bin:$PATH"
fi
command -v guix
guix --version | head -1
echo "OK: Guix installed (run guix pull next for nonguix/firefox)"
