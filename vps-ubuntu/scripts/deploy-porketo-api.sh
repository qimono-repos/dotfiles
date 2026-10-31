#!/usr/bin/env bash
# Build and deploy the Porketo Ktor API on the Ubuntu VPS.
# Run: sudo bash vps-ubuntu/scripts/deploy-porketo-api.sh
# Optional paths: DOTFILES_REPO=/path/to/dotfiles PORKETO_REPO=/path/to/the-porketo
# Installs a loopback-only systemd service and keeps prior releases for rollback.
# Does not configure Nginx, open firewall ports, reboot, or print secret values.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REPO="${DOTFILES_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
PORKETO_REPO="${PORKETO_REPO:-$(dirname "$DOTFILES_REPO")/the-porketo}"
SERVICE_DIR="$PORKETO_REPO/no-sql/kotlin-service"
APP_SOURCE="$SERVICE_DIR/src/main/kotlin/com/qimono/porketo/Application.kt"
UNIT=/etc/systemd/system/porketo-api.service
ENV_DIR=/etc/porketo-api
ENV_FILE="$ENV_DIR/porketo.env"
ROOT_DIR=/opt/porketo
RELEASES="$ROOT_DIR/releases"
CURRENT="$ROOT_DIR/current"
PREVIOUS="$ROOT_DIR/previous"
SERVICE_USER=porketo
SERVICE_GROUP=porketo
PORT="${PORKETO_PORT:-8080}"
HOST=127.0.0.1
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OLD_RELEASE=""

fail() { echo "ERROR: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"; }
[[ "$EUID" -eq 0 ]] || fail "Run with sudo/root: sudo bash $0"
if [[ "${1:-}" == "--rollback" ]]; then
  [[ -L "$CURRENT" && -L "$PREVIOUS" ]] || fail "No current/previous release pair is available to roll back."
  CURRENT_TARGET="$(readlink -f "$CURRENT")"
  PREVIOUS_TARGET="$(readlink -f "$PREVIOUS")"
  [[ -x "$PREVIOUS_TARGET/bin/porketo-api" ]] || fail "Previous release is incomplete: $PREVIOUS_TARGET"
  SWAP="$(mktemp -u "$ROOT_DIR/.rollback.XXXXXX")"
  ln -s "$PREVIOUS_TARGET" "$SWAP"
  mv -Tf "$SWAP" "$CURRENT"
  SWAP="$(mktemp -u "$ROOT_DIR/.previous.XXXXXX")"
  ln -s "$CURRENT_TARGET" "$SWAP"
  mv -Tf "$SWAP" "$PREVIOUS"
  systemctl restart porketo-api.service
  for _ in $(seq 1 30); do
    if curl --fail --silent --max-time 2 "http://127.0.0.1:$PORT/health" >/dev/null; then
      echo "Rollback successful: $(readlink -f "$CURRENT")"
      exit 0
    fi
    sleep 2
  done
  SWAP="$ROOT_DIR/.current.restore.$STAMP"
  ln -s "$CURRENT_TARGET" "$SWAP"
  mv -Tf "$SWAP" "$CURRENT"
  SWAP="$ROOT_DIR/.previous.restore.$STAMP"
  ln -s "$PREVIOUS_TARGET" "$SWAP"
  mv -Tf "$SWAP" "$PREVIOUS"
  systemctl restart porketo-api.service || true
  fail "Rolled-back release did not become healthy; inspect journalctl -u porketo-api."
