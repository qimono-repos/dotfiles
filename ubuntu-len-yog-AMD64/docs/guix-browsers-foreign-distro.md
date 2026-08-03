# Guix browsers on Ubuntu (foreign distro)

**Start here for first-try:** [LESSONS-guix-browsers.md](./LESSONS-guix-browsers.md)  
**One command plan:** `./scripts/setup-guix-browsers-first-try.sh`

After `guix pull` with **nonguix**, Firefox is `firefox` in `nongnu/packages/mozilla.scm`.  
Binary substitutes: **`https://substitutes.nonguix.org`** (not always on CI/bordeaux).

## First-try (graceful)

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64

# 0) channels + pull once
#    stow already installs ~/.config/guix/channels.scm (nonguix)
guix pull
export PATH="$HOME/.config/guix/current/bin:$PATH" && hash guix
which guix && guix describe

# 1) host prereqs (sudo once)
./scripts/setup-guix-browser-prereqs.sh
#    - userns=0  → Epiphany works
#    - authorize nonguix key → Firefox substitute works

# 2) install browsers (small domain; good first try)
./scripts/setup-guix-browsers-first-try.sh install
#    ≡ guix install epiphany firefox --substitute-urls='…nonguix… …'

# 3) launch
source ~/.guix-profile/etc/profile
epiphany &
firefox &
```

Or all-in-one after pull: `./scripts/setup-guix-browsers-first-try.sh all`

## Later: declarative profile (preferred)

Only after prereqs work:

```bash
export PATH="$HOME/.config/guix/current/bin:$PATH" && hash guix
guix package -m guix/manifests/profile-full.scm \
  --substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
```

## Failure cheatsheet

| Symptom | Fix |
|---------|-----|
| `firefox: unknown package` | Use `…/current/bin/guix`; `guix pull` with nonguix |
| `bwrap: setting up uid map` / Epiphany trap | `setup-guix-browser-prereqs.sh` (userns) |
| Building `firefox-*.source*` / ENOSPC | Stop; authorize nonguix; free disk; substitute install |
| App grid missing icons | `link-guix-desktop-apps.sh` + log out/in |
| `canberra-gtk-module` | Ignore (optional sounds) |

## Verify

```bash
cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns   # 0
which guix
guix package -I | grep -iE 'firefox|epiphany'
epiphany --version
firefox --version
```
