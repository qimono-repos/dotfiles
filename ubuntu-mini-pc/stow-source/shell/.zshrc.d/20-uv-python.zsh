# uv + Python: Guix interpreter only. Never uv-managed CPython.

export UV_PYTHON_PREFERENCE="${UV_PYTHON_PREFERENCE:-only-system}"

if [[ -x "$HOME/.guix-profile/bin/python3" ]]; then
  export QIMONO_GUIX_PYTHON="$HOME/.guix-profile/bin/python3"
elif [[ -x "$HOME/.guix-profile/bin/python" ]]; then
  export QIMONO_GUIX_PYTHON="$HOME/.guix-profile/bin/python"
fi

export QIMONO_QUANTUM_HOME="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"

alias qimono-quantum='cd "$QIMONO_QUANTUM_HOME" 2>/dev/null || echo "No quantum workspace yet — run install-quantum-python.sh"'
