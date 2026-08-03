# Confidence model — HP ProBook bootstrap

## Target outcome

End of one sitting:

1. GNU Guix installed and `guix pull` done (nonguix channel).  
2. Host: unprivileged userns allowed (Epiphany/WebKit).  
3. Nonguix substitute key authorized.  
4. Guix packages **`epiphany`** + **`firefox`** installed from **substitutes**.  
5. Shell can find post-pull `guix` and profile bins.  
6. Snap Firefox / Epiphany removed (if they were present).

## Why ~85–90% on a similar ProBook

| Factor | Yoga (proven) | ProBook (expected) |
|--------|---------------|--------------------|
| Arch | x86_64 | Intel x86_64 → **same substitutes** |
| RAM | 6.5 GiB tight | “Plenty” → safer pull/install |
| Disk | 153 G dual-boot, ENOSPC once | “Plenty” → less ENOSPC risk |
| Guix browsers path | Documented + fixed | Encoded in `bootstrap.sh` |
| Fresh machine | N/A | Installer scripted from zero Guix |

## Failure modes (and mitigations)

| Failure | Likelihood | Mitigation in bootstrap |
|---------|------------|-------------------------|
| `guix` still `/usr/local/bin` without nonguix | Medium | Force `PATH=…/current/bin`; fail if `guix show firefox` fails |
| Firefox source build / disk full | Medium on small disks | Use nonguix substitutes only; abort if `source` drv without substitute |
| Epiphany bwrap trap | High without sysctl **drop-in** | `./scripts/install-host-sysctl.sh` early; `sysctl -w` alone dies on reboot |
| Guix install script interactive | Medium | `YES_TO_ALL=1` where supported; document password |
| Snap remove needs sudo | Low | Explicit step; continue if snap missing |
| Network / substitute 403 | Low–medium | Retry URLs; print authorize key step |

## What we do **not** claim for session 1

- Quantum stack (Qiskit/PennyLane/Q#)  
- .NET 10 / Rust full toolchain  
- LazyVim / full stow of every app  
- Bit-identical profile to the Yoga  

Those are session 2+ using the Yoga pack as reference.
