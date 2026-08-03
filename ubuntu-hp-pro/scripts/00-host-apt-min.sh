#!/usr/bin/env bash
# Minimal apt tools so Guix installer + network/certs work.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y \
  curl \
  wget \
  ca-certificates \
  gnupg \
  xz-utils \
  build-essential \
  netbase \
  locales

# UTF-8 locale (helps Guix GUI apps)
sudo locale-gen en_US.UTF-8 2>/dev/null || true
sudo update-locale LANG=en_US.UTF-8 2>/dev/null || true

echo "OK: apt minimum installed"
