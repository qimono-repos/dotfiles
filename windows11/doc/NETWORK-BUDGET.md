# Network Budget Tracking on the Qimono Machines

The Windows11 machine pack ships a small PS1 monitor that enforces a hard cap on
**received** bytes so bandwidth-sensitive sessions (metered SIM, ISP daily quota,
etc.) can be audited and can hard-stop before exceeding a limit.

## Why

Qimono runs install sessions under a finite daily bandwidth budget. Packages,
toolchains, and source-builds nibble at it; the goal is to *always be able to
answer* "how much have we received since the session tracked started?" — without
the monitor itself lying.

## The script

```
dotfiles/windows11/scripts/check-network-budget.ps1
```

### How it works

1. On first run it records each live adapter's OS cumulative `ReceivedBytes`
   counter into `%USERPROFILE%\.qimono\network-budget.json` as `lastSeen`.
2. On every later run it computes, **per adapter**, `add = max(0, now - lastSeen)`
   and adds that to a **monotonic** `accumulatedBytes` total, then updates `lastSeen`.
3. A counter that went backwards (reboot, sleep/resume, adapter disconnect) adds
   `0` for that cycle and is re-anchored — **usage already counted is never lost**.
4. Exit code is `1` once `consumed >= budget`, which lets build scripts chain a
   hard stop. Pretty status line is colored (green → yellow ≥ 80 % → red == cap).

### State file

| Field | Meaning |
|---|---|
| `startedAt` | ISO-8601 when tracking first anchored |
| `budgetBytes` | budget in effect (default `1073741824` = 1 GiB) |
| `accumulatedBytes` | monotonic received-since-start (the number that matters) |
| `lastSeen` | per-adapter last counter value |
| `runs` / `runsReset` | invocation + reset counters (diagnostics) |

### Usage

```powershell
# Init or report (default 1 GiB budget)
pwsh .\dotfiles\windows11\scripts\check-network-budget.ps1

# Different budget
pwsh .\dotfiles\windows11\scripts\check-network-budget.ps1 -BudgetBytes 536870912

# Wipe tracking and start over
pwsh .\dotfiles\windows11\scripts\check-network-budget.ps1 -Reset
```

### Build-script pattern

```powershell
& <pack>\scripts\check-network-budget.ps1   # exit 1 if cap reached -> abort
if ($LASTEXITCODE -ne 0) { exit 1 }
& winget install ...                        # then re-check after
& <pack>\scripts\check-network-budget.ps1
```

## Historical bug fixed (2026-09-16)

The v1 script snapshotted a single `baseline` and re-anchored it on reset —
which **zeroed the running total** the moment a counter reset. Mid-session the
Wi-Fi counter reset and the monitor started reporting `0.0 MB / 1024 MB` while we
were, in fact, ~307 MB into the budget. v2 (above) stores `accumulatedBytes`
separately from `lastSeen`, so this cannot recur. If a stored state predates this
fix, run `-Reset` and re-anchor deliberately.

## Caveats

- Windows `Get-NetAdapterStatistics` is per-session OS telemetry; counters reset on
  reboot (handled by design above). **Expected daily drift:** a reboot mid-track
  loses the deltas that happened while counters were zeroed (that window is
  unmeasurable), but nothing *previously* measured is dropped.
- Adapter names (Wi-Fi, Ethernet 2, …) may shuffle; the monitor keys on current
  names and re-bases unknown adapters on arrival with zero contribution.
- This tracks this machine's NIC counters only — not router-level or ISP-measured
  usage. Treat it as an *approximation with a hard-stop enabler*, not as billing.