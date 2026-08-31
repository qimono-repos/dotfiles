#!/usr/bin/env bash
# disk-audit.sh — READ-ONLY report of the disk-space suspects on a macOS host,
# framed for the Qimono Apple Container + Guix stack. It only MEASURES, never
# deletes; it prints `brew cleanup` / `container system prune` / manual `rm`
# suggestions you can apply yourself.
# Usage: ./scripts/disk-audit.sh [--top N]   (default --top 20 largest offenders)
set -uo pipefail

TOP=20
for arg in "$@"; do
  case "$arg" in
    --top=*) TOP="${arg#--top=}" ;;
    -h|--help) echo "usage: $0 [--top N]   (read-only; prints reclaim suggestions)"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

hr() { printf '\n%-60s\n' "──── $* ────"; }
size_h() { du -sh "$1" 2>/dev/null | cut -f1; }

echo "=== disk-audit — $(hostname)  ($(date '+%Y-%m-%d %H:%M')) ==="
df -h / | tail -1

hr "1. KEEP-FIRST: what the container+Guix stack needs"
printf '  %-34s %s\n' "Xcode CLT (xcode-select -p)" "$(xcode-select -p 2>/dev/null || echo 'missing')"
if /usr/bin/pgrep -q oahd 2>/dev/null; then echo "  Rosetta (oahd): RUNNING — needed to BUILD images"; fi
for p in brew container podman guix; do
  if command -v "$p" >/dev/null 2>&1; then d="$(size_h "$(command -v "$p")")"; echo "  $p: on PATH (binary ${d})"; fi
done

hr "2. Homebrew — safest reclaim (brew cleanup)"
brew cleanup --dry-run 2>/dev/null | sed 's/^/  [audit] /' || echo "  (no brew on PATH yet)"
echo "  command to apply:  brew cleanup"

hr "3. Apple Container — stale kernels/images/system"
if command -v container >/dev/null 2>&1; then
  echo "  container system: $(container system status 2>/dev/null | head -1 || true)"
  echo "  command to apply:  container system prune   # removes unused images/kernels"
else
  echo "  (container CLI not installed)"
fi

hr "4. Big directory suspects (KEEP-check these; re-add on demand)"
# Order by size. Each is safe to re-fetch/rebuild, so they are reclaim candidates.
for dir in \
  "$HOME/Library/Developer" \
  "$HOME/Library/Developer/CoreSimulator" \
  "$HOME/Library/Caches" \
  "$HOME/Library/Developer/Xcode" \
  "$HOME/Library/Application Support/iPhone Simulator" \
  "$HOME/Library/Developer/Shared" \
  "$HOME/.cache" \
  "$HOME/.npm" \
  "$HOME/.bun/install/cache" \
  "$HOME/Library/Caches/pip" \
  "$HOME/Library/Caches/uv" \
  "$HOME/go/pkg/mod" \
  "$HOME/Documents" \
  "$HOME/Downloads" \
  "$HOME/Pictures/Screenshots"; do
  [[ -e "$dir" ]] && printf '  %-50s %s\n' "$dir" "$(size_h "$dir")"
done

hr "5. Top ${TOP} files/dirs under HOME by size (largest reclaim candidates)"
du -ahx "$HOME" 2>/dev/null | sort -rh | head -n "$TOP" | \
  awk '{ printf "  %-8s %s\n", $1, $2 }'

hr "6. Xcode / Simulator runtimes (expensive to reinstall — KEEP-list decision)"
# Xcode full app
if [[ -d /Applications/Xcode.app ]]; then
  echo "  /Applications/Xcode.app: $(size_h /Applications/Xcode.app)"
  echo "  -> KEEP this only if you build Swift/iOS apps; else 'xcode-select --install' keeps the CLT."
else
  echo "  /Applications/Xcode.app: not installed (CLT only — good)."
fi
echo "  SIMULATOR runtimes live under ~/Library/Developer/CoreSimulator — see section 4."
echo "  To strip a specific runtime (re-addable):"
echo "    xcrun simctl runtime delete \"iOS xx.x\""
echo "    xcrun simctl runtime list"

hr "7. Suggested apply order (you run these, NOT this script)"
cat <<'EOF'
  1. brew cleanup                      # tap logs + old versions
  2. container system prune            # unused Apple-Container kernels/images
  3. rm -rf ~/Library/Developer/CoreSimulator/Caches/*   # sim caches
  4. Delete stale iOS/Watch/older simulator runtimes:
       xcrun simctl runtime list && xcrun simctl runtime delete "<unused>"
  5. ~/.cache/pip, ~/.cache/uv (uv re-fetches), ~/.npm
  6. If keeping Xcode only for CLT: rm -rf /Applications/Xcode.app (~10+ GiB)
  7. Re-run:  df -h /   → target ≳30 GiB free for container+Guix
EOF

hr "Done — audit only, nothing deleted."