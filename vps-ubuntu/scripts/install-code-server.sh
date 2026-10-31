#!/usr/bin/env bash
# Install code-server as an isolated, password-protected, loopback-only service.
# Run: sudo bash vps-ubuntu/scripts/install-code-server.sh [--start|--stop]
# Service is on-demand and disabled at boot; use an SSH local forward to access.
set -Eeuo pipefail
umask 077
[[ "$EUID" -eq 0 ]] || { echo "Run as root: sudo bash $0" >&2; exit 1; }
ACTION="${1:---start}"
[[ "$ACTION" == --start || "$ACTION" == --stop ]] || { echo "Usage: $0 [--start|--stop]" >&2; exit 2; }

VERSION=4.144.0
ARCHIVE="code-server-${VERSION}-linux-amd64.tar.gz"
SHA256=710f749c40a0f3d0ab3be09c0de65314e5c2907cc50646f5fbc0f24c0e8fba2d
ROOT=/opt/qimono-code-server
RELEASES="$ROOT/releases"
CURRENT="$ROOT/current"
USER_NAME=codeserver
GROUP_NAME=codeserver
WORKSPACES=/srv/qimono/workspaces
CONF_DIR=/etc/qimono-code-server
CONF="$CONF_DIR/config.yaml"
UNIT=/etc/systemd/system/qimono-code-server.service
PORT=13337
DOTFILES_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORKETO_SOURCE="$(dirname "$DOTFILES_SOURCE")/the-porketo"
MANIFEST="$DOTFILES_SOURCE/vps-ubuntu/guix/manifest.scm"
GUIX="/root/.config/guix/current/bin/guix"

if [[ "$ACTION" == --stop ]]; then
  systemctl stop qimono-code-server.service
  echo "Stopped. Start it with: sudo systemctl start qimono-code-server"
  exit 0
fi
for cmd in curl tar sha256sum git systemctl openssl runuser; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 1; }
done

getent group "$GROUP_NAME" >/dev/null || groupadd --system "$GROUP_NAME"
id "$USER_NAME" >/dev/null 2>&1 || useradd --system --gid "$GROUP_NAME" \
  --home-dir /var/lib/qimono-code-server --create-home --shell /usr/sbin/nologin "$USER_NAME"
install -d -o root -g root -m 0755 "$ROOT" "$RELEASES"
install -d -o root -g "$GROUP_NAME" -m 0750 /srv/qimono
install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0750 /var/lib/qimono-code-server "$WORKSPACES"
install -d -o root -g "$GROUP_NAME" -m 0750 "$CONF_DIR"

RELEASE="$RELEASES/v${VERSION}"
if [[ ! -x "$RELEASE/bin/code-server" ]]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "Downloading official code-server ${VERSION} release..."
  curl -fL "https://github.com/coder/code-server/releases/download/v${VERSION}/${ARCHIVE}" -o "$tmp/$ARCHIVE"
  printf '%s  %s\n' "$SHA256" "$tmp/$ARCHIVE" | sha256sum -c -
  tar -xzf "$tmp/$ARCHIVE" -C "$tmp"
  install -d -o root -g root -m 0755 "$RELEASE"
  cp -a "$tmp/code-server-${VERSION}-linux-amd64/." "$RELEASE/"
  chown -R root:root "$RELEASE"
  chmod -R a+rX,go-w "$RELEASE"
fi
if [[ ! -L "$CURRENT" ]]; then
  [[ ! -e "$CURRENT" ]] || { echo "$CURRENT exists and is not a symlink." >&2; exit 1; }
  ln -s "$RELEASE" "$ROOT/.current.${VERSION}"
  mv -Tf "$ROOT/.current.${VERSION}" "$CURRENT"
fi

# These are separate service-user checkouts. The service cannot read root's
# home, agent credentials, or the root-owned Atlas environment file.
if [[ -d "$DOTFILES_SOURCE/.git" && ! -d "$WORKSPACES/dotfiles/.git" ]]; then
  git clone --no-hardlinks "$DOTFILES_SOURCE" "$WORKSPACES/dotfiles"
  git -C "$WORKSPACES/dotfiles" remote set-url origin https://github.com/qimono-repos/dotfiles.git
  # Capture this checkout's tracked edits and non-ignored new files in the
  # initial private workspace without copying .git, ignored environments, or
  # secrets. Never overlay an existing IDE workspace on reruns.
  while IFS= read -r -d '' path; do
    if [[ -e "$DOTFILES_SOURCE/$path" || -L "$DOTFILES_SOURCE/$path" ]]; then
      install -d "$WORKSPACES/dotfiles/$(dirname "$path")"
      cp -a "$DOTFILES_SOURCE/$path" "$WORKSPACES/dotfiles/$path"
    fi
  done < <(git -C "$DOTFILES_SOURCE" ls-files --cached --others --exclude-standard -z)
  while IFS= read -r -d '' path; do rm -f "$WORKSPACES/dotfiles/$path"; done \
    < <(git -C "$DOTFILES_SOURCE" ls-files --deleted -z)
fi
if [[ -d "$PORKETO_SOURCE/.git" && ! -d "$WORKSPACES/the-porketo/.git" ]]; then
  git clone --no-hardlinks "$PORKETO_SOURCE" "$WORKSPACES/the-porketo"
  git -C "$WORKSPACES/the-porketo" remote set-url origin https://github.com/qimono-repos/the-porketo.git
  while IFS= read -r -d '' path; do
    if [[ -e "$PORKETO_SOURCE/$path" || -L "$PORKETO_SOURCE/$path" ]]; then
      install -d "$WORKSPACES/the-porketo/$(dirname "$path")"
      cp -a "$PORKETO_SOURCE/$path" "$WORKSPACES/the-porketo/$path"
    fi
  done < <(git -C "$PORKETO_SOURCE" ls-files --cached --others --exclude-standard -z)
  while IFS= read -r -d '' path; do rm -f "$WORKSPACES/the-porketo/$path"; done \
    < <(git -C "$PORKETO_SOURCE" ls-files --deleted -z)
