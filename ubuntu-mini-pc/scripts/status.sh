#!/usr/bin/env bash
# Expected vs Actual probe for this pack. Read-only.
set -u

ok() { printf '  %-42s OK    %s\n' "$1" "$2"; }
bad() { printf '  %-42s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-42s WAIT  %s\n' "$1" "$2"; }

export GUIX_PROFILE="${HOME}/.guix-profile"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  set +u
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
  set -u
fi

echo "=== ubuntu-mini-pc status ($(hostname)) ==="
echo

if command -v guix >/dev/null 2>&1 && command -v grep >/dev/null; then
  INSTALLED="$(guix package -I 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
else
  INSTALLED=""
fi

need_pkg() {
  local p="$1"
  if echo " $INSTALLED " | grep -q " $p "; then
    ok "guix:$p" "installed"
  else
    bad "guix:$p" "not in user profile"
  fi
}

need_pkg emacs
need_pkg stow
need_pkg python
need_pkg uv
need_pkg jupyter
need_pkg gcc-toolchain
need_pkg zlib
need_pkg openssl
need_pkg pkg-config
need_pkg glibc-locales

echo
PY="$(command -v python3 2>/dev/null || true)"
case "$PY" in
  */.guix-profile/bin/python3|/gnu/store/*)
    ok "python3 on PATH" "$PY ($($PY --version 2>&1))"
    ;;
  *)
    bad "python3 on PATH" "${PY:-missing} (want ~/.guix-profile/bin/python3)"
    ;;
esac

if [[ -x /usr/bin/python3 ]]; then
  ok "apt python still present" "/usr/bin/python3 ($(/usr/bin/python3 --version 2>&1))"
else
  warn "apt python still present" "unexpectedly missing"
fi

UV="$(command -v uv 2>/dev/null || true)"
case "$UV" in
  */.guix-profile/bin/uv|/gnu/store/*)
    ok "uv on PATH" "$UV ($($UV --version 2>&1))"
    ;;
  *)
    bad "uv on PATH" "${UV:-missing} (want Guix uv)"
    ;;
esac

if [[ -f "$HOME/.jupyter/jupyter_notebook_config.py" ]]; then
  ok "~/.jupyter/jupyter_notebook_config.py" "present"
else
  bad "~/.jupyter/jupyter_notebook_config.py" "missing"
fi

if [[ -f "$HOME/.config/systemd/user/qimono-jupyter.service" ]]; then
  ok "qimono-jupyter.service file" "present"
else
  bad "qimono-jupyter.service file" "missing"
fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl --user is-enabled qimono-jupyter.service >/dev/null 2>&1; then
    ok "qimono-jupyter enabled" "$(systemctl --user is-enabled qimono-jupyter.service 2>/dev/null)"
  else
    bad "qimono-jupyter enabled" "not enabled"
  fi
  if systemctl --user is-active qimono-jupyter.service >/dev/null 2>&1; then
    ok "qimono-jupyter active" "active"
  else
    warn "qimono-jupyter active" "$(systemctl --user is-active qimono-jupyter.service 2>/dev/null || echo inactive)"
  fi
fi

if [[ -f "$HOME/.secrets/jupyter_auth.py" ]]; then
  ok "~/.secrets/jupyter_auth.py" "present (hash only)"
else
  warn "~/.secrets/jupyter_auth.py" "run ./scripts/setup-jupyter-auth.sh"
fi

WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"
if [[ -f "$WS/pyproject.toml" ]]; then
  ok "quantum-workspace" "$WS"
else
  bad "quantum-workspace" "missing ($WS)"
fi

if [[ -f "$HOME/.local/share/jupyter/kernels/quantum/kernel.json" ]]; then
  ok "kernel Python (quantum)" "kernelspec present"
else
  warn "kernel Python (quantum)" "run ./scripts/install-quantum-python.sh"
fi

echo
if [[ -f "$HOME/.secrets/jupyter_auth.py" ]]; then
  echo "Open http://127.0.0.1:5005 (password login; hash in ~/.secrets)."
else
  echo "Auth is WAIT until you run setup-jupyter-auth.sh (interactive)."
fi
