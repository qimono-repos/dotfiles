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
# MongoDB's official download catalogue supplies the current Debian/Ubuntu x64 .deb.
python3 - "$tmp" <<'PY'
import json, pathlib, sys, urllib.request
root = pathlib.Path(sys.argv[1])
url = "https://downloads.mongodb.com/compass/mongosh.json"
req = urllib.request.Request(url, headers={"User-Agent":"qimono-vps-provisioner"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.load(r)
found = []
def walk(x):
    if isinstance(x, dict):
        for v in x.values():
            if isinstance(v, str) and v.startswith("https://") and "mongosh" in v.lower() and ".deb" in v.lower():
                found.append(v)
            else:
                walk(v)
    elif isinstance(x, list):
        for v in x:
            walk(v)
walk(data)
urls = list(dict.fromkeys(found))
url = next((u for u in urls if ("x64" in u.lower() or "amd64" in u.lower() or "x86_64" in u.lower()) and ".deb" in u.lower()), None)
if not url:
    raise SystemExit("Could not identify official mongosh Debian x64 package in MongoDB's download catalogue")
req = urllib.request.Request(url, headers={"User-Agent":"qimono-vps-provisioner"})
with urllib.request.urlopen(req, timeout=60) as r:
    payload = r.read()
if not payload.startswith(b"!<arch>\n"):
    raise SystemExit("MongoDB mongosh download was not a Debian package")
(root/"mongosh.deb").write_bytes(payload)
print("Downloaded official mongosh package:", url)
PY
apt-get install -y "$tmp/mongosh.deb"
mongosh --version
echo "MongoDB Atlas CLI and mongosh installed. No database server was installed."
