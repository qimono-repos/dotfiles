# ubuntu-hp-pro

Machine pack for a **Linux HP ProBook** (Intel, x86_64 expected) in the Qimono / Ying-Yang fleet.

**Sibling lessons:** `ubuntu-len-yog-AMD64` (Yoga Ryzen) — browser path proven there.  
**This pack’s job #1:** bare Ubuntu → **Guix + Epiphany (GNOME Web) + Firefox** in one session.

## Confidence (Firefox + Epiphany via Guix)

| Scenario | Confidence | Why |
|----------|------------|-----|
| HP ProBook, **x86_64**, Ubuntu 24.04/26.04-ish, **you + sudo**, network, **≥40 G free**, hardened bootstrap + **QA/** | **~97–99%** first session | Yoga-proven; userns drop-in; weather/disk/wrong-guix gates; Human+AI reboot QA |
| Skip preflight / ignore “don’t compile Firefox” | **~90–93%** | Human error |
| Arm64 / offline / no sudo | **Low** | Different story |
| “Also full quantum + .NET + uv in same session” | **~50%** | Out of scope |

**QA (this use case):** [QA/README.md](./QA/README.md) — **Human + AI** checklists · [QA/Day1-browsers.md](./QA/Day1-browsers.md)  
**Model:** [CONFIDENCE.md](./CONFIDENCE.md)

**Not magic if:** you skip sudo, use old `/usr/local/bin/guix` without pull, or let Firefox **source-build** when weather is 0%.

## Day-one ritual (what you described)

```bash
# 0) Get this repo onto the ProBook (usb / git clone / scp)
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro   # or wherever you put it

# 1) Optional: remove snap browsers first (script can do this too)
# sudo snap remove firefox
# sudo snap remove epiphany   # if present as "epiphany" or gnome-web packaging

# 2) Preflight — see QA/Day1-browsers.md and QA/Checklist-User.md (≥40G, network, sudo)

# 3) The magic
chmod +x ./scripts/bootstrap.sh  # if needed
./scripts/bootstrap.sh
```

Sit near the machine: **sudo** a few times; **guix pull** can take a while; **watch step 4** (no `firefox-*.source` compile).

When it finishes — **QA smoke** then **reboot** (see `QA/Checklist-User.md` R1/R2):

```bash
source ~/.guix-profile/etc/profile
epiphany &
firefox &
# then reboot and open epiphany again — that is the real QA pass
```

## Layout

```
ubuntu-hp-pro/
  README.md                 # this file
  CONFIDENCE.md             # risk notes
  docs/LESSONS.md           # pointer to Yoga browser lessons
  guix/channels.scm         # nonguix + default
  QA/                       # Human + AI QA (this use case only)
    README.md               # hub
    Checklist-agent.md
    Checklist-User.md       # reboot after first Epiphany
    Day1-browsers.md
  host-sysctl/99-guix-userns.conf   # → /etc/sysctl.d/ (must install; survives reboot)
  keys/nonguix-signing-key.pub      # vendored; authorize without curl if present
  scripts/bootstrap.sh      # main entry (prints resume map)
  scripts/install-host-sysctl.sh    # AppArmor userns=0 only (sudo)
  scripts/00-host-apt-min.sh
  scripts/10-install-guix.sh
  scripts/20-guix-pull-channels.sh  # hard-fail if not post-pull guix
  scripts/30-browser-prereqs.sh     # userns + nonguix key
  scripts/40-install-browsers.sh    # disk + weather + install
  scripts/50-shell-path.sh
  scripts/60-remove-snap-browsers.sh
  stow-source/shell/        # .zshrc.d snippets (guix, history, oh-my-posh)
  scripts/stow-apply.sh     # stow -d stow-source -t $HOME shell
```

### Shell history (fleet baseline)

`stow-source/shell/.zshrc.d/15-history.zsh` keeps **≥1000** commands (`HISTSIZE`/`SAVEHIST`) and shares history across sessions. Apply with:

```bash
./scripts/stow-apply.sh
# then: source ~/.zshrc
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
