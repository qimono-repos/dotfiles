#!/usr/bin/env bash
# Qimono dotfiles — Firefox installer for ubuntu-len-yog-ARM64.
#
# aarch64 reasoning: Guix `firefox` has NO aarch64 substitute and would be a
# multi-hour source build (per LESSONS-guix-browsers.md — never source-build
# Firefox). This pack instead installs Firefox via snap (native ARM package for
# Ubuntu), ranking snap #3 in the pack policy for desktop apps when Guix effort
# is too high.
#
# Safety: Firefox is NEVER autostarted — only Ghostty launches at login
# (scripts/startup-login.sh / 60-startup.desktop).
#
# Idempotent + reproducible; expected-vs-actual (OK / MISS / WAIT / PLAN).
#
# Usage:
#   ./install-browser.sh                # probe + install if missing
#   ./install-browser.sh --dry-run      # probe only, change nothing

set -uo pipefail

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }
plan() { printf '  %-40s PLAN  %s\n' "$1" "$2"; }

probe() {
  PROBE=0
  if snap list firefox >/dev/null 2>&1; then
    PROBE=1
    local v; v="$(snap list firefox 2>/dev/null | awk 'NR==2{print $2}')"
    ok "firefox (snap)" "installed (v${v:-?}) — native ARM"
  elif [[ -x /usr/bin/firefox ]] && /usr/bin/firefox --version >/dev/null 2>&1; then
    PROBE=1
    ok "firefox (apt)" "/usr/bin/firefox present"
  else
    bad "firefox" "not installed (no snap, no working /usr/bin/firefox)"
  fi
}

echo "=== Firefox on $(hostname) — snap (ARM-friendly) — $(date '+%Y-%m-%d %H:%M') ==="
echo
probe

if (( PROBE )); then
  echo
  echo "Policy: firefox is manual-launch only (never autostarted)."
  echo "Verify:  firefox "
  exit 0
fi

if (( DRY_RUN )); then
  plan "install firefox" "sudo snap install firefox"
  exit 0
fi

echo "--- installing firefox via snap (native ARM) ---"
if command -v snap >/dev/null 2>&1; then
  if sudo snap install firefox; then
    ok "install firefox" "done (snap)"
  else
    bad "install firefox" "snap install failed"
    exit 1
  fi
else
  echo "error: snap not available for native-ARM firefox." >&2
  exit 1
fi

echo
echo "Launch manually when needed:  firefox"
echo "Never autostarted — only Ghostty starts at login."