fi
chown -R "$USER_NAME:$GROUP_NAME" "$WORKSPACES"

# Give the IDE user its own copy of the reproducible Guix tool profile.
if [[ ! -x /var/lib/qimono-code-server/.guix-profile/bin/gh ]]; then
  "$GUIX" package --manifest="$MANIFEST" --profile=/var/lib/qimono-code-server/.guix-profile
fi
install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0700 /var/lib/qimono-code-server/.config /var/lib/qimono-code-server/.config/gh
chown "$USER_NAME:$GROUP_NAME" /var/lib/qimono-code-server/.config
chmod 0700 /var/lib/qimono-code-server/.config
runuser -u "$USER_NAME" -- env HOME=/var/lib/qimono-code-server GH_CONFIG_DIR=/var/lib/qimono-code-server/.config/gh \
  /var/lib/qimono-code-server/.guix-profile/bin/gh config set editor nvim
runuser -u "$USER_NAME" -- env HOME=/var/lib/qimono-code-server GH_CONFIG_DIR=/var/lib/qimono-code-server/.config/gh \
  /var/lib/qimono-code-server/.guix-profile/bin/gh config set git_protocol ssh
GIT_CONFIG=/var/lib/qimono-code-server/.gitconfig
if [[ ! -e "$GIT_CONFIG" ]]; then install -o "$USER_NAME" -g "$GROUP_NAME" -m 0600 /dev/null "$GIT_CONFIG"; fi
for workspace in "$WORKSPACES/dotfiles" "$WORKSPACES/the-porketo"; do
  if [[ -d "$workspace/.git" ]] && ! git config --file "$GIT_CONFIG" --get-all safe.directory 2>/dev/null | grep -Fxq "$workspace"; then
    runuser -u "$USER_NAME" -- sh -c \
      "cd / && HOME=/var/lib/qimono-code-server /usr/bin/git config --file '$GIT_CONFIG' --add safe.directory '$workspace'"
  fi
done

if [[ ! -e "$CONF" ]]; then
  password="$(openssl rand -hex 32)"
  cat > "$CONF" <<EOF
bind-addr: 127.0.0.1:$PORT
auth: password
password: "$password"
cert: false
EOF
  unset password
fi
chown root:"$GROUP_NAME" "$CONF"
chmod 0640 "$CONF"

if [[ ! -e "$UNIT" ]] || ! grep -q 'Managed by Qimono vps-ubuntu install-code-server.sh' "$UNIT"; then
  if [[ -e "$UNIT" ]]; then cp -a "$UNIT" "$UNIT.pre-qimono.$(date -u +%Y%m%dT%H%M%SZ)"; fi
  unit_tmp="$(mktemp /etc/systemd/system/.qimono-code-server.XXXXXX)"
  cat > "$unit_tmp" <<EOF
# Managed by Qimono vps-ubuntu install-code-server.sh
[Unit]
Description=Qimono private browser IDE (code-server)
After=network.target
StartLimitIntervalSec=60s
StartLimitBurst=5
[Service]
Type=simple
User=$USER_NAME
Group=$GROUP_NAME
WorkingDirectory=$WORKSPACES
Environment=HOME=/var/lib/qimono-code-server
Environment=PATH=/var/lib/qimono-code-server/.guix-profile/bin:/usr/local/bin:/usr/bin:/bin:/var/lib/qimono-code-server/.local/bin
ExecStart=$CURRENT/bin/code-server --config $CONF --user-data-dir /var/lib/qimono-code-server/user-data --extensions-dir /var/lib/qimono-code-server/extensions $WORKSPACES
Restart=on-failure
RestartSec=10s
TimeoutStopSec=30s
CPUQuota=75%
MemoryMax=1G
TasksMax=64
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/qimono-code-server $WORKSPACES
[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "$unit_tmp"
  mv -f "$unit_tmp" "$UNIT"
fi

systemctl daemon-reload
systemctl disable qimono-code-server.service >/dev/null 2>&1 || true
systemctl start qimono-code-server.service
healthy=0
for _ in $(seq 1 30); do
  if curl --fail --silent --max-time 2 "http://127.0.0.1:$PORT/healthz" >/dev/null; then healthy=1; break; fi
  sleep 2
done
if (( ! healthy )); then
  systemctl --no-pager --full status qimono-code-server.service >&2 || true
  journalctl -u qimono-code-server.service -n 40 --no-pager >&2 || true
  systemctl stop qimono-code-server.service || true
  echo "Health check failed; code-server is stopped. Inspect journalctl -u qimono-code-server." >&2
  exit 1
fi

printf 'code-server version: '
"$CURRENT/bin/code-server" --version | head -n 1
printf 'Listening: 127.0.0.1:%s (password authentication)\n' "$PORT"
printf 'Service: active now, disabled at boot; limits: CPU 75%%, RAM 1 GiB, 64 tasks\n'
printf 'Workspace: %s (dedicated service-user copies)\n' "$WORKSPACES"
printf 'Password file: %s (not printed)\n' "$CONF"
cat <<EOF

From your local computer, open an SSH tunnel:
  ssh -N -L $PORT:127.0.0.1:$PORT root@$(hostname -f)
Then visit http://127.0.0.1:$PORT. Read the password from $CONF.
Stop when finished: sudo systemctl stop qimono-code-server
Start again: sudo systemctl start qimono-code-server
EOF
