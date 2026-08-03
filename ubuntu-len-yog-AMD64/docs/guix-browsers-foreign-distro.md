# Guix browsers on Ubuntu (foreign distro) — call it a day checklist

After `guix pull` with **nonguix**, Firefox is package `firefox` from `nongnu/packages/mozilla.scm`.  
Default Guix CI does **not** always have Firefox substitutes; **nonguix** does:

`https://substitutes.nonguix.org`

## 0) Always use post-pull Guix

Your pull printed this for a reason:

```bash
export GUIX_PROFILE="$HOME/.config/guix/current"
source "$GUIX_PROFILE/etc/profile"
hash guix
which guix   # should be ~/.config/guix/current/bin/guix
guix describe
```

Without that, `guix search firefox` only sees the old Guix (emacs-firefox-javascript-repl).

Also keep the **user profile** on PATH:

```bash
export GUIX_PROFILE="$HOME/.guix-profile"
source "$GUIX_PROFILE/etc/profile"
```

(Stow `10-guix.zsh` should load both; open a new terminal after stow.)

---

## 1) Fix Epiphany / WebKit `bwrap: setting up uid map: Permission denied`

**Cause:** Ubuntu sets  
`kernel.apparmor_restrict_unprivileged_userns=1`  
Guix WebKit/Epiphany uses bubblewrap user namespaces → crash (not a broken Guix package).

### One-shot (until reboot)

```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

### Permanent

```bash
echo 'kernel.apparmor_restrict_unprivileged_userns=0' | \
  sudo tee /etc/sysctl.d/99-guix-userns.conf
sudo sysctl --system
```

Then:

```bash
source ~/.guix-profile/etc/profile
export LANG=en_US.UTF-8
export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
epiphany &
```

**Security note:** this relaxes an Ubuntu hardening knob. Acceptable for a personal Yoga; revisit for multi-user/kiosk machines.

---

## 2) Authorize nonguix substitutes + install Firefox

```bash
# key (once per machine)
curl -fsSL https://substitutes.nonguix.org/signing-key.pub -o /tmp/nonguix-signing-key.pub
sudo guix archive --authorize < /tmp/nonguix-signing-key.pub

# install Firefox (download ~76 MiB compressed if substitutes work)
export PATH="$HOME/.config/guix/current/bin:$PATH"
hash guix

guix install firefox \
  --substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
```

**Preferred long-term:** add `"firefox"` to `guix/manifests/profile-full.scm`, then:

```bash
guix package -m guix/manifests/profile-full.scm \
  --substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
```

Optional daemon-wide (so you do not pass `--substitute-urls` every time) — edit guix-daemon service to include `https://substitutes.nonguix.org` first; see Guix manual “Getting Substitutes from Other Servers”.

### Do **not** compile Firefox from source on 6.5 GiB RAM

If substitutes fail, stop and fix authorization/URLs. Building Firefox will thrash the machine.

Optional Guix Chromium (substitutes on bordeaux):

```bash
guix install ungoogled-chromium
```

---

## 3) App grid (GNOME) — desktop files

Guix already installs `.desktop` files under:

`$HOME/.guix-profile/share/applications/`

(e.g. `org.gnome.Epiphany.desktop`, and after install Firefox’s desktop file).

GNOME must see them via `XDG_DATA_DIRS`. Stow shell should set Guix profile; also:

```bash
# refresh desktop database
update-desktop-database "$HOME/.guix-profile/share/applications" 2>/dev/null || true

# force icons into user applications (reliable for app grid)
mkdir -p "$HOME/.local/share/applications"
ln -sfn "$HOME/.guix-profile/share/applications/org.gnome.Epiphany.desktop" \
  "$HOME/.local/share/applications/org.gnome.Epiphany.desktop"
# after firefox install, link its .desktop too (name may be firefox.desktop)
ls "$HOME/.guix-profile/share/applications/" | grep -iE 'epiphany|firefox|web'

# log out/in of GNOME, or:
# Super key → type "Web" or "Firefox"
```

Helper script: `scripts/link-guix-desktop-apps.sh`

---

## 4) Open commands

| App | Terminal |
|-----|----------|
| GNOME Web | `epiphany &` |
| Firefox (Guix) | `firefox &` |

---

## 5) Call-it-a-day verification

```bash
export PATH="$HOME/.config/guix/current/bin:$PATH"
export GUIX_PROFILE="$HOME/.guix-profile"
source "$GUIX_PROFILE/etc/profile"
hash guix

cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns   # want 0
guix package -I | grep -iE 'epiphany|firefox'
epiphany --version
firefox --version
```

Keep **Chrome/Brave** until both Guix browsers open a page successfully; then you can ignore them.
