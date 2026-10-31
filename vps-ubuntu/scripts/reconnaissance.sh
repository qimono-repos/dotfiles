#!/usr/bin/env bash
# Qimono VPS read-only reconnaissance for the first Porketo API milestone.
# Collects host state and repository metadata without installing or changing
# anything. It does not read secret files or print environment variable values.
#
# Usage:
#   sudo bash vps-ubuntu/scripts/reconnaissance.sh
#   sudo bash vps-ubuntu/scripts/reconnaissance.sh --app-repo /path/to/the-porketo
#   sudo bash vps-ubuntu/scripts/reconnaissance.sh --stdout

set -uo pipefail
umask 077

DEFAULT_DOTFILES="${DOTFILES_REPO:-}"
if [[ -z "$DEFAULT_DOTFILES" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  DEFAULT_DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
DOTFILES_REPO="$DEFAULT_DOTFILES"
APP_REPO="${PORKETO_REPO:-}"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp}"
WRITE_REPORT=1

while (($#)); do
  case "$1" in
    --dotfiles-repo)
      (($# >= 2)) || { echo "--dotfiles-repo requires a path" >&2; exit 2; }
      DOTFILES_REPO="$2"; shift 2 ;;
    --app-repo)
      (($# >= 2)) || { echo "--app-repo requires a path" >&2; exit 2; }
      APP_REPO="$2"; shift 2 ;;
    --output-dir)
      (($# >= 2)) || { echo "--output-dir requires a path" >&2; exit 2; }
      OUTPUT_DIR="$2"; shift 2 ;;
    --stdout)
      WRITE_REPORT=0; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$APP_REPO" ]]; then
  if [[ -d "$(dirname "$DOTFILES_REPO")/the-porketo/.git" ]]; then
    APP_REPO="$(dirname "$DOTFILES_REPO")/the-porketo"
  elif [[ -d "$HOME/source/repos/qimono-repos/the-porketo/.git" ]]; then
    APP_REPO="$HOME/source/repos/qimono-repos/the-porketo"
  else
    APP_REPO="$HOME/source/repos/qimono-repos/the-porketo"
  fi
fi

if (( WRITE_REPORT )); then
  mkdir -p "$OUTPUT_DIR" || { echo "Cannot create output directory: $OUTPUT_DIR" >&2; exit 1; }
  REPORT="$OUTPUT_DIR/qimono-vps-recon-$(date -u +%Y%m%dT%H%M%SZ).txt"
  exec > >(tee "$REPORT") 2>&1
fi

section() { printf '\n\n===== %s =====\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
version_or_missing() {
  local name="$1"; shift
  if have "$name"; then
    printf '$'; printf ' %q' "$@"; printf '\n'
    "$@" 2>&1 | head -n 3
  else
    printf '%s: not installed\n' "$name"
  fi
}
repo_state() {
  local label="$1" path="$2"
  section "$label repository"
  printf 'path=%s\n' "$path"
  if [[ ! -d "$path/.git" ]]; then
    echo 'git_repository=not found'
    return
  fi
  printf 'branch='; git -C "$path" branch --show-current 2>/dev/null || true
  printf 'commit='; git -C "$path" rev-parse --short HEAD 2>/dev/null || true
  echo 'working_tree_status:'
  git -C "$path" status --short 2>&1 || true
  [[ -z "$(git -C "$path" status --porcelain 2>/dev/null)" ]] && echo '  clean'
}

section 'Report metadata'
printf 'captured_at_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'report_user=%s\n' "$(id -un 2>/dev/null || echo unknown)"
printf 'dotfiles_repo=%s\n' "$DOTFILES_REPO"
printf 'porketo_repo=%s\n' "$APP_REPO"
echo 'This report does not include environment values, credentials, process command lines, or secret-file contents.'

section 'Host and operating system'
printf 'hostname='; hostname 2>/dev/null || true
printf 'kernel='; uname -srmo 2>/dev/null || true
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf 'os=%s\nversion=%s\ncodename=%s\n' "${PRETTY_NAME:-unknown}" "${VERSION_ID:-unknown}" "${VERSION_CODENAME:-unknown}"
fi
printf 'uptime='; uptime -p 2>/dev/null || true
printf 'timezone='; timedatectl show -p Timezone --value 2>/dev/null || date +%Z

section 'CPU, memory, and storage'
lscpu 2>/dev/null | grep -E '^(Architecture|CPU\(s\)|Model name|Vendor ID|Thread|Core|Socket|Hypervisor vendor):' || true
free -h 2>/dev/null || true
df -hT / 2>/dev/null || true
df -ih / 2>/dev/null || true

section 'Network exposure and firewall (read-only)'
if have ss; then ss -lntup 2>&1 || ss -lntu 2>&1 || true; else echo 'ss: not installed'; fi
if have ufw; then ufw status 2>&1 || true; else echo 'ufw: not installed'; fi
if have nft; then nft list ruleset 2>&1 | sed -n '1,100p' || true; else echo 'nft: not installed'; fi

section 'Active services of interest'
for svc in ssh nginx caddy docker containerd mongod porketo-api code-server openvscode-server; do
  if have systemctl; then
    state="$(systemctl is-active "$svc" 2>/dev/null || true)"
    enabled="$(systemctl is-enabled "$svc" 2>/dev/null || true)"
    printf '%-22s active=%s enabled=%s\n' "$svc" "${state:-unknown}" "${enabled:-unknown}"
  else
    echo 'systemctl: not available'
    break
  fi
done
if have systemctl; then
  echo 'running_services:'
  systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null | awk '{print $1}' | head -n 60
fi

section 'Installed tool versions'
version_or_missing java java -version
version_or_missing javac javac -version
version_or_missing gradle gradle --version
version_or_missing guix guix --version
version_or_missing zsh zsh --version
version_or_missing stow stow --version
version_or_missing git git --version
version_or_missing atlas atlas --version
version_or_missing codex codex --version
version_or_missing opencode opencode --version
version_or_missing nginx nginx -v
version_or_missing curl curl --version

section 'Porketo API workspace'
if [[ -d "$APP_REPO" ]]; then
  repo_state 'Porketo' "$APP_REPO"
  SERVICE="$APP_REPO/no-sql/kotlin-service"
  if [[ -d "$SERVICE" ]]; then
    printf 'service_path=%s\n' "$SERVICE"
    for f in settings.gradle.kts build.gradle.kts gradle.properties README.md deploy/README.md; do
      [[ -f "$SERVICE/$f" ]] && printf 'present=%s\n' "$f" || printf 'missing=%s\n' "$f"
    done
    [[ -x "$SERVICE/gradlew" ]] && echo 'gradle_wrapper=present_executable' || echo 'gradle_wrapper=missing_or_not_executable'
    [[ -f "$SERVICE/src/main/kotlin/com/qimono/porketo/Application.kt" ]] && echo 'ktor_application=present' || echo 'ktor_application=missing'
    [[ -f "$SERVICE/src/test/kotlin/com/qimono/porketo/ApplicationTest.kt" ]] && echo 'application_tests=present' || echo 'application_tests=missing'
    echo 'service_source_bind_configuration:'
    if [[ -r "$SERVICE/src/main/kotlin/com/qimono/porketo/Application.kt" ]]; then
      rg -n 'embeddedServer|host\s*=|get\("/(health|ready)"\)|MONGODB_URI|MONGODB_DATABASE|PORT' \
        "$SERVICE/src/main/kotlin/com/qimono/porketo/Application.kt" 2>/dev/null || true
    fi
  else
    echo "kotlin_service=not found under $APP_REPO/no-sql/kotlin-service"
  fi
else
  echo 'porketo_repository=not found'
fi

section 'Dotfiles repository state'
repo_state 'Dotfiles' "$DOTFILES_REPO"

section 'Relevant deployment files'
for f in \
  "$DOTFILES_REPO/vps-ubuntu/README.md" \
  "$DOTFILES_REPO/vps-ubuntu/NEXT_STEPS_VPS.md" \
  "$DOTFILES_REPO/vps-ubuntu/guix/manifest.scm" \
  "$DOTFILES_REPO/vps-ubuntu/scripts/provision-vps.sh" \
  "$DOTFILES_REPO/vps-ubuntu/stow-source/shell/.zshrc"; do
  [[ -f "$f" ]] && printf 'present=%s\n' "$f" || printf 'missing=%s\n' "$f"
done

section 'Existing proxy and service definitions (paths only)'
for path in /etc/nginx/sites-enabled /etc/nginx/conf.d /etc/systemd/system; do
  if [[ -d "$path" ]]; then
    printf '[%s]\n' "$path"
    find "$path" -maxdepth 2 \( -type f -o -type l \) -printf '%f\n' 2>/dev/null | sort | head -n 80
  else
    printf '%s: absent\n' "$path"
  fi
done

section 'End of report'
echo 'No package installation, service changes, network changes, repository writes, or reboots were performed.'
if (( WRITE_REPORT )); then
  echo "report_file=$REPORT"
  echo 'The report is created with mode 0600. Review it before sharing; host and network metadata may be sensitive.'
fi
