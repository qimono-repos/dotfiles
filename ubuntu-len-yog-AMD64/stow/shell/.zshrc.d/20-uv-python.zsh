# uv + Python conventions (Guix python preferred over host 3.14)

# uv installs tools into ~/.local/bin by default — already early on PATH
export UV_PYTHON_PREFERENCE="${UV_PYTHON_PREFERENCE:-only-managed}"

# If Guix python exists, expose a stable hint for scripts
if [[ -x "$HOME/.guix-profile/bin/python3" ]]; then
  export QIMONO_GUIX_PYTHON="$HOME/.guix-profile/bin/python3"
elif [[ -x "$HOME/.guix-profile/bin/python" ]]; then
  export QIMONO_GUIX_PYTHON="$HOME/.guix-profile/bin/python"
fi

# Default quantum workspace (override in ~/.zshrc.local if needed)
export QIMONO_QUANTUM_HOME="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"

# Convenience
alias qimono-quantum='cd "$QIMONO_QUANTUM_HOME" 2>/dev/null || echo "No quantum workspace yet — run install-quantum-python.sh"'