fi
[[ $# -eq 0 ]] || fail "Usage: sudo bash $0 [--rollback]"
[[ -d "$PORKETO_REPO/.git" ]] || fail "Porketo repository not found: $PORKETO_REPO"
[[ -f "$SERVICE_DIR/build.gradle.kts" && -f "$APP_SOURCE" ]] || fail "Kotlin service files missing in $SERVICE_DIR"
[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT > 0 && PORT < 65536 )) || fail "Invalid port: $PORT"
for cmd in curl git java python3 systemctl; do need "$cmd"; done

JAVA_VERSION="$(java -version 2>&1 | awk -F '"' '/version/ {print $2; exit}')"
[[ "$JAVA_VERSION" == 21* ]] || fail "Java 21 required; found ${JAVA_VERSION:-unknown}"
if [[ -x "$SERVICE_DIR/gradlew" ]]; then
  GRADLE=("$SERVICE_DIR/gradlew")
elif command -v gradle >/dev/null 2>&1; then
  GRADLE=(gradle)
else
  fail 'Gradle is unavailable; install Gradle or add the committed wrapper first.'
fi

echo '=== Preflight (read only) ==='
printf 'host=%s\nrepo=%s\nrevision=%s\njava=%s\ngradle=%s\nbind=%s:%s\n' \
  "$(hostname)" "$PORKETO_REPO" "$(git -C "$PORKETO_REPO" rev-parse --short HEAD)" \
  "$JAVA_VERSION" "${GRADLE[*]}" "$HOST" "$PORT"
printf 'memory_before='; free -h | awk '/Mem:/ {print $7 " available of " $2}'
printf 'disk_before='; df -h / | awk 'NR==2 {print $4 " available"}'
if [[ -L "$CURRENT" ]]; then OLD_RELEASE="$(readlink -f "$CURRENT" || true)"; fi
if [[ -e "$CURRENT" && ! -L "$CURRENT" ]]; then fail "$CURRENT exists and is not a symlink; refusing to replace it."; fi

echo '=== Ensure source supports a loopback HOST default ==='
python3 - "$APP_SOURCE" "$HOST" <<'PY'
from pathlib import Path
import shutil, sys, time
p = Path(sys.argv[1]); host = sys.argv[2]
s = p.read_text(encoding="utf-8")
old = 'embeddedServer(Netty, host = "0.0.0.0", port = port)'
new = 'embeddedServer(Netty, host = host, port = port)'
port_line = '    val port = System.getenv("PORT")?.toIntOrNull() ?: 8080\n'
host_line = f'    val host = System.getenv("HOST")?.takeIf {{ it.isNotBlank() }} ?: "{host}"\n'
if 'System.getenv("HOST")' in s and new in s:
    print("HOST configuration already present")
elif old in s and port_line in s:
    backup = p.with_name(p.name + ".pre-vps-deploy." + time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()))
    shutil.copy2(p, backup)
    p.write_text(s.replace(port_line, port_line + host_line, 1).replace(old, new, 1), encoding="utf-8")
    print(f"Added HOST configuration (default {host}); backup={backup}")
else:
    raise SystemExit("Unexpected Application.kt bind configuration; inspect it and make HOST configurable before deployment.")
PY

echo '=== Generate wrapper if needed ==='
if [[ ! -x "$SERVICE_DIR/gradlew" ]]; then
  GRADLE_VERSION="$(gradle --version | awk '/^Gradle / {print $2; exit}')"
  [[ -n "$GRADLE_VERSION" ]] || fail 'Could not detect Gradle version.'
  (cd "$SERVICE_DIR" && gradle --no-daemon wrapper --gradle-version "$GRADLE_VERSION")
  [[ -x "$SERVICE_DIR/gradlew" ]] || fail 'Gradle wrapper generation failed.'
fi

echo '=== Build application distribution ==='
"$SERVICE_DIR/gradlew" --no-daemon --max-workers=1 -p "$SERVICE_DIR" installDist
DIST="$SERVICE_DIR/build/install/porketo-api"
[[ -x "$DIST/bin/porketo-api" ]] || fail "Distribution executable missing: $DIST/bin/porketo-api"

echo '=== Create dedicated service identity and protected configuration ==='
getent group "$SERVICE_GROUP" >/dev/null || groupadd --system "$SERVICE_GROUP"
id "$SERVICE_USER" >/dev/null 2>&1 || useradd --system --gid "$SERVICE_GROUP" \
  --home-dir /var/lib/porketo --create-home --shell /usr/sbin/nologin "$SERVICE_USER"
install -d -o root -g root -m 0755 "$ROOT_DIR" "$RELEASES"
install -d -o "$SERVICE_USER" -g "$SERVICE_GROUP" -m 0750 /var/lib/porketo
install -d -o root -g "$SERVICE_GROUP" -m 0750 "$ENV_DIR"
if [[ ! -e "$ENV_FILE" ]]; then
  cat > "$ENV_FILE" <<EOF
# Root-managed service environment. Do not commit credentials.
MONGODB_URI=
MONGODB_DATABASE=porketo
HOST=$HOST
PORT=$PORT
EOF
  echo "Created $ENV_FILE with no Atlas credential; /health will work and /ready will report unavailable."
fi
# Preserve the credential and other settings while enforcing loopback and the
# selected port in the root-managed systemd environment file.
python3 - "$ENV_FILE" "$HOST" "$PORT" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1]); values = {"HOST": sys.argv[2], "PORT": sys.argv[3]}
lines = p.read_text(encoding="utf-8").splitlines()
seen = set(); output = []
for line in lines:
    key = line.split("=", 1)[0].strip() if "=" in line and not line.lstrip().startswith("#") else ""
    if key in values:
        if key not in seen:
            output.append(f"{key}={values[key]}"); seen.add(key)
    else:
        output.append(line)
