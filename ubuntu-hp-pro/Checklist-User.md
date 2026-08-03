# Checklist — User / human (Guix browsers / host gates)

**Machine pack:** `ubuntu-hp-pro`  
**Pair file:** [Checklist-agent.md](./Checklist-agent.md) (agent: scripts, gates, log coaching)

**How to use**

- In the repo: change `- [ ]` to `- [x]` when done.
- Print this page and tick with a **pen** if you prefer offline.
- You own: **sudo**, **reboot**, **watching install logs**, **GUI clicks**.

**Victory rule (you):** Epiphany opening once is good news. **Real win** = after a **reboot**, Epiphany still opens. That is what AppArmor taught us.

---

## U0 — Day 0 preflight (before long bootstrap)

- [ ] Machine is **x86_64** (`uname -m`)
- [ ] Disk free on `/` **≥ 40 G** (`df -h /`) — prefer ≥50 G
- [ ] Network works (browser or `curl` to the outside world)
- [ ] `sudo -v` works (you know the password)
- [ ] Logged into a **graphical** session (not SSH-only for final smoke)
- [ ] Dotfiles present: `…/dotfiles/ubuntu-hp-pro` (git pull / USB complete)
- [ ] No surprise proxy — or you set `http_proxy` / `https_proxy` before Guix

**Stop here if any of the above fail.** Fix overnight; do not start `guix pull` on a red preflight.

---

## U1 — Start bootstrap (you run these)

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro   # adjust path
```

- [ ] Optional first: `./scripts/install-host-sysctl.sh` (sudo — quick AppArmor fix)
- [ ] Main: `./scripts/bootstrap.sh`  
      or keep snaps until GUI works: `./scripts/bootstrap.sh --skip-snap`
- [ ] Stay at the machine for sudo prompts and long `guix pull`

### Resume if interrupted

- [ ] I know `--from N` (0 apt … 1 guix … 2 pull … 3 userns+key … 4 browsers … 5 path … 6 snap)

---

## U2 — Watch gates (do not walk away blind)

- [ ] After pull: `which guix` shows `…/.config/guix/current/bin/guix` (not only `/usr/local/bin/guix`)
- [ ] After userns step:

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns
# must print = 0
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
```

- [ ] Live value is **0**
- [ ] File `/etc/sysctl.d/99-guix-userns.conf` exists  
- [ ] During browser install: if you see **building `firefox-*.source`** → **Ctrl+C**  
      Do **not** let Firefox compile for hours. Tell the agent / retry weather later.

---

## G1 — First GUI smoke (same boot as install)

```bash
source ~/.guix-profile/etc/profile
export PATH="$HOME/.config/guix/current/bin:$PATH"
epiphany &
firefox &
```

- [ ] Epiphany (Guix / GNOME Web) **launched once** and opened a page (e.g. https://example.com)
- [ ] Firefox (Guix) **launched once** and opened a page  
      (If Firefox substitutes are 0%, Epiphany-only is OK for emergency; retry Firefox later — no compile)

**Stop: do not celebrate “done” yet. Reboot is next.**

---

## R1 — Reboot after Epiphany launched once  ← mandatory

> Retrospective rule: without this box, host policy is **unproven**.

- [ ] **Reboot** the machine after Epiphany launched successfully once  
      (full reboot, not only log out)

```bash
# after reboot, in a new session:
sysctl kernel.apparmor_restrict_unprivileged_userns
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
```

- [ ] After reboot: sysctl still **`= 0`**
- [ ] After reboot: drop-in file still present

---

## R2 — Epiphany again after reboot  ← mandatory for victory

```bash
source ~/.guix-profile/etc/profile
epiphany &
```

- [ ] Epiphany launches again after reboot and opens a page
- [ ] (Optional) Firefox still launches after reboot

**If Epiphany dies with `bwrap: setting up uid map: Permission denied`:**  
run `./scripts/install-host-sysctl.sh`, confirm drop-in, reboot again, re-check R1/R2.

---

## U3 — Optional cleanup

- [ ] Snap browsers removed if that was the goal (`bootstrap` step 6, or manual `snap remove …`)
- [ ] New terminal has Guix on PATH (or your shell profile sources `~/.guix-profile`)

---

## Done when (pen this)

- [ ] Preflight was green  
- [ ] Bootstrap finished or resumed cleanly **without** Firefox source build  
- [ ] G1 first launch OK  
- [ ] **R1 reboot done**  
- [ ] **R2 Epiphany after reboot OK**  
- [ ] Agent may now mark full victory (tell them R1+R2 are `[x]`)

---

## Sign-off (human)

| Field | Value |
|-------|--------|
| Date | |
| Hostname | |
| Printed + pen? / edited in git? | |
| Reboot done? (yes/no) | |
| Epiphany after reboot? (yes/no) | |
| Notes | |
