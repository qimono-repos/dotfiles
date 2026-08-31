# launchd — macOS's systemd (services), from a Linux-eye view

Yes, you can still "make units to launch services" — but it's launchd, not
systemd. Same job, different names and trigger model.

## The mental model shift: jobs, not units

| Idea | Linux (systemd) | macOS (launchd) |
|------|-----------------|-----------------|
| A thing that runs | **unit** / service file | **job** — a `.plist` |
| Where user jobs live | `~/.config/systemd/user/` | `~/Library/LaunchAgents/` |
| Where system jobs live | `/etc/systemd/system/` | `/Library/LaunchDaemons/` (root, no GUI) · `/Library/LaunchAgents/` (login) |
| Manifest format | `.service` (INI) | `.plist` (XML) |
| One-shot command | `systemctl start u.service` | `launchctl load/unload` or `launchctl bootstrap` |
| Enable at boot | `systemctl enable` | presence in the LaunchAgent/Daemon dir |
| Run on a schedule/timer | systemd timer | `StartInterval` / `StartCalendarInterval` keys |
| Run when path/file changes | `path` queuing | `WatchPaths` key |
| Keeps running / restart | `Restart=always` | `KeepAlive=true` |

## The big difference: trigger model

systemd is *event/state driven* with a bus; launchd is the **kernel
kickstarted** — it's actually macOS's *first* PID-1 and also boots the OS. Two
practical consequences:

1. **You don't usually "start" a job manually** — you drop the plist in the
   LaunchAgent/Daemon dir and (re)load it. Presence + a `launchctl` load is the
   "enable".
2. **`KeepAlive=true`** is your `Restart=always`; **`WatchPaths`** is your
   path-watching; **`StartCalendarInterval`** is your timer.

## Minimal recurring-job example (e.g. run `disk-audit.sh --top 5` daily)

`~/Library/LaunchAgents/com.qimono.diskaudit.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.qimono.diskaudit</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>-lc</string>
    <string>$HOME/dotfiles/darwin/scripts/disk-audit.sh --top 5 &gt;&gt; $HOME/.qimono/disk-audit.log</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
```

Then:

```bash
launchctl load ~/Library/LaunchAgents/com.qimono.diskaudit.plist   # v1 API
# or the modern way:
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.qimono.diskaudit.plist
launchctl print gui/$(id -u)/com.qimono.diskaudit   # inspect status
launchctl bootout gui/$(id -u)/com.qimono.diskaudit # remove
```

> Prefer `bootstrap`/`bootout`/`print` (modern, v3) over `load`/`unload` (legacy,
> officially deprecated but everywhere in tutorials).

## KeepAlive = restart-on-crash (your systemd `Restart=always`)

```xml
<key>KeepAlive</key><true/>
<key>ThrottleInterval</key><integer>10</integer>
```

## Key reference to remember

- `~/Library/LaunchAgents` — per-user, GUI session (commonest).
- `/Library/LaunchAgents` — global, GUI session.
- `/Library/LaunchDaemons` — system daemons as root, no GUI.
- `launchctl list | grep qimono` — see running user jobs.
- One script can export its own plist, mirroring how systemd units are declared.

## When to reach for Homebrew services instead

Homebrew adds a thin layer: `brew services start/stop/restart <formula>` writes
the plist for you for bottled formulae (postgres, redis, etc.). It's the lazy
path to the same launchd backend — good for bottled services, fine for the
darwin pack.