#!/usr/bin/env bash
# Compatibility entrypoint. The full VPS convergence pipeline is provision-vps.sh.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$ROOT/provision-vps.sh" "$@"
