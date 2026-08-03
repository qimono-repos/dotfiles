# Lessons learned — Guix Epiphany + Firefox on Ubuntu (2026-08)

Real session on Lenovo Yoga AMD64 (dual-boot, ~153 G root, 6.5 GiB RAM).  
Use this so the **next** machine hits a clean first try.

## What “success” looked like

| App | Package | What fixed it |
|-----|---------|----------------|
| GNOME Web | Guix `epiphany` | `kernel.apparmor_restrict_unprivileged_userns=0` |
| Firefox | Guix `firefox` (nonguix) | Post-pull guix + authorize nonguix key + **substitute** install (~76 MiB) |

Cosmetic: `Failed to load module "canberra-gtk-module"` — ignore (optional GTK event sounds).

---

## Lessons (ordered by how hard they bit us)

### 1. Two different `guix` binaries

| Binary | Role |
|--------|------|
| `/usr/local/bin/guix` | Often **installer / root** generation — **no** nonguix → `firefox: unknown package` |
| `~/.config/guix/current/bin/guix` | After **`guix pull`** with channels — **has** nonguix |

**Always:**

```bash
export PATH="$HOME/.config/guix/current/bin:$PATH"
hash guix
which guix   # must show …/current/bin/guix
guix describe   # must list nonguix
```

Stow: `stow-source/shell/.zshrc.d/10-guix.zsh` + `stow-source/shell/.zprofile` prepend this on login/interactive shells.

### 2. Channels without pull are useless for packages

`~/.config/guix/channels.scm` listing nonguix does nothing until:

```bash
guix pull
```

Then use **current** guix (lesson 1).

### 3. Epiphany crash is Ubuntu security, not a bad package

```text
bwrap: setting up uid map: Permission denied
Failed to fully launch dbus-proxy
trace trap (core dumped)
```

App grid “Web” **opens then spins forever** = WebKit process died the same way.

**Why Guix specifically:** Ubuntu AppArmor ships a userns profile only for **`/usr/bin/bwrap`**.  
Guix WebKit calls **`/gnu/store/*-bubblewrap-*/bin/bwrap`**, which is not covered, so with  
`kernel.apparmor_restrict_unprivileged_userns=1` (Ubuntu default) Guix sandboxes die.  
Host `/usr/bin/bwrap` may still work — that is a false “everything is fine” signal.

**`sysctl -w` alone is not enough** — it is **lost on reboot**. You must install the drop-in.

**Fix (permanent, pack script):**

```bash
./scripts/install-host-sysctl.sh
# installs host-sysctl/99-guix-userns.conf → /etc/sysctl.d/
# also: ./scripts/fix-guix-userns-epiphany.sh
# also: ./scripts/setup-guix-browser-prereqs.sh  (userns + nonguix key)
```

**Verify (including after reboot):**

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns   # must be 0
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
epiphany &
```

**QA discipline (use-case folder `QA/`):** first launch is not victory.  
Human: `QA/Checklist-User.md` **R1** (reboot) + **R2** (Epiphany again).  
Agent: `QA/Checklist-agent.md` — no host-gate pass until R1+R2.  
Hub: `QA/README.md` — **Qimono Human + AI QA**.

Same file + script live in **`ubuntu-hp-pro`** (keep both packs in sync).

### 4. Firefox must be a **substitute**, never a source build on this laptop

| Path | Outcome |
|------|---------|
| Build from source (`…source.tar…drv`) | Multi‑GB download, ENOSPC, failed |
| Substitute from `substitutes.nonguix.org` | ~76 MiB, worked |

Default CI/bordeaux often have **0%** Firefox substitutes. Nonguix has them **after** you:

```bash
curl -fsSL https://substitutes.nonguix.org/signing-key.pub -o /tmp/nonguix-signing-key.pub
sudo guix archive --authorize < /tmp/nonguix-signing-key.pub
```

And always pass (or configure daemon):

```text
--substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
```

If the log shows `firefox-….source.tar` **building**, **Ctrl+C** and fix key/URLs — do not compile on 6.5 GiB / dual-boot disk.

### 5. Disk is a real constraint

Failed run hit `No space left on device` while unpacking Firefox source.  
Even with ~50 G free later, a source build + deps peaks hard.

Before big installs:

```bash
df -h /
guix gc -F 20G    # only if free space is low
```

### 6. `guix package -m profile-full.scm` vs `guix install firefox`

| Method | When |
|--------|------|
| `guix install firefox …` | **First try / recovery** — only adds Firefox, smaller risk |
| `guix package -m profile-full.scm …` | **Preferred** once prereqs work — full declarative set |

`-m` **replaces** the listed set of packages in the profile generation — keep `profile-full.scm` complete. Never apply a **slim** partial manifest alone.

### 7. Desktop grid ≠ shell PATH

`.desktop` files live under `~/.guix-profile/share/applications/`.  
GNOME needs `XDG_DATA_DIRS` (stow sets it) and optionally:

```bash
./scripts/link-guix-desktop-apps.sh
```

Log out/in once if icons missing.

### 8. Harmless noise

`canberra-gtk-module` = optional event-sound plugin (often from apt Chrome/desktop). Not required for Guix browsers.

---

## First-try algorithm (next machine)

```text
1. guix pull  (channels.scm includes nonguix)
2. New shell; which guix → …/current/bin/guix
3. ./scripts/setup-guix-browser-prereqs.sh   # sudo: userns + nonguix key
4. guix install epiphany firefox \
     --substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
   # or profile-full.scm with same --substitute-urls
5. source ~/.guix-profile/etc/profile
6. epiphany &   firefox &
7. link-guix-desktop-apps.sh
```

Or: `./scripts/setup-guix-browsers-first-try.sh` (orchestrates docs + prereqs + install).

---

## Artifacts in this pack

| Path | Purpose |
|------|---------|
| `docs/LESSONS-guix-browsers.md` | This file |
| `docs/guix-browsers-foreign-distro.md` | Long checklist |
| `host-sysctl/99-guix-userns.conf` | Drop-in for `/etc/sysctl.d/` (must install; not auto) |
| `scripts/install-host-sysctl.sh` | sudo install drop-in + apply (survives reboot) |
| `scripts/fix-guix-userns-epiphany.sh` | alias → install-host-sysctl.sh |
| `scripts/setup-guix-browser-prereqs.sh` | userns + nonguix authorize |
| `scripts/bootstrap.sh` step 0 | installs userns drop-in if missing |
| `scripts/setup-guix-browsers-first-try.sh` | Ordered first-try installer |
| `scripts/link-guix-desktop-apps.sh` | App grid symlinks |
| `guix/manifests/profile-full.scm` | Includes epiphany + firefox |
| `stow-source/shell/.zshrc.d/10-guix.zsh` | current guix + profile + substitute URL env |
| `stow-source/shell/.zprofile` | Login-shell PATH for current guix |
