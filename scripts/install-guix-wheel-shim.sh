#!/usr/bin/env bash
# Qimono dotfiles — fleet-standard Guix wheel shim installer.
#
# A venv created from Guix CPython inherits Guix's ld.so, which searches only
# the Guix store (not /usr/lib/x86_64-linux-gnu). manylinux wheels (NumPy,
# SciPy, Qiskit-Aer) strip their RPATH and dlopen libz / libstdc++ by soname,
# so `import numpy` dies with:
#
#     ImportError: libz.so.1: cannot open shared object file
#
# The fix is a venv-local `sitecustomize.py` that preloads the Guix sonames
# with RTLD_GLOBAL before any wheel loads. It is scoped to the interpreter, so
# Ubuntu tools (`ls`, `date`) keep their own loader — never export
# $GUIX_PROFILE/lib in the login shell (that makes Ubuntu binaries load Guix
# libm and die with `GLIBC_2.43 not found`).
#
# Idempotent: re-run after any `uv sync` that recreates the venv. Safe to run
# on any fleet machine; does nothing when the shim is already in place.
#
# Usage:
#   ./install-guix-wheel-shim.sh [--dry-run] [TARGET]
#
#   TARGET may be a venv (dir with bin/python), a project dir (uses ./.venv),
#   or a site-packages dir. Default: ./.venv in the current directory, else
#   $QIMONO_QUANTUM_HOME/.venv.
#
# Env overrides: QIMONO_GUIX_PROFILE (default $HOME/.guix-profile)
# See ubuntu-mini-pc/docs/quantum.md and ubuntu-mini-pc/docs/python-path.md.

set -uo pipefail

DRY_RUN=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,29p' "$0"; exit 0 ;;
    -*) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
    *) TARGET="$1" ;;
  esac
  shift
done

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }
plan() { printf '  %-40s PLAN  %s\n' "$1" "$2"; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHIM_SRC="$HERE/sitecustomize-guix-native.py"
GUIX_PROFILE_DIR="${QIMONO_GUIX_PROFILE:-$HOME/.guix-profile}"

echo "=== guix wheel shim on $(hostname) — $(date '+%Y-%m-%d %H:%M') ==="
echo

if [[ ! -f "$SHIM_SRC" ]]; then
  bad "shim source" "missing alongside this script: $SHIM_SRC"
  exit 1
fi
ok "shim source" "$SHIM_SRC"

if [[ -r "$GUIX_PROFILE_DIR/lib/libz.so.1" ]]; then
  ok "guix libz" "$GUIX_PROFILE_DIR/lib/libz.so.1"
else
  warn "guix libz" "$GUIX_PROFILE_DIR/lib/libz.so.1 missing (install zlib via Guix)"
fi

# --- Resolve the target site-packages ---------------------------------------
if [[ -z "$TARGET" ]]; then
  if [[ -x "./.venv/bin/python" ]]; then
    TARGET="./.venv"
  elif [[ -n "${QIMONO_QUANTUM_HOME:-}" && -x "$QIMONO_QUANTUM_HOME/.venv/bin/python" ]]; then
    TARGET="$QIMONO_QUANTUM_HOME/.venv"
  else
    bad "target" "no venv found (pass one: ./install-guix-wheel-shim.sh /path/to/.venv)"
    exit 2
  fi
fi

VENV=""
SITE=""
if [[ -x "$TARGET/bin/python" ]]; then
  VENV="$TARGET"                     # a venv
elif [[ -x "$TARGET/.venv/bin/python" ]]; then
  VENV="$TARGET/.venv"               # a project dir
elif [[ -d "$TARGET" && -f "$TARGET/_virtualenv.pth" ]]; then
  SITE="$TARGET"                     # already a site-packages dir
else
  bad "target" "not a venv, project, or site-packages: $TARGET"
  exit 2
fi

if [[ -z "$SITE" ]]; then
  SITE="$("$VENV/bin/python" -c 'import sysconfig; print(sysconfig.get_path("purelib"))' 2>/dev/null)"
  [[ -d "$SITE" ]] || { bad "site-packages" "could not resolve for $VENV"; exit 2; }
fi
ok "site-packages" "$SITE"

if [[ -n "$VENV" ]]; then
  PYBIN="$("$VENV/bin/python" -c 'import os, sys; print(os.path.realpath(sys.executable))' 2>/dev/null || echo "$VENV/bin/python")"
  case "$PYBIN" in
    */gnu/store/*|*/.guix-profile/*) ok "interpreter" "$PYBIN (Guix)" ;;
    *) warn "interpreter" "$PYBIN is not Guix (shim is harmless but may be unnecessary)" ;;
  esac
fi

DEST="$SITE/sitecustomize.py"

# --- Install (idempotent) ----------------------------------------------------
if [[ -f "$DEST" ]] && cmp -s "$SHIM_SRC" "$DEST"; then
  ok "sitecustomize.py" "already current — nothing to do"
else
  [[ -f "$DEST" ]] && warn "sitecustomize.py" "differs from shim"
  if (( DRY_RUN )); then
    plan "install shim" "cp $SHIM_SRC $DEST"
    echo
    exit 0
  fi
  if [[ -f "$DEST" ]]; then
    BACKUP="$DEST.bak-$(date +%Y%m%d-%H%M%S)"
    cp -p "$DEST" "$BACKUP"
    warn "existing sitecustomize.py" "backed up to $BACKUP"
  fi
  cp "$SHIM_SRC" "$DEST"
  ok "install shim" "$DEST"
fi

# --- Verify (best effort) ----------------------------------------------------
if (( ! DRY_RUN )) && [[ -n "$VENV" ]]; then
  if "$VENV/bin/python" -c 'import numpy' >/dev/null 2>&1; then
    ok "verify" "numpy imports under $(basename "$VENV") python"
  else
    warn "verify" "numpy import not confirmed (may not be installed yet)"
  fi
fi

echo
echo "Re-run after any 'uv sync' that recreates the venv."
echo "Never export LD_LIBRARY_PATH=\$GUIX_PROFILE/lib in the login shell."
