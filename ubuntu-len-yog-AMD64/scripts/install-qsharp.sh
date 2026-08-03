#!/usr/bin/env bash
# Verify .NET for Q# and ensure Python qsharp is present in the quantum workspace.
set -euo pipefail

WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
fi

echo "==> .NET SDK"
if ! command -v dotnet >/dev/null 2>&1; then
  echo "error: dotnet not found." >&2
  echo "  Prefer: already installed via Microsoft apt package on this host." >&2
  echo "  Fallback ranking: apt (host) > podman image with SDK." >&2
  exit 1
fi

dotnet --list-sdks
dotnet --info | head -20

echo
echo "==> Q# project templates (best-effort; may 404 if renamed upstream)"
dotnet new install Microsoft.Quantum.ProjectTemplates 2>/dev/null \
  || echo "note: classic QDK templates unavailable — use Azure Quantum docs / qsharp Python"

echo
echo "==> Python Q# via qdk package in workspace"
if [[ -d "$WS" ]] && command -v uv >/dev/null 2>&1; then
  (cd "$WS" && uv add qdk && uv run python -c "from qdk import qsharp; print('qdk/qsharp OK')") \
    || echo "warn: could not import qdk.qsharp yet"
else
  echo "note: run install-quantum-python.sh first for the uv workspace"
fi

SAMPLE="${WS:-$HOME}/qsharp-hello"
if command -v dotnet >/dev/null 2>&1; then
  echo
  echo "==> Optional: try creating a console sample under $SAMPLE"
  echo "    (skipped automatically — run manually if templates installed)"
  echo "    mkdir -p $SAMPLE && cd $SAMPLE && dotnet new console -n QsHello"
fi

echo
echo "OK: Q# host checks finished."
echo "    Prefer Python qsharp for quick loops on this 6.5GiB laptop."
