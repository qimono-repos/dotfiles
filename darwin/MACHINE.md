# MACHINE.md — the 2026 Apple Silicon fleet (`darwin`)

Snapshot placeholders. Fill from `scripts/machine-discovery.sh` output on
**both** machines after acquisition (2026-09-01). Refresh after major changes.

> This pack is **herd-wide**: one pack, two machines (MacBook Air + Mac mini).
> Keep the table below populated per host so troubleshooting knows which box.

## Fleet facts (decided 2026-08-31, pre-acquisition)

| Item | Value |
|------|-------|
| Role | both **general laptops** (imaging/compute), NOT servers |
| Setup cadence | both in parallel |
| Guarantee | Apple Container requires **macOS 26 "Tahoe"** (not Sequoia/GoldenGate) |
| CPU | Apple Silicon (presumed M3 both) — arm64 |
| Shell | zsh + oh-my-posh (catppuccin) + tmux, same as Linux boxes |
| Dev Linux env | `container machine qi-dev` — Debian + systemd, `$HOME` mirrored |
| Guix | foreign-distro mode inside the machine |

## Host 1 — MacBook Air

| Item | Detail |
|------|--------|
| **Captured** | (run `./scripts/machine-discovery.sh`) |
| hw.model | `MacBookAir?` (fill `sysctl -n hw.model`) |
| Chip | Apple M3 (?) |
| RAM / Storage | ? GiB / ? TB |
| Hostname | (fill) |
| macOS | (fill `sw_vers -productVersion`, must be ≥ 26) |
| brew / container / podman | (fill versions) |

## Host 2 — Mac mini

| Item | Detail |
|------|--------|
| **Captured** | (run `./scripts/machine-discovery.sh`) |
| hw.model | `Macmini?` (fill `sysctl -n hw.model`) |
| Chip | Apple M3 (?) |
| RAM / Storage | ? GiB / ? TB |
| Hostname | (fill) |
| macOS | (fill `sw_vers -productVersion`, must be ≥ 26) |
| brew / container / podman | (fill versions) |

## Container machines

| Machine | Base image | Purpose | Notes |
|---------|-----------|---------|-------|
| `qi-dev` | `qimono/debian-qi` (Debian + systemd) | the persistent dev env; Guix lives here | `$HOME` mirrored; don't migrate state — recreate |

## Refresh commands

```bash
sw_vers
sysctl -n hw.model machdep.cpu.brand_string
system_profiler SPHardwareDataType | head -25
brew --version
container --version
podman --version
container machine list
```