# Confidence model — HP ProBook bootstrap

## Target outcome

End of one sitting:

1. GNU Guix installed and `guix pull` done (nonguix channel).  
2. Host: unprivileged userns allowed (Epiphany/WebKit) **with drop-in under `/etc/sysctl.d/`**.  
3. Nonguix substitute key authorized (vendored key preferred).  
4. Guix packages **`epiphany`** + **`firefox`** installed from **substitutes**.  
5. Shell can find post-pull `guix` and profile bins.  
6. Snap Firefox / Epiphany removed (if they were present).  
7. **GUI smoke + reboot QA:** both browsers open a page; Epiphany **after reboot** (see `QA/`).

## Confidence band (2026-08-03)

| Scenario | Confidence | Why |
|----------|------------|-----|
| ProBook **x86_64**, Ubuntu 24.04/26.04-ish, **you + sudo**, network, **≥40 G free**, hardened `bootstrap.sh` + **QA/** Human+AI checklists | **~97–99%** | Yoga-proven path; AppArmor drop-in; weather/disk/wrong-guix gates; reboot QA |
| Same but skip preflight / ignore source-build watch | **~90–93%** | Human error returns |
| Arm64 / offline / no sudo / tiny disk | **Low** | Out of scope |

**Not 100%:** multi-hour substitute/pull outage, hardware failure, forcing a Firefox source build.

### How we moved ~93% → ~97–99%

| Mitigation | Where |
|------------|--------|
| AppArmor userns drop-in (survives reboot) | `install-host-sysctl.sh` + step 3 |
| Vendored nonguix signing key | `keys/nonguix-signing-key.pub` |
| Hard fail if not post-pull guix | steps 2 + 4 |
| Hard fail if &lt;40 G free | step 4 |
| `guix weather firefox` abort on 0% | step 4 |
| Resume map + GUI smoke + reboot | `bootstrap.sh`, `QA/Day1-browsers.md`, `QA/Checklist-User.md` R1/R2 |

## Failure modes (and mitigations)

| Failure | Likelihood | Mitigation |
|---------|------------|------------|
| `guix` still `/usr/local/bin` without nonguix | Low–medium | Hard fail after pull + install if not `…/current/bin/guix` |
| Firefox source build / disk full | Low if gates honored | Weather + 40 G gate; Ctrl+C culture in QA |
| Epiphany bwrap trap | Low if step 3 runs | Drop-in + verify value `0` |
| Guix install interactive | Medium | `YES_TO_ALL=1`; you present with sudo |
| Snap remove needs sudo | Low | Step 6; `--skip-snap` until GUI OK |
| Network / substitute 0% | Low–medium | Weather abort; retry later; hotspot |

## What we do **not** claim for session 1

- Quantum stack (Qiskit/PennyLane/Q#)  
- .NET 10 / Rust full toolchain  
- LazyVim / full stow of every app  
- Bit-identical profile to the Yoga  
- Private Qimono substitute server (explored; not required for day 1)

Those are session 2+ using the Yoga pack as reference.
