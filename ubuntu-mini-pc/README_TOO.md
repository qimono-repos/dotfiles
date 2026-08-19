# README_TOO.md — The Emergency Reboot Procedure

> **Fatal priority.** `too` is not a convenience — it is the machine's last resort.

To activate this mode run this command: `sudo ./scripts/install-passwordless-power.sh`

## Why This Exists

Alan Turing proved that you cannot always determine whether a program will halt.
This is the halting problem, and it has a practical consequence:

**You cannot know when your machine is truly stuck.**

When the display is frozen, input is broken, a process is in an uninterruptible
state (`D` state), or the system is otherwise unresponsive — you need a way to
force-reboot **immediately**, with no barriers, no questions, no authentication.

`too` exists for that moment.

## What `too` Does

```zsh
too       # force reboot now, ignore GNOME inhibitor locks, no sudo prompt
powerofff # force poweroff now, same guarantees
```

These are **opinionated procedures**, not generic wrappers. They:

- Use `systemctl reboot -i` / `systemctl poweroff -i` (ignore inhibitor locks)
- Require **no password** (sudoers drop-in from `install-passwordless-power.sh`)
- Work from any state where the shell can still execute a function
- Accept that current work **will be lost** — that is the price of the escape hatch

## When to Use `too`

| Scenario | Why `too` is correct |
|----------|---------------------|
| Display frozen, mouse dead | Input subsystem may be hung; no way to interact with desktop shutdown |
| Process in `D` state (uninterruptible sleep) | Kernel-level block; `kill -9` won't work; only reboot clears it |
| GNOME/Wayland compositor crashed | Desktop environment unresponsive; no GUI shutdown available |
| System under extreme OOM thrashing | So slow that interactive shutdown times out before completing |
| Disk I/O hung (NVMe timeout) | Filesystem unresponsive; `powerofff` may also hang — try `too` first |
| runaway process eating all CPU/RAM | System barely responsive; need fast recovery, not graceful shutdown |
| After a failed kernel module load | System may be unstable; reboot is the only safe path |
| You just need the machine off **now** | No justification needed. That is what `too` is for. |

## What You Lose

When you run `too`:

- **Unsaved work is gone.** Every buffer, every unsaved file, every in-flight operation.
- **Open terminals are killed.** No chance to save scrollback or copy output.
- **Running services stop uncleanly.** Database transactions may need recovery on next boot.
- **This is inevitable.** That is the point. The alternative is a machine you cannot recover.

The halting problem tells us: there is no algorithm that can always decide
whether a running program will finish. When the answer is "it won't,"
`too` is the only answer that always works.

## Proposal: `too --info` (Diagnostic Before Destruction)

Before invoking the nuclear option, `too --info` reports what is stuck,
writes it to disk, and then reboots:

```zsh
too --info
```

### What it does

1. **Echoes diagnostics to the terminal** — so the user can see the state
   at the very last moment before the inevitable reboot.
2. **Writes `/home/halt-info.txt`** — a persistent record on disk for
   post-mortem analysis after reboot. Best-effort: if the write fails,
   `too` still reboots. The escape hatch always moves forward.
3. **Reboots.** No confirmation. The info is for the record, not for
   decision-making — the decision is already made.

### Terminal output

```
=== System State ===
Uptime: 3d 14:22:07
Load average: 12.4, 11.8, 10.2 (high — system is struggling)

=== Uninterruptible Processes (D state — cannot be killed) ===
  PID  USER    COMMAND
  4411 root    /usr/local/bin/ollama serve
  8832 qi      python3 train_model.py

=== Zombie Processes (Z state — defunct, need parent cleanup) ===
  PID  PPID  COMMAND
  9001  8832  [python3] <defunct>

=== Memory Pressure ===
  Total: 14.5 GiB | Used: 14.2 GiB | Available: 0.3 GiB
  Swap:  4.0 GiB  | Used:  3.8 GiB

=== Saved to /home/halt-info.txt ===
Rebooting...
```

### halt-info.txt (on disk)

The same information is written to `/home/halt-info.txt` so it survives
the reboot. After the machine comes back:

```bash
cat /home/halt-info.txt          # see what was stuck
journalctl -b -1 -p err          # kernel logs from the previous boot
```

If the filesystem is too hung to write, the write silently fails and
`too` reboots anyway. **The machine always moves forward.**

## Proposal: SSH broadcast

When SSH server is configured, `too --info` could broadcast the halt-info
to a known remote host before rebooting:

