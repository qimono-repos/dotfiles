# dotfiles

Configuration files for macOS, Linux, and Windows.

![imge](./assets/monkey-dotfiles.jpeg)

## Linux machine packs

| Pack | Machine | Notes |
|------|---------|-------|
| [`ubuntu-len-yog-AMD64/`](./ubuntu-len-yog-AMD64/) | Lenovo Yoga 7 14AHP9 (Ryzen / x86_64) | Stow + Guix-first + Qiskit/PennyLane/Q# |
| `ubuntu/` | Generic Ubuntu / VPS | apt lists, nginx, server scripts |
| `gnu-guix/` | Guix recipes & channels | shared across Guix hosts |
| `fedora/` | Fedora host history | |

**Package manager ranking (Linux laptops):** 1 **guix** · 2 **apt** · 3 **snap** · 4 **podman** · 5 **nix**

Agent-facing host notes live in `$HOME/AGENTS.md` (not project-scoped).

## Continuity journal (P3–P5)

| File | Purpose |
|------|---------|
| [`JOURNAL-P3-P5.md`](./JOURNAL-P3-P5.md) | Pending work, session log, resume checklist |
| [`SD-CARD-README.md`](./SD-CARD-README.md) | Portable home on SD (mount → bootstrap → stow) |
| [`ubuntu-len-yog-AMD64/scripts/machine-discovery.sh`](./ubuntu-len-yog-AMD64/scripts/machine-discovery.sh) | Read-only host probe for new chassis / nomad |

**Guix install policy:** preferred `guix package -m …/profile-full.scm` (full list).  
Last resort: `ubuntu-len-yog-AMD64/scripts/installing-daily-use-apps.sh` (`guix install …`).  
**Warning:** a *partial* `-m` manifest **replaces** the profile and can wipe other apps.
