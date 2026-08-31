#!/usr/bin/env bash
# container-machine-create.sh — build a Debian+systemd image and create the
# persistent dev machine (`qi-dev`). Modeled on the documented container-machine
# pattern: systemd must be a REAL init at /sbin/init (upstream Debian/Ubuntu
# images have no init there and FAIL as machine bases — Alpine works, systemd
# needs your own image).
#
# Idempotent: rebuild image first on re-runs (`container build` cache aware).
# Usage: ./container-machine-create.sh [--dry-run]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=0
NAME="qi-dev"
IMAGE="qimono/debian-qi:bookworm"
DOCKERFILE_DIR="${HOME}/.qimono/container-machine"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) echo "usage: $0 [--dry-run]"; exit 0 ;;
    --name=*) NAME="${arg#--name=}" ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

ok()  { printf '  %-42s OK    %s\n' "$1" "$2"; }
bad() { printf '  %-42s MISS  %s\n' "$1" "$2"; }
warn(){ printf '  %-42s WAIT  %s\n' "$1" "$2"; }
plan(){ printf '  %-42s PLAN  %s\n' "$1" "$2"; }

echo "=== [darwin] create container machine '$NAME' ($IMAGE) ==="

if ! command -v container >/dev/null 2>&1; then
  bad "container CLI" "not on PATH — run ./scripts/install-container.sh first"
  exit 2
fi
ok "container CLI" "$(container --version 2>/dev/null | head -1)"

mkdir -p "$DOCKERFILE_DIR"
cat > "$DOCKERFILE_DIR/Dockerfile" <<'EOF'
# qimono/debian-qi — Debian bookworm WITH a real init at /sbin/init, so it
# can act as an Apple `container machine` base (see darwin/docs/apple-container.md).
# Pattern: systemd as PID 1 via /sbin/init, empty machine-id, masked breakers.
FROM debian:bookworm

ENV container=container
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# systemd must be at /sbin/init for container machines; upstream Debian images
# do not ship it there.
RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv \
      curl ca-certificates git \
      sudo zsh less vim-tiny \
    && rm -f /etc/machine-id \
    && ln -s /lib/systemd/systemd /sbin/init \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Mask the notorious systemd breakers inside containerized boots.
RUN systemctl mask \
      systemd-udevd.service systemd-udevd-kernel.socket \
      systemd-udevd-control.socket systemd-firstboot.service \
      systemd-tmpfiles-setup.service systemd-tmpfiles-setup-dev.service \
      systemd-remount-fs.service 2>/dev/null || true

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
EOF
ok "Dockerfile" "$DOCKERFILE_DIR/Dockerfile (systemd at /sbin/init)"

if (( DRY_RUN )); then
  plan "build"    "container build -f $DOCKERFILE_DIR/Dockerfile -t $IMAGE $DOCKERFILE_DIR"
  plan "machine"  "container machine create --name $NAME --set-default $IMAGE"
  plan "enter"    "container machine run $NAME"
  exit 0
fi

# ---- build the image --------------------------------------------------------
echo "==> container build -t $IMAGE"
if container build -f "$DOCKERFILE_DIR/Dockerfile" -t "$IMAGE" "$DOCKERFILE_DIR"; then
  ok "build" "$IMAGE"
else
  warn "build" "failed — check 'container build --help'; Rosetta 2 must be installed to BUILD"
  exit 1
fi

# ---- create the machine (stateful; recreate, don't migrate) -----------------
if container machine list 2>/dev/null | grep -q "$NAME"; then
  ok "machine $NAME" "already exists:"
  container machine list | grep -E "NAME|$NAME" || true
  echo "Use:  container machine run $NAME"
  exit 0
fi

echo "==> container machine create --name $NAME --set-default $IMAGE"
container machine create --name "$NAME" --set-default "$IMAGE"
ok "machine $NAME" "created (mirrors your macOS \$HOME via VirtioFS)"

echo
echo "Next:"
echo "  ./scripts/gen-guix-in-container.sh      # write Guix bootstrap into \$HOME"
echo "  container machine run $NAME              # enter Linux"
echo "  sudo bash ~/.qimono/guix-in-container.sh # then bootstrap Guix inside"