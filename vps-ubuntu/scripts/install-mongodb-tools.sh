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

echo "=== MongoDB Shell (mongosh) ==="
# Use the official mongosh GitHub release asset. Ubuntu 26.04 is newer than
# MongoDB's documented APT repository matrix, so avoid adding an OS repo.
python3 - "$tmp" <<'PY'
import hashlib, json, pathlib, sys, urllib.request
root = pathlib.Path(sys.argv[1])
api = "https://api.github.com/repos/mongodb-js/mongosh/releases/latest"
req = urllib.request.Request(api, headers={"Accept":"application/vnd.github+json","User-Agent":"qimono-vps-provisioner"})
with urllib.request.urlopen(req, timeout=30) as r:
    release = json.load(r)
assets = release.get("assets", [])
# Prefer the self-contained OpenSSL 11 Debian build; fall back to the
# regular Debian build if that is the only amd64 .deb published.
candidates = [a for a in assets if a.get("name", "").endswith("_amd64.deb")]
asset = next((a for a in candidates if "shared-openssl11" in a["name"]), None)
if asset is None:
    asset = next((a for a in candidates if "shared-openssl11" not in a["name"]), None)
if asset is None:
    raise SystemExit("No official mongosh amd64 Debian package found in latest release")
digest = asset.get("digest", "")
if not digest.startswith("sha256:"):
    raise SystemExit("GitHub release did not publish a SHA-256 digest for the mongosh package")
url = asset.get("browser_download_url")
if not url:
    raise SystemExit("mongosh release asset has no download URL")
req = urllib.request.Request(url, headers={"User-Agent":"qimono-vps-provisioner"})
with urllib.request.urlopen(req, timeout=120) as r:
    payload = r.read()
actual = hashlib.sha256(payload).hexdigest()
expected = digest.split(":", 1)[1]
if actual.lower() != expected.lower():
    raise SystemExit("mongosh SHA-256 mismatch; refusing installation")
if not payload.startswith(b"!<arch>\\n"):
    raise SystemExit("Official mongosh release asset is not a Debian package")
package = root / "mongosh.deb"
package.write_bytes(payload)
print(f"Verified {release.get('tag_name')} {asset['name']} (SHA-256 {actual})")
PY
apt-get install -y "$tmp/mongosh.deb"
mongosh --version
echo "MongoDB Atlas CLI and mongosh installed. No database server was installed."
