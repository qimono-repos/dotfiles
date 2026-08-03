#!/usr/bin/env bash
# Fix Epiphany/WebKit bwrap on Ubuntu (AppArmor unprivileged userns restriction).
# Thin wrapper around install-host-sysctl.sh (canonical pack drop-in).
# Requires sudo. Safe for personal laptop; see docs/LESSONS-guix-browsers.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/install-host-sysctl.sh"
