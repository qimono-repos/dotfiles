# ubuntu-mini-pc

**Status:** scaffold only (feedback 2026-08).

Planned machine pack for the **AMD mini PC** that currently still shares some stow history with the archive tree `dotfiles/ubuntu/`.

## Intent

- Same **Ying-Yang Project 2026/2027** as `ubuntu-len-yog-AMD64`
- Rewrite stow using lessons from the Yoga pack (`stow-source/`, Guix manifests, smoke tests)
- Arch expected: **x86_64** (confirm on box before assuming substitutes)

## Do not

- Treat `dotfiles/ubuntu/` as this machine’s live product pack — it is a recopilation of many VPS/old hosts plus mini-PC residue.

## Next (when prioritized)

1. Capture `MACHINE.md` from the mini PC (`hostnamectl`, `lscpu`, disk).  
2. Copy structure from `ubuntu-len-yog-AMD64/` (not blind copy of paths).  
3. Share `guix/channels.scm` policy; per-machine manifests where needed.  
4. **Day-zero host sysctl:** copy `host-sysctl/99-guix-userns.conf` + `scripts/install-host-sysctl.sh` from Yoga/HP packs — Ubuntu AppArmor vs Guix `bwrap` (Epiphany) will bite otherwise.
