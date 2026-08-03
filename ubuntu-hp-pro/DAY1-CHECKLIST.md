# HP ProBook — Day‑1 browsers checklist

**Goal:** Guix **Epiphany + Firefox**, one sitting, you + sudo.  
**Pack:** `ubuntu-hp-pro` · **Success = both GUIs open a page**, not only `guix package -I`.

**Split work (checkboxes `- [ ]` / `- [x]`, or print + pen):**

| Who | File |
|-----|------|
| Agent | [Checklist-agent.md](./Checklist-agent.md) |
| You (human) | [Checklist-User.md](./Checklist-User.md) |

**Mandatory:** after Epiphany launches once → **reboot** → Epiphany again (User R1/R2). Without that, status is “works this boot only.”

---

## Day −1 (Yoga or any proven host) — optional but high value

- [ ] Dotfiles commit you will use is pushed / on USB
- [ ] `bash -n scripts/*.sh` clean (or trust last hardening commit)
- [ ] `guix weather firefox --substitute-urls=https://substitutes.nonguix.org` shows substitutes (not 0%)
- [ ] Know approx `guix pull` duration (patience)

---

## Day 0 — ProBook preflight (15–20 min, before long bootstrap)

| # | Check | Pass |
|---|--------|------|
| 1 | `uname -m` | `x86_64` |
| 2 | `df -h /` | **≥40 G free** (prefer ≥50) |
| 3 | Network | `curl -I https://substitutes.nonguix.org` works (or browser) |
| 4 | `sudo -v` | works |
| 5 | Graphical session | logged in (for later GUI smoke) |
| 6 | Dotfiles present | `…/dotfiles/ubuntu-hp-pro` complete |
| 7 | Proxy | none, or export `http_proxy`/`https_proxy` **before** guix |

**Stop** if disk/network/sudo fail — fix overnight, do not start pull.

---

## Day 1 — Main ritual

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro   # adjust path

# Optional quick win first:
./scripts/install-host-sysctl.sh

./scripts/bootstrap.sh
# or keep snaps until GUI works:
# ./scripts/bootstrap.sh --skip-snap
```

### Resume map

| Flag | Step |
|------|------|
| `--from 0` | apt minimum |
| `--from 1` | install Guix |
| `--from 2` | channels + `guix pull` |
| `--from 3` | userns + nonguix key |
| `--from 4` | install epiphany firefox |
| `--from 5` | PATH / desktop |
| `--from 6` | remove snap browsers |

### Stay at the machine for

- [ ] Guix installer / sudo prompts  
- [ ] End of **step 2** (`guix pull`)  
- [ ] **Step 4** log — if you see `building firefox-*.source` → **Ctrl+C**, fix weather/key, do **not** compile  

### Hard gates already in scripts

- Post-pull guix must be `~/.config/guix/current/bin/guix`  
- `apparmor_restrict_unprivileged_userns=0` + `/etc/sysctl.d/99-guix-userns.conf`  
- ≥40 G free before browser install  
- `guix weather firefox` on nonguix must not be 0%  

---

## GUI smoke (mandatory, same sitting)

```bash
source ~/.guix-profile/etc/profile
export PATH="$HOME/.config/guix/current/bin:$PATH"
which guix epiphany firefox
sysctl kernel.apparmor_restrict_unprivileged_userns   # 0
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
epiphany &    # open https://example.com
firefox &
```

- [ ] Epiphany loads a page  
- [ ] Firefox loads a page  

### Bonus / mandatory persistence (see Checklist-User R1–R2)

- [ ] **Reboot after Epiphany launched once**
- [ ] After reboot: userns still `0` + drop-in present
- [ ] After reboot: Epiphany still works  

---

## Contingency

| Problem | Action |
|---------|--------|
| No Wi‑Fi / blocked substitutes | Phone hotspot; retry |
| Weather 0% Firefox | Wait / retry next day — **never** source-build on day 1 |
| Epiphany trap | `./scripts/install-host-sysctl.sh` |
| Wrong guix | `export PATH="$HOME/.config/guix/current/bin:$PATH" && hash guix` |
| Interrupted bootstrap | `./scripts/bootstrap.sh --from N` |

Epiphany alone + snap Firefox is an acceptable **emergency** browser day; Guix Firefox can wait for substitutes.

---

## Definition of done

1. Bootstrap finished or resumed cleanly without Firefox compile  
2. Userns drop-in installed and live value `0`  
3. Guix Epiphany + Guix Firefox open a page  
4. (Bonus) Survives reboot  
