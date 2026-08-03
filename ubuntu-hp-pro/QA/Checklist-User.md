# QA — User / human (ubuntu-hp-pro)

**Use case:** HP ProBook · Guix browsers / host gates  
**Pair:** [Checklist-agent.md](./Checklist-agent.md) · **Hub:** [README.md](./README.md)

**How to use:** `- [ ]` → `- [x]` in git, or **print + pen**.  
You own: **sudo**, **reboot**, install logs, **GUI clicks**.

**Victory rule:** Epiphany once is good. **QA pass** = after **reboot**, Epiphany still opens.

---

## U0 — Day 0 preflight

- [ ] `uname -m` → **x86_64**
- [ ] `df -h /` → **≥ 40 G** free (prefer ≥50)
- [ ] Network works
- [ ] `sudo -v` works
- [ ] Graphical session (for GUI smoke)
- [ ] Dotfiles: `…/ubuntu-hp-pro` complete
- [ ] Proxy OK or env set before Guix

**Stop if red.** Do not start `guix pull` on a bad preflight.

---

## U1 — Bootstrap (you run)

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro   # adjust path
```

- [ ] Optional: `./scripts/install-host-sysctl.sh`
- [ ] `./scripts/bootstrap.sh` (or `--skip-snap`)
- [ ] Stay for sudo + long `guix pull`
- [ ] Know resume: `--from N` (0…6)

---

## U2 — Watch gates

- [ ] `which guix` → `…/.config/guix/current/bin/guix`
- [ ] Userns:

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns   # = 0
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
```

- [ ] Live **0** + drop-in exists
- [ ] If **building `firefox-*.source`** → **Ctrl+C** (no day‑1 compile)

---

## G1 — First GUI smoke (same boot)

```bash
source ~/.guix-profile/etc/profile
export PATH="$HOME/.config/guix/current/bin:$PATH"
epiphany &
firefox &
```

- [ ] Epiphany opened a page
- [ ] Firefox opened a page (or defer if substitutes 0% — no compile)

**Not QA pass yet — reboot next.**

---

## R1 — Reboot after Epiphany launched once  ← mandatory QA

- [ ] **Reboot** after successful first Epiphany (full reboot)

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
```

- [ ] After reboot: still **0**
- [ ] After reboot: drop-in still present

---

## R2 — Epiphany after reboot  ← mandatory QA

```bash
source ~/.guix-profile/etc/profile
epiphany &
```

- [ ] Epiphany opens a page again
- [ ] (Optional) Firefox after reboot

If `bwrap: setting up uid map: Permission denied`:  
`./scripts/install-host-sysctl.sh` → fix → reboot → R1/R2 again.

---

## U3 — Optional

- [ ] Snap browsers removed if desired
- [ ] New terminal has Guix on PATH

---

## Done when (pen)

- [ ] Preflight green  
- [ ] Bootstrap clean (no Firefox source build)  
- [ ] G1 OK  
- [ ] **R1 reboot**  
- [ ] **R2 Epiphany after reboot**  
- [ ] Tell agent R1+R2 are `[x]` so agent QA can pass  

---

## Sign-off (human QA)

| Field | Value |
|-------|--------|
| Date | |
| Hostname | |
| Pen / git? | |
| Reboot done? | |
| Epiphany after reboot? | |
| Notes | |
