#!/usr/bin/env bash
# QIMONO GUIX LOBBY | Codex + OpenCode + Ollama | v1.1.0
# Native musl Codex and OpenCode V2 in ~/.local/bin.
# Ollama: Guix package if available; otherwise official archive adapted for Guix.
# Override: QIMONO_OLLAMA=auto|force|off (auto checks free space).
set -Eeuo pipefail

NAME="qimono-agents"
INSTALL_BIN="$HOME/.local/bin"
OPT_DIR="$HOME/.local/opt"
STATE_DIR="$HOME/.local/state/qimono"
TMP="$(mktemp -d)"
LOG="$STATE_DIR/agents-$(date -u +%Y%m%dT%H%M%SZ).log"
OLLAMA_MODE="${QIMONO_OLLAMA:-auto}"
RESULTS=()

say() { printf '\n[%s] %s\n' "$NAME" "$*"; }
problem() { printf '[%s] ISSUE: %s\n' "$NAME" "$*" >&2; }
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT
trap 'printf "[%s] ERROR at line %s (status %s)\n" "$NAME" "$LINENO" "$?" >&2' ERR

if (( EUID == 0 )); then
  printf '[%s] Run as qi, not root.\n' "$NAME" >&2
  exit 1
fi
mkdir -p "$INSTALL_BIN" "$OPT_DIR" "$STATE_DIR"
exec > >(tee -a "$LOG") 2>&1

GUIX_PROFILE="$HOME/.guix-profile"
if [[ -f "$GUIX_PROFILE/etc/profile" ]]; then
  export GUIX_PROFILE
  . "$GUIX_PROFILE/etc/profile"
fi
export PATH="$INSTALL_BIN:$HOME/.guix-profile/bin:$PATH"
hash -r

PROFILE_LINE='[ -f "$HOME/.guix-profile/etc/profile" ] && GUIX_PROFILE="$HOME/.guix-profile" && export GUIX_PROFILE && . "$GUIX_PROFILE/etc/profile"'
BIN_LINE='export PATH="$HOME/.local/bin:$PATH"'
touch "$HOME/.bash_profile"
grep -Fqx "$PROFILE_LINE" "$HOME/.bash_profile" || printf '%s\n' "$PROFILE_LINE" >> "$HOME/.bash_profile"
grep -Fqx "$BIN_LINE" "$HOME/.bash_profile" || printf '%s\n' "$BIN_LINE" >> "$HOME/.bash_profile"

download() {
  local url="$1" dest="$2"
  say "Downloading $url"
  rm -f "$dest"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --connect-timeout 30 --output "$dest" "$url" || return 1
  else
    wget -q --show-progress --tries=3 --timeout=60 -O "$dest" "$url" || return 1
  fi
  [[ -s "$dest" ]]
}
install_binary() {
  install -m 0755 "$1" "$INSTALL_BIN/$2"
  "$INSTALL_BIN/$2" --version
}
say "Starting v1.1.0 at $(date -u --iso-8601=seconds)"
say "Architecture: $(uname -m)"
say "Resource preflight: RAM, storage and existing installs"
free -h || true
df -h "$HOME" /gnu/store /tmp
du -sh "$INSTALL_BIN" "$OPT_DIR" 2>/dev/null || true
say "Planning budgets for temporary downloads, extraction and installed binaries (not exact release sizes): Codex 250 MiB; OpenCode 350 MiB; Ollama runtime 3072 MiB, models excluded"
CODEX_BUDGET_MIB=250
OPENCODE_BUDGET_MIB=350
available_mib() { df -Pm "$HOME" | awk 'NR==2{print $4}'; }

case "$(uname -m)" in
  x86_64) CODEX_ARCH=x86_64; OPENCODE_ARCH=x64; OLLAMA_ARCH=amd64 ;;
  aarch64) CODEX_ARCH=aarch64; OPENCODE_ARCH=arm64; OLLAMA_ARCH=arm64 ;;
  *) printf 'Unsupported architecture for these binaries.\n' >&2; exit 1 ;;
esac

install_codex() {
  local archive="$TMP/codex.tar.gz" extracted
  download "https://github.com/openai/codex/releases/latest/download/codex-$CODEX_ARCH-unknown-linux-musl.tar.gz" "$archive" || return 1
  mkdir -p "$TMP/codex"
  tar -xzf "$archive" -C "$TMP/codex" || return 1
  extracted="$(find "$TMP/codex" -type f -name 'codex-*linux-musl' -print -quit)"
  [[ -n "$extracted" ]] || { problem "Codex binary absent from archive"; return 1; }
  install_binary "$extracted" codex
}

