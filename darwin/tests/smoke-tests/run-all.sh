#!/usr/bin/env bash
# run-all.sh — darwin smoke tests. INTENDED TO RUN INSIDE the container machine
# (Linux). No arguments; exits non-zero if any check fails.
# Host-only checks live in darwin/QA/Checklist-agent.md instead.
set -uo pipefail

pass=0; fail=0
rep() { printf '  %-4s %s\n' "$1" "$2"; }
check() { # check <desc> <cmd...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then rep PASS "$desc"; pass=$((pass+1));
  else rep FAIL "$desc"; fail=$((fail+1)); fi
}

echo "=== darwin smoke tests (in-machine) ==="

check "PID 1 = systemd"         bash -c '[[ "$(ps -p 1 -o comm= | tr -d " ")" == "systemd" ]]'
check "kernel is Linux"         bash -c '[[ "$(uname -s)" == "Linux" ]]'
check "guix on PATH"            bash -c 'command -v guix >/dev/null'
check "guix --version"          bash -c 'guix --version >/dev/null 2>&1'
check "guix profile sourced"    bash -c 'command -v guix | grep -q guix-profile'
check "manifest packages (guix package -I)" bash -c 'guix package -I 2>/dev/null | grep -qE "stow|tmux|ripgrep|neovim"'
check "guix shell sandbox"      bash -c 'guix shell hello -- hello 2>/dev/null | grep -q "Hello, world!"'
check "stow present"            bash -c 'command -v stow >/dev/null 2>&1'

echo
echo "pass=$pass fail=$fail"
[[ $fail -eq 0 ]] || echo "FAILURES above — see darwin/QA/Checklist-agent.md"
exit $(( fail == 0 ? 0 : 1 ))