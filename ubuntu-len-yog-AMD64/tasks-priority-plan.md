# Tasks priority plan — AI compute / credit aware

Companion journal (pending + resume): **`../JOURNAL-P3-P5.md`**

## Priority bands

| Band | Examples |
|------|----------|
| **P0–P2** | Done earlier (structure, teach-ins, stow-source) |
| **P3** | quantum-host, jupyter, KDE Connect, editors docs |
| **P4** | Guix browsers, snap migration, podman autostart |
| **P5** | SD card tutorial + machine-discovery (no physical card required to author) |

---

## Status snapshot (2026-08-03)

| Band | State |
|------|--------|
| P0–P2 | complete |
| P3 | **mostly complete** (docs + rust + jupyter + kdeconnect) |
| P4 | **partial** — Guix epiphany OK; snap remove needs user sudo; chromium/firefox pending |
| P5 | **docs/scripts complete** — real SD experiment waits for hardware |

---

## P3 detail

| ID | Task | Status |
|----|------|--------|
| T22 | quantum-host .NET/Rust strategy + manifests | `[x]` |
| T23 | Codeium / VSCodium docs | `[x]` |
| T24 | KDE Connect doc + Guix install | `[x]` |
| T25 | JupyterLab via uv | `[x]` |
| T26 | diagrams/math docs | `[x]` |

## P4 detail

| ID | Task | Status |
|----|------|--------|
| T27 | Guix browsers | `[~]` epiphany done; chromium/firefox pending |
| T28 | Snap remove | `[ ]` run: `sudo snap remove epiphany` |
| T29 | Podman autostart | `[x]` |
| T30 | Nomad/SD live | `[ ]` needs physical card → P5 |

## P5 detail

| ID | Task | Status |
|----|------|--------|
| T31 | `SD-CARD-README.md` | `[x]` |
| T32 | `machine-discovery.sh` | `[x]` |
| T33 | Journal links | `[x]` |

---

## Next week checklist (copy into terminal)

```bash
# 1) Guix profile hygiene
source ~/.guix-profile/etc/profile
guix package -I

# 2) Snap: remove only GNOME Web snap (Guix epiphany installed)
sudo snap remove epiphany

# 3) Optional heavy browser
guix install ungoogled-chromium   # not: guix package -m slim-file

# 4) Firefox research after pull
guix pull
guix search firefox | head

# 5) When SD card arrives
cd ~/source/repos/qimono-repos/dotfiles
less SD-CARD-README.md
./ubuntu-len-yog-AMD64/scripts/machine-discovery.sh | tee /tmp/discovery-$(hostname).txt
```

---

## Session log

| When | Notes |
|------|-------|
| 2026-08-03 | P3+P4+P5 chunks; profile wipe lesson; journal at repo root |