for key, value in values.items():
    if key not in seen:
        output.append(f"{key}={value}")
p.write_text("\n".join(output).rstrip() + "\n", encoding="utf-8")
PY
chown root:"$SERVICE_GROUP" "$ENV_FILE"
chmod 0640 "$ENV_FILE"

echo '=== Install immutable release and systemd unit ==='
REV="$(git -C "$PORKETO_REPO" rev-parse --short HEAD)"
RELEASE="$RELEASES/${STAMP}-${REV}"
[[ ! -e "$RELEASE" ]] || fail "Release already exists: $RELEASE"
install -d -o root -g root -m 0755 "$RELEASE"
cp -a "$DIST/." "$RELEASE/"
chown -R root:root "$RELEASE"
chmod -R a+rX,go-w "$RELEASE"
if [[ -e "$UNIT" ]] && ! grep -q 'Managed by Qimono vps-ubuntu deploy-porketo-api.sh' "$UNIT"; then
  cp -a "$UNIT" "$UNIT.pre-qimono.$STAMP"
  echo "Backed up existing unit to $UNIT.pre-qimono.$STAMP"
fi
UNIT_TMP="$(mktemp /etc/systemd/system/.porketo-api.XXXXXX)"
cat > "$UNIT_TMP" <<EOF
# Managed by Qimono vps-ubuntu deploy-porketo-api.sh
[Unit]
Description=The Porketo Ktor API
After=network.target
StartLimitIntervalSec=60s
StartLimitBurst=5
[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$CURRENT
EnvironmentFile=$ENV_FILE
ExecStart=$CURRENT/bin/porketo-api
Restart=on-failure
RestartSec=5s
CPUQuota=75%
MemoryMax=768M
TasksMax=64
TimeoutStopSec=30s
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/porketo
[Install]
WantedBy=multi-user.target
EOF
chmod 0644 "$UNIT_TMP"
mv -f "$UNIT_TMP" "$UNIT"
LINK_TMP="$ROOT_DIR/.current.$STAMP"
ln -s "$RELEASE" "$LINK_TMP"
mv -Tf "$LINK_TMP" "$CURRENT"
systemctl daemon-reload
systemctl enable --now porketo-api.service
systemctl restart porketo-api.service

echo '=== Check local health; roll back release if it fails ==='
HEALTHY=0
for _ in $(seq 1 30); do
  if curl --fail --silent --show-error --max-time 2 "http://127.0.0.1:$PORT/health"; then HEALTHY=1; echo; break; fi
  sleep 2
done
if (( ! HEALTHY )); then
  systemctl --no-pager --full status porketo-api.service >&2 || true
  journalctl -u porketo-api.service -n 40 --no-pager >&2 || true
  if [[ -n "$OLD_RELEASE" && -d "$OLD_RELEASE" ]]; then
    ln -s "$OLD_RELEASE" "$ROOT_DIR/.rollback.$STAMP"
    mv -Tf "$ROOT_DIR/.rollback.$STAMP" "$CURRENT"
    systemctl restart porketo-api.service || true
    echo "Previous release restored: $OLD_RELEASE" >&2
  else
    systemctl stop porketo-api.service || true
    echo 'First deployment failed; service stopped.' >&2
  fi
  fail 'Health check failed; inspect the service journal.'
fi

if [[ -n "$OLD_RELEASE" && -d "$OLD_RELEASE" ]]; then
  PREVIOUS_TMP="$ROOT_DIR/.previous.$STAMP"
  ln -s "$OLD_RELEASE" "$PREVIOUS_TMP"
  mv -Tf "$PREVIOUS_TMP" "$PREVIOUS"
fi

echo '=== Atlas readiness (informational) ==='
if ! curl --fail --silent --show-error --max-time 5 "http://127.0.0.1:$PORT/ready"; then
  echo 'Atlas is not ready. Set MONGODB_URI in /etc/porketo-api/porketo.env and restart the service.'
fi
echo
echo '=== Deployment complete ==='
printf 'release=%s\ncurrent=%s\nhealth=http://127.0.0.1:%s/health\nenvironment_file=%s (values not shown)\n' \
  "$RELEASE" "$(readlink -f "$CURRENT")" "$PORT" "$ENV_FILE"
printf 'memory_after='; free -h | awk '/Mem:/ {print $7 " available of " $2}'
printf 'disk_after='; df -h / | awk 'NR==2 {print $4 " available"}'
cat <<EOF

Operations:
  systemctl status porketo-api
  journalctl -u porketo-api -f
  systemctl stop porketo-api
  systemctl start porketo-api
  systemctl disable porketo-api

The API is loopback-only. No Nginx, firewall, public-port, or reboot changes were made.
EOF
