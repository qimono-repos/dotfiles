#!/usr/bin/env bash
set -euo pipefail

version=${QIMONO_GH_VERSION:-}
bin_dir=${QIMONO_GH_BIN_DIR:-$HOME/.local/bin}

if [[ -z "$version" ]]; then
  version="$(curl -fsSL --max-time 30 https://api.github.com/repos/cli/cli/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"
fi

plain_version=${version#v}

if [[ -x "$bin_dir/gh" ]]; then
  installed="$("$bin_dir/gh" --version 2>/dev/null | awk 'NR==1 {print $3}')"
  if [[ "$installed" == "$plain_version" ]]; then
    echo "gh $plain_version already installed at $bin_dir/gh"
    "$bin_dir/gh" config set git_protocol ssh
    exit 0
  fi
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

archive="gh_${plain_version}_linux_amd64.tar.gz"
checksums="gh_${plain_version}_checksums.txt"
base="https://github.com/cli/cli/releases/download/${version}"

curl -fsSL --retry 3 --max-time 300 -o "$tmp/$archive" "$base/$archive"
curl -fsSL --retry 3 --max-time 60 -o "$tmp/$checksums" "$base/$checksums"
awk -v name="$archive" '$2 == name { print }' "$tmp/$checksums" | sha256sum -c -

mkdir -p "$bin_dir"
tar -xzf "$tmp/$archive" -C "$tmp"
install -m 0755 "$tmp/gh_${plain_version}_linux_amd64/bin/gh" "$bin_dir/gh"
"$bin_dir/gh" config set git_protocol ssh
"$bin_dir/gh" --version