install_opencode() {
  local archive="$TMP/opencode.tar.gz" extracted flavor ok=0
  for flavor in "opencode-linux-$OPENCODE_ARCH-musl" "opencode-linux-$OPENCODE_ARCH-baseline-musl"; do
    if download "https://opencode.ai/update/api/latest/cli/opencode/$flavor.tar.gz" "$archive"; then
      ok=1; break
    fi
  done
  (( ok )) || { problem "OpenCode archive download failed"; return 1; }
  mkdir -p "$TMP/opencode"
  tar -xzf "$archive" -C "$TMP/opencode" || return 1
  extracted="$(find "$TMP/opencode" -type f -name opencode -print -quit)"
  [[ -n "$extracted" ]] || { problem "OpenCode binary absent from archive"; return 1; }
  install_binary "$extracted" opencode
}

install_ollama_guix() {
  say "Checking the active Guix channels for Ollama"
  if guix show ollama >/dev/null 2>&1; then
    guix install ollama
    GUIX_PROFILE="$HOME/.guix-profile"
    . "$GUIX_PROFILE/etc/profile"
    command -v ollama >/dev/null && ollama --version
    return $?
  fi
  return 1
}

install_ollama_official() {
  local archive="$TMP/ollama.tar.zst"
  local prefix="$OPT_DIR/ollama" executable glibc gcc_lib interpreter runtime_libs
  say "Using official Ollama Linux archive adapted for Guix"
  guix install zstd patchelf || return 1
  GUIX_PROFILE="$HOME/.guix-profile"
  . "$GUIX_PROFILE/etc/profile"
  export PATH="$INSTALL_BIN:$GUIX_PROFILE/bin:$PATH"
  hash -r

  download "https://ollama.com/download/ollama-linux-$OLLAMA_ARCH.tar.zst" "$archive" || return 1
  mkdir -p "$prefix"
  tar --zstd -xf "$archive" -C "$prefix" || return 1
  executable="$prefix/bin/ollama"
  [[ -f "$executable" ]] || { problem "bin/ollama missing in archive"; return 1; }

  glibc="$(guix build glibc | tail -n 1)" || return 1
  gcc_lib="$(guix build gcc:lib | tail -n 1)" || return 1
  case "$(uname -m)" in
    x86_64) interpreter="$glibc/lib/ld-linux-x86-64.so.2" ;;
    aarch64) interpreter="$glibc/lib/ld-linux-aarch64.so.1" ;;
  esac
  [[ -f "$interpreter" ]] || { problem "Guix ELF interpreter missing: $interpreter"; return 1; }
  if patchelf --print-interpreter "$executable" >/dev/null 2>&1; then
    patchelf --set-interpreter "$interpreter" "$executable"
  fi
  runtime_libs="$glibc/lib:$gcc_lib/lib:$prefix/lib/ollama"
  if patchelf --print-rpath "$executable" >/dev/null 2>&1; then
    patchelf --set-rpath "$runtime_libs" "$executable"
  fi

  cat > "$INSTALL_BIN/ollama" <<EOF
#!/usr/bin/env bash
export LD_LIBRARY_PATH="$runtime_libs:\${LD_LIBRARY_PATH:-}"
export OLLAMA_MODELS="\${OLLAMA_MODELS:-\$HOME/.local/share/ollama/models}"
exec "$executable" "\$@"
EOF
  chmod 0755 "$INSTALL_BIN/ollama" || return 1
  "$INSTALL_BIN/ollama" --version
}

if (( $(available_mib) >= CODEX_BUDGET_MIB )); then
  if install_codex; then RESULTS+=("codex: installed"); else RESULTS+=("codex: needs review"); fi
else
  RESULTS+=("codex: deferred; less than 250 MiB free")
fi
df -h "$HOME"
if (( $(available_mib) >= OPENCODE_BUDGET_MIB )); then
  if install_opencode; then RESULTS+=("opencode: installed"); else RESULTS+=("opencode: needs review"); fi
else
  RESULTS+=("opencode: deferred; less than 350 MiB free")
fi
df -h "$HOME"

case "$OLLAMA_MODE" in
  off) RESULTS+=("ollama: disabled") ;;
  auto|force)
    free_kib="$(df -Pk "$HOME" | awk 'NR==2{print $4}')"
    if [[ "$OLLAMA_MODE" == auto ]] && (( free_kib < 3145728 )); then
      RESULTS+=("ollama: deferred; less than 3 GiB free for archive and extraction")
    elif install_ollama_guix || install_ollama_official; then
      RESULTS+=("ollama: installed")
    else
      RESULTS+=("ollama: needs review; see log")
    fi
    ;;
  *) problem "QIMONO_OLLAMA must be auto, force or off"; exit 2 ;;
esac

say "Final resources"
free -h || true
df -h "$HOME" /gnu/store /tmp
du -sh "$INSTALL_BIN" "$OPT_DIR" 2>/dev/null || true
say "Final summary"
printf '  %s\n' "${RESULTS[@]}"
say "Version checks"
for tool in codex opencode ollama; do
  if command -v "$tool" >/dev/null 2>&1; then "$tool" --version || true; fi
done
echo "No models downloaded. To serve local models: ollama serve"
echo "Full log: $LOG"