```zsh
# Future proposal — not yet implemented
ssh backup-host "cat >> /home/qi/halt-logs/$(hostname)-$(date +%s).txt" < /home/halt-info.txt
```

This requires:
- OpenSSH server enabled on this machine
- Key-based auth to a backup host
- The backup host must be reachable at the time of halt

Until then, `/home/halt-info.txt` is the local record.

## Proposal: Git emergency-save

By convention, all git repos live in `~/source/repos/qimono-repos/`.
Before rebooting, `too` could scan for uncommitted work and attempt to
preserve it — best-effort, never blocking the reboot.

**How it works:**

1. Walk every subdirectory under `~/source/repos/qimono-repos/`
2. Run `git status --porcelain` — if clean, skip
3. If dirty, create branch `emergency-reboot-branch-yyyy-mm-dd-hh-MM`
   - **No seconds** — intentional. Keeps branches minimally human-controllable,
     prevents pollution of bot-made error-reset branches
4. Stage all changes (`git add -A`), commit with message:
   `emergency: uncommitted work before forced reboot`
5. Attempt `git push origin <branch>` — if network is available
6. If push fails (no network, no remote, auth broken), log the failure
   and **continue the reboot anyway**

**This is a nice to have, not a requirement.** The reboot always proceeds.
The git save is a last attempt to send uncommitted work to origin — if it
works, great; if not, the work was already considered lost by the nature
of `too`.

```zsh
# Future proposal — not yet implemented
REPOS_DIR="$HOME/source/repos/qimono-repos"
BRANCH="emergency-reboot-branch-$(date +%Y-%m-%d-%H-%M)"

for repo in "$REPOS_DIR"/*/; do
  [[ -d "$repo/.git" ]] || continue
  cd "$repo" || continue

  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "Dirty: $(basename "$repo")"
    git checkout -b "$BRANCH" 2>/dev/null || continue
    git add -A 2>/dev/null
    git commit -m "emergency: uncommitted work before forced reboot" 2>/dev/null || continue
    git push origin "$BRANCH" 2>/dev/null && \
      echo "Pushed: $(basename "$repo")" || \
      echo "Push failed: $(basename "$repo") (network or auth issue)"
  fi
done
```

### Implementation sketch

```zsh
too() {
  if [[ "${1:-}" == "--info" ]]; then
    INFO=""
    INFO+="=== System State ==="$'\n'
    INFO+="$(uptime)"$'\n'$'\n'
    INFO+="=== Uninterruptible Processes (D state) ==="$'\n'
    INFO+="$(ps -eo pid,user,stat,wchan,comm | awk '$3 ~ /D/ {print}')"$'\n'$'\n'
    INFO+="=== Zombie Processes (Z state) ==="$'\n'
    INFO+="$(ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/ {print}')"$'\n'$'\n'
    INFO+="=== Memory ==="$'\n'
    INFO+="$(free -h)"$'\n'$'\n'
    INFO+="=== Timestamp ==="$'\n'
    INFO+="$(date -Iseconds)"$'\n'

    echo "$INFO"
    echo ""

    # Best-effort write — if it fails, we still reboot
    echo "$INFO" > /home/halt-info.txt 2>/dev/null && \
      echo "Saved to /home/halt-info.txt" || \
      echo "Could not write halt-info.txt (filesystem may be hung)"

    echo "Rebooting..."
  fi
  sudo /usr/bin/systemctl reboot -i
}
```

## Design Decisions (Opinionated)

1. **No confirmation prompt.** `too` does not ask "are you sure?" If you typed it, you meant it.
2. **No graceful shutdown.** `systemctl reboot -i` skips inhibitor locks and waits for services.
3. **No password.** The sudoers drop-in ensures this works even when you cannot authenticate.
4. **Function, not alias.** Aliases cannot call `sudo` internally; the user would need to type `sudo too`, which defeats the purpose.
5. **Name is deliberate.** "too" is short, mnemonic ("turn it off and on again"), and impossible to confuse with system commands.

## For Agents (AI and Human)

When operating on this machine:

- **Never disable `too`.** Do not remove the sudoers drop-in. Do not alias it to something safer.
- **Never add a confirmation.** The whole point is zero-friction escape.
- **If `too` fails**, the machine needs physical power cycle. That is the true last resort.
- **Document why you used `too`** if possible (in system logs, or verbally to the operator).
- **After reboot**, check `journalctl -b -1 -p err` for what went wrong in the previous boot.

---

*The halting problem is undecidable. `too` is the answer to undecidability.*
