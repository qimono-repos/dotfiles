# Skill: GNOME login autostart (fleet pattern)

> Origin: ubuntu-hp-pro, ported to ubuntu-len-yog-AMD64 (2026-08-21).
> Goal: chosen apps come up on every session start — guarded, logged,
> first-run correct.

## When to use this skill

Making GUI apps launch automatically at GNOME login on any machine pack in
this repo.

## The fleet pattern (one entry point)

```
stow-source/shell/.config/autostart/60-startup.desktop   # stowed → ~/.config/autostart/
        └─ Exec=<ABSOLUTE path>/scripts/startup-login.sh  # machine-pack script
                ├─ app 1 (guard + capped log)
                ├─ sleep 3
                ├─ app 2 …
                └─ wait
```

One `.desktop` per machine, one script it calls. Never put app commands in
the desktop file itself.

## The laws

1. **Exec must be an absolute path** into the machine pack; autostart env is
   minimal and PATH-unreliable.
2. **Guard every launch.** Host apps: `pgrep -x <name>`. Flatpak apps: ask
   the scope table (`systemctl --user list-units "app-flatpak-${id}-*"
   --no-legend --state=active`) — host pgrep cannot see sandboxed argv.
3. **Guix binaries need the profile sourced** inside the launching subshell:
   `( set +u; source "$HOME/.guix-profile/etc/profile"; exec <app> ) &`
   Autostart env carries no Guix PATH/LD vars (hp-pro lesson: otherwise a
   snap stub may win resolution).
4. **Flatpak launches**: absolute client path
   `$HOME/.guix-profile/bin/flatpak --user run <app-id>` plus
   `export FLATPAK_BWRAP=/usr/bin/bwrap` for belt-and-braces.
5. **Cap every log**: `tail -n 1000 "$LOG" > "$LOG.tmp" && mv` before
   appending; long-running stdout goes through the cap or a shim that caps
   (see alpaca shim). Logs live in `/tmp/<app>-log.txt`.
6. **Stagger launches** (`sleep 3`) so apps don't fight over login I/O.
7. **End the script with `wait`** to keep children attached under
   gnome-session.
8. **Validate before stowing**: `desktop-file-validate <entry>.desktop`,
   then `./scripts/stow-apply.sh`.

## QA discipline

- Manual test MUST simulate the session env:
  `export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 DISPLAY=:0`
  A harness without display env kills X/Wayland apps after their first log
  line — looks like a script bug, isn't (cost us one round).
- Launch test runs via `setsid nohup ./scripts/startup-login.sh … </dev/null & disown`
  from tool sessions: a timeout SIGKILL would otherwise reap the children
  mid-test and fake a failure.
- Verify with the guards ON: second run must print `… already running — skip`.
- Real victory = next reboot/login fires the desktop entry by itself
  (R1-style: agent proves mechanics, human confirms the real trigger).

## Gotchas found

| Trap | Detail |
|---|---|
| Guix firefox process name | wrapper execs `.firefox-real`; guard BOTH names |
| Missing display env in tests | silent death after first line (canberra msg only) |
| Tool-session timeouts | SIGKILL process group → use setsid for detached tests |
| Scope-table checks | flatpak argv invisible to host pgrep; trust systemd units |

## Reference implementations

- `ubuntu-len-yog-AMD64/scripts/startup-login.sh` (ghostty + firefox + alpaca)
- `ubuntu-hp-pro/scripts/startup-login.sh` (firefox + ptyxis + vscodium)
