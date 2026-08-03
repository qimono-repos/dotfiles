# ubuntu-hp-pro

Machine pack for a **Linux HP ProBook** (Intel, x86_64 expected) in the Qimono / Ying-Yang fleet.

**Sibling lessons:** `ubuntu-len-yog-AMD64` (Yoga Ryzen) — browser path proven there.  
**This pack’s job #1:** bare Ubuntu → **Guix + Epiphany (GNOME Web) + Firefox** in one session.

## Confidence (Firefox + Epiphany via Guix)

| Scenario | Confidence | Why |
|----------|------------|-----|
| HP ProBook, **x86_64**, Ubuntu 24.04/26.04-ish, **sudo**, working network, **≥40 G free**, plenty RAM | **~85–90%** first session | Same arch as Yoga → nonguix Firefox **substitutes**; more RAM/disk than Yoga; pipeline encoded in `bootstrap.sh` |
| Arm64 / weird Ubuntu spin / offline / no sudo | **Low** | Different story |
| “Also full quantum + .NET + uv in same session” | **~50%** | Out of scope of this bootstrap (hooks only) |

**Residual ~10–15% risk:** `guix pull` / substitute server hiccups, AppArmor edge cases, first Guix installer prompts, corporate proxy, very full disk.

**Not magic if:** you skip sudo steps, use old `/usr/local/bin/guix` without pull, or build Firefox from source offline.

## Day-one ritual (what you described)

```bash
# 0) Get this repo onto the ProBook (usb / git clone / scp)
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro   # or wherever you put it

# 1) Optional: remove snap browsers first (script can do this too)
# sudo snap remove firefox
# sudo snap remove epiphany   # if present as "epiphany" or gnome-web packaging

# 2) The magic
./scripts/bootstrap.sh
```

Sit near the machine: **sudo password** a few times; **guix pull** can take a while.

When it finishes:

```bash
source ~/.guix-profile/etc/profile
epiphany &
firefox &
```

## Layout

```
ubuntu-hp-pro/
  README.md                 # this file
  CONFIDENCE.md             # risk notes
  docs/LESSONS.md           # pointer to Yoga browser lessons
  guix/channels.scm         # nonguix + default
  host-sysctl/99-guix-userns.conf   # → /etc/sysctl.d/ (must install; survives reboot)
  scripts/bootstrap.sh      # main entry
  scripts/install-host-sysctl.sh    # AppArmor userns=0 only (sudo)
  scripts/00-host-apt-min.sh
  scripts/10-install-guix.sh
  scripts/20-guix-pull-channels.sh
  scripts/30-browser-prereqs.sh     # userns + nonguix key
  scripts/40-install-browsers.sh
  scripts/50-shell-path.sh
  scripts/60-remove-snap-browsers.sh
  stow-source/shell/        # optional PATH snippets (manual or stow if stow exists)
```

### Host must-have (Epiphany)

Without the sysctl drop-in, Guix Epiphany dies after reboot:

`bwrap: setting up uid map: Permission denied`

```bash
./scripts/install-host-sysctl.sh
sysctl kernel.apparmor_restrict_unprivileged_userns   # 0
```

## After browsers work (later sessions)

- Guix python/uv: see Yoga pack manifests  
- .NET: host Microsoft packages or docs in `ubuntu-len-yog-AMD64/docs/quantum-host-dotnet-rust.md`  
- Full profile: copy/adapt `profile-full.scm` once `which guix` is `…/current/bin/guix`
