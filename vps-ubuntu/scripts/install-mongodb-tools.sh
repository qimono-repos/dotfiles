#!/usr/bin/env bash
# Install official MongoDB Atlas CLI and mongosh on Ubuntu/Debian x86_64.
# No MongoDB server is installed. Downloads are verified before installation.
set -Eeuo pipefail
[[ "$EUID" -eq 0 ]] || { echo "Run as root: sudo bash $0" >&2; exit 1; }
[[ "$(dpkg --print-architecture)" == amd64 ]] || { echo "This installer currently targets amd64." >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl python3

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "=== MongoDB Atlas CLI ==="
python3 - "$tmp" <<'PY'
import json, pathlib, sys, urllib.request, hashlib
root = pathlib.Path(sys.argv[1])
api = "https://api.github.com/repos/mongodb/mongodb-atlas-cli/releases/latest"
req = urllib.request.Request(api, headers={"Accept":"application/vnd.github+json","User-Agent":"qimono-vps-provisioner"})
with urllib.request.urlopen(req, timeout=30) as r:
    release = json.load(r)
assets = {a["name"]: a["browser_download_url"] for a in release.get("assets", [])}
deb = next((n for n in assets if n.endswith("_linux_x86_64.deb")), None)
checks = next((n for n in assets if n == "checksums.txt"), None)
if not deb or not checks:
    raise SystemExit("Could not find Atlas CLI amd64 .deb and checksums.txt in latest release")
for name in (deb, checks):
    req = urllib.request.Request(assets[name], headers={"User-Agent":"qimono-vps-provisioner"})
    with urllib.request.urlopen(req, timeout=60) as r:
        (root/name).write_bytes(r.read())
expected = None
for line in (root/checks).read_text().splitlines():
    parts = line.split()
    if len(parts) >= 2 and parts[-1].lstrip("*") == deb:
        expected = parts[0]
        break
if not expected:
    raise SystemExit("Atlas CLI checksum entry not found")
actual = hashlib.sha256((root/deb).read_bytes()).hexdigest()
if actual.lower() != expected.lower():
    raise SystemExit("Atlas CLI SHA-256 mismatch; refusing installation")
print(f"Verified Atlas CLI {release.get('tag_name')} ({actual})")
(root/"atlas-deb-name").write_text(deb)
PY
atlas_deb="$(cat "$tmp/atlas-deb-name")"
apt-get install -y "$tmp/$atlas_deb"
atlas --version

echo "mongosh intentionally skipped: Atlas CLI is sufficient for this VPS milestone."
echo "MongoDB Atlas CLI installed. No MongoDB server or mongosh was installed."
