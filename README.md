# dotfiles

Configuration files for macOS, Linux, and Windows.

![imge](./assets/monkey-dotfiles.jpeg)

## Linux machine packs

| Pack | Machine | Notes |
|------|---------|-------|
| [`ubuntu-len-yog-AMD64/`](./ubuntu-len-yog-AMD64/) | Lenovo Yoga 7 14AHP9 (Ryzen / x86_64) | Stow + Guix-first + Qiskit/PennyLane/Q# · [**QA/**](./ubuntu-len-yog-AMD64/QA/) |
| [`ubuntu-hp-pro/`](./ubuntu-hp-pro/) | HP ProBook (Intel x86_64) | bootstrap Guix + Epiphany + Firefox · [**QA/**](./ubuntu-hp-pro/QA/) |
| [`ubuntu-mini-pc/`](./ubuntu-mini-pc/) | `qi-mini-pc-ubu-rr` (Ryzen 7 7730U) | quantum workstation: Guix python/uv/jupyter + 127.0.0.1:5005 · [**QA/**](./ubuntu-mini-pc/QA/) |
| `ubuntu/` | Generic Ubuntu / VPS | apt lists, nginx, server scripts (archive; not this mini-PC’s live pack) |
| `gnu-guix/` | Guix recipes & channels | shared across Guix hosts |
| `fedora/` | Fedora host history | |

**Package manager ranking (Linux laptops):** 1 **guix** · 2 **apt** · 3 **snap** · 4 **podman** · 5 **nix**

**QA is use-case scoped** (not a repo-root folder): each machine pack has its own `QA/` with **Human + AI** checklists (`- [ ]` / `- [x]`, or print + pen). Born from AppArmor/reboot lessons — Qimono celebrates error → process.

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
