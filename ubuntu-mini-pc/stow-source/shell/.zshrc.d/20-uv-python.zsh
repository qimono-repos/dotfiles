# =============================================================================
# Python policy — SINGLE SOURCE OF TRUTH (all qimono machines)
# =============================================================================
# The machine's own Python (/usr/bin/python3, /usr/local/bin/python…) must
# NEVER be used for development. Every Python comes from the Guix package
# manager:
#
#   * any terminal        : ~/.guix-profile/bin/python3   (PATH rank #1, 10-guix.zsh)
#   * per-project work    : guix shell -m manifest.scm    (project profile)
#   * qiskit workspace    : ./run python …                (wraps guix shell + uv)
#   * venvs               : created only from a Guix python (uv sync)
#
# If an interpreter cannot be proven Guix-owned, the shell refuses and tells
# you how to get a Guix one.
# =============================================================================

# --- uv: Guix/system interpreters only; downloads forbidden -----------------
# Forced exports (not :-defaults) so no stale value from an old shell,
# an IDE, or a remote env can reintroduce uv-managed CPythons. A uv-managed
# CPython mixed with Guix LD_LIBRARY_PATH segfaults at startup.
export UV_PYTHON_PREFERENCE=only-system
export UV_PYTHON_DOWNLOADS=never

# Global fallback interpreter for uv in ANY location: the default Guix
# profile's python. Per-project overrides still win (CLI --python flag,
# an existing .venv, or pyproject requires-python filtering).
if [[ -x "$HOME/.guix-profile/bin/python3" ]]; then
  export UV_PYTHON="$HOME/.guix-profile/bin/python3"
fi

# Stable hint for scripts that want the Guix python explicitly.
[[ -n "${UV_PYTHON:-}" ]] && export QIMONO_GUIX_PYTHON="${QIMONO_GUIX_PYTHON:-$UV_PYTHON}"

# --- Guard: refuse the machine Python, explain the way out ------------------
# Shell functions take precedence over PATH lookup in interactive zsh, so
# these shadow /usr/bin/python3 even if PATH order ever changes. They step
# aside whenever the resolved binary belongs to Guix (default profile or a
# guix shell profile), so normal work is never interrupted.
_qimono_python_guard() {
  local cmd=$1
  shift
  local resolved
  resolved="$(whence -p "$cmd" 2>/dev/null)"
  if [[ -n "$resolved" && ( "$resolved" == /gnu/store/* || "$resolved" == "$HOME"/.guix-profile/* ) ]]; then
    command "$cmd" "$@"
    return
  fi
  print -u2 -- "qimono: '${cmd}' is not available from the machine (${resolved:-not found})."
  print -u2 -- "Please create a virtual environment for this Guix machine, or enter a"
  print -u2 -- "Guix environment — the package-manager Python is always used instead:"
  print -u2 -- "  cd <project> && guix shell -m manifest.scm    # then: ${cmd} ..."
  print -u2 -- "  cd <project> && uv sync --python python3      # create .venv (Guix python)"
  print -u2 -- "  ./run ${cmd} ...                              # qiskit workspace wrapper"
  return 127
}
python()  { _qimono_python_guard python  "$@"; }
python3() { _qimono_python_guard python3 "$@"; }

# --- Convenience -------------------------------------------------------------
export QIMONO_QUANTUM_HOME="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"
alias qimono-quantum='cd "$QIMONO_QUANTUM_HOME" 2>/dev/null || echo "No quantum workspace yet — run install-quantum-python.sh"'
