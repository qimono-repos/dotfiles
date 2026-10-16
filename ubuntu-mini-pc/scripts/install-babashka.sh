#!/usr/bin/env bash
# Install a pinned Babashka release into ~/.local/bin without sudo.
#
# Update BB_VERSION and the matching official SHA-256 together when upgrading.
# Release assets and checksums: https://github.com/babashka/babashka/releases
set -Eeuo pipefail

readonly BB_VERSION="1.13.219"
readonly BB_SHA256_AMD64="9ac1fe988d7001625b30ef3e3307e67f8545505a7cb49a4aa179f578115a3e09"
readonly INSTALL_DIR="${HOME}/.local/bin"
readonly ASSET="babashka-${BB_VERSION}-linux-amd64-static.tar.gz"
readonly URL="https://github.com/babashka/babashka/releases/download/v${BB_VERSION}/${ASSET}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

case "$(uname -s)" in
  Linux) ;;
  *) die "This installer currently supports Linux only." ;;
esac

case "$(uname -m)" in
  x86_64|amd64) ;;
  *) die "Unsupported architecture: $(uname -m). This pinned build targets x86_64." ;;
esac

for cmd in curl sha256sum tar install mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

archive="${tmp_dir}/${ASSET}"
printf 'Downloading Babashka %s...\n' "$BB_VERSION"
curl --fail --location --silent --show-error "$URL" --output "$archive"

printf '%s  %s\n' "$BB_SHA256_AMD64" "$archive" | sha256sum --check --status \
  || die "SHA-256 verification failed for ${ASSET}; refusing to install."

tar -xzf "$archive" -C "$tmp_dir" bb
[[ -f "${tmp_dir}/bb" ]] || die "Expected bb executable was not present in the release archive."

mkdir -p "$INSTALL_DIR"
install -m 0755 "${tmp_dir}/bb" "${INSTALL_DIR}/bb"

printf 'Installed: %s\n' "${INSTALL_DIR}/bb"
"${INSTALL_DIR}/bb" --version
"${INSTALL_DIR}/bb" -e '(println "Babashka is alive!")'

case ":$PATH:" in
  *":${INSTALL_DIR}:"*)
    printf 'PATH already includes %s\n' "$INSTALL_DIR"
    ;;
  *)
    printf 'Note: %s is not currently on PATH. Add it through your dotfiles shell configuration.\n' "$INSTALL_DIR"
    ;;
esac
