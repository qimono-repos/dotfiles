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
# MongoDB publishes a machine-readable catalogue with URL and SHA-256.
python3 - "$tmp" <<'PY'
import hashlib, json, pathlib, sys, urllib.request
root = pathlib.Path(sys.argv[1])
url = "https://downloads.mongodb.com/compass/mongosh.json"
req = urllib.request.Request(url, headers={"User-Agent":"qimono-vps-provisioner"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.load(r)
versions = data.get("versions", [])
if not versions:
    raise SystemExit("MongoDB mongosh catalogue has no versions")
downloads = versions[0].get("downloads", [])
entry = next((d for d in downloads if d.get("arch") == "x86_64" and d.get("distro") == "deb"), None)
if not entry:
    raise SystemExit("No x86_64 Debian package found in MongoDB mongosh catalogue")
archive = entry.get("archive", {})
package_url = archive.get("url")
expected = archive.get("sha256")
if not package_url or not expected:
    raise SystemExit("MongoDB mongosh catalogue entry lacks URL or SHA-256")
req = urllib.request.Request(package_url, headers={"User-Agent":"qimono-vps-provisioner"})
with urllib.request.urlopen(req, timeout=90) as r:
    payload = r.read()
actual = hashlib.sha256(payload).hexdigest()
if actual.lower() != expected.lower():
    raise SystemExit("mongosh SHA-256 mismatch; refusing installation")
if not payload.startswith(b"!<arch>\\n"):
    raise SystemExit("MongoDB mongosh download was not a Debian package")
(root/"mongosh.deb").write_bytes(payload)
print(f"Verified mongosh package ({actual}): {package_url}")
PY
apt-get install -y "$tmp/mongosh.deb"
mongosh --version
echo "MongoDB Atlas CLI and mongosh installed. No database server was installed."
