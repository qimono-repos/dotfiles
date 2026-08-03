# QA — Day‑1 browsers (ubuntu-hp-pro)

**Use case:** HP ProBook · one sitting · you + sudo.  
**Success:** Guix Epiphany + Firefox open pages — and **survive reboot** (User R1/R2).

**Human + AI QA split:**

| Who | File |
|-----|------|
| Agent | [Checklist-agent.md](./Checklist-agent.md) |
| You | [Checklist-User.md](./Checklist-User.md) |
| Hub | [README.md](./README.md) |

Without reboot QA, status is **“works this boot only.”**

---

## Day −1 (optional, high value)

- [ ] Dotfiles tip on USB / git
- [ ] `bash -n scripts/*.sh` (or trust last hardening commit)
- [ ] `guix weather firefox` on nonguix not 0%
- [ ] Rough idea of `guix pull` duration

---

## Day 0 — Preflight (15–20 min)

| # | Check | Pass |
|---|--------|------|
| 1 | `uname -m` | `x86_64` |
| 2 | `df -h /` | **≥40 G free** |
| 3 | Network | reaches substitutes / guix |
| 4 | `sudo -v` | works |
| 5 | Graphical session | yes |
| 6 | Pack present | `ubuntu-hp-pro` complete |
| 7 | Proxy | none or set before guix |

**Stop** if disk/network/sudo fail.

---

## Day 1 — Ritual

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro
./scripts/install-host-sysctl.sh    # optional quick win
./scripts/bootstrap.sh
# ./scripts/bootstrap.sh --skip-snap
```

### Resume map

| Flag | Step |
|------|------|
| `--from 0` | apt |
| `--from 1` | install Guix |
| `--from 2` | pull + nonguix |
| `--from 3` | userns + key |
| `--from 4` | epiphany firefox |
| `--from 5` | PATH / desktop |
| `--from 6` | snap remove |

### Stay for

- [ ] sudo / installer  
- [ ] end of pull  
- [ ] step 4 — **Ctrl+C** if `firefox-*.source` builds  

### Script hard gates

- post-pull guix · userns `0` + drop-in · ≥40 G · weather not 0% for firefox  

---

## GUI smoke + persistence QA

```bash
source ~/.guix-profile/etc/profile
export PATH="$HOME/.config/guix/current/bin:$PATH"
epiphany &
firefox &
```

- [ ] Epiphany page  
- [ ] Firefox page  
- [ ] **Reboot after Epiphany launched once** (User R1)  
- [ ] After reboot: userns `0` + drop-in + Epiphany again (User R2)  

---

## Contingency

| Problem | Action |
|---------|--------|
| No network | hotspot; retry |
| Weather 0% Firefox | wait — never source-build day 1 |
| Epiphany trap | `./scripts/install-host-sysctl.sh` |
| Wrong guix | `PATH=…/current/bin` |
| Interrupted | `bootstrap.sh --from N` |

---

## Definition of done (QA)

1. Bootstrap clean (no Firefox compile)  
2. Userns drop-in + live `0`  
3. Guix browsers open pages  
4. **Reboot-verified** Epiphany  
