# Checklist — Agent (Guix browsers / host gates)

**Machine pack:** `ubuntu-hp-pro`  
**Pair file:** [Checklist-User.md](./Checklist-User.md) (human does sudo, reboot, GUI pen-checks)

**How to use**

- In the repo: mark done with `- [x]` (leave `- [ ]` open).
- On paper: print and tick with a pen.
- **Do not** mark host gates complete until the User checklist has **reboot-verified** Epiphany (or an explicit “reboot deferred” note signed by the human).

**Victory rule (agent):** Epiphany launching once is a **smoke**, not done. Done = drop-in on disk + live sysctl `0` + GUI once + **User reboot + Epiphany again**.

---

## A0 — Before claiming anything works

- [ ] Read pack `CONFIDENCE.md` + `DAY1-CHECKLIST.md` + this file + Checklist-User
- [ ] Confirm work is on **x86_64** Ubuntu foreign distro + Guix (not ARM assumptions)
- [ ] Confirm scope: Epiphany + Firefox via Guix substitutes; not full quantum day-1

---

## A1 — Pack integrity (no machine sudo required)

- [ ] `host-sysctl/99-guix-userns.conf` present and sets `kernel.apparmor_restrict_unprivileged_userns=0`
- [ ] `scripts/install-host-sysctl.sh` present and copies that file to `/etc/sysctl.d/`
- [ ] `scripts/30-browser-prereqs.sh` calls install-host-sysctl and fails if value ≠ `0`
- [ ] `scripts/40-install-browsers.sh` hard-gates: post-pull guix, ≥40 G free, `guix weather firefox`
- [ ] `keys/nonguix-signing-key.pub` vendored (or document curl fallback only)
- [ ] `bash -n scripts/*.sh` all clean
- [ ] Resume map documented (`bootstrap.sh --from N` / DAY1 card)

---

## A2 — Root cause checklist (AppArmor / bwrap) — know before you declare win

- [ ] Explained: Ubuntu `apparmor_restrict_unprivileged_userns=1` by default
- [ ] Explained: host `/usr/bin/bwrap` may work while Guix `/gnu/store/*-bubblewrap-*/bin/bwrap` fails
- [ ] Explained: `sysctl -w` alone **dies on reboot** — drop-in required
- [ ] Never tell user “fixed” after only `sysctl -w` without install to `/etc/sysctl.d/`

---

## A3 — Preflight assistance (agent can run / draft)

- [ ] Remind User of Day 0 gates: arch, disk ≥40 G, network, sudo, graphical session
- [ ] If on a reference machine (Yoga): check whether `/etc/sysctl.d/99-guix-userns.conf` exists
- [ ] If on a reference machine: `sysctl kernel.apparmor_restrict_unprivileged_userns` (want `0`)
- [ ] Optional: `guix weather firefox --substitute-urls=https://substitutes.nonguix.org` (record if 0%)

---

## A4 — During bootstrap (agent coaching / log watch)

- [ ] Point User at `./scripts/bootstrap.sh` (or `--skip-snap` until GUI OK)
- [ ] After step 2: insist `which guix` → `…/.config/guix/current/bin/guix`
- [ ] After step 3: insist drop-in file **and** live value `0` (not “Epiphany opened”)
- [ ] During step 4: if log shows `firefox-*.source` / long compile → stop User (Ctrl+C); do not normalize source build
- [ ] After install: remind User of GUI smoke commands (Checklist-User G1)

---

## A5 — Acceptance gates (agent marks only when evidence exists)

### Host policy (must be true on the **target** machine)

- [ ] Evidence: `/etc/sysctl.d/99-guix-userns.conf` installed (User or script output)
- [ ] Evidence: `apparmor_restrict_unprivileged_userns = 0` live
- [ ] Evidence: Guix Epiphany launched **once** (User G1)

### Persistence (mandatory — retrospective lesson)

- [ ] **User completed reboot** after first successful Epiphany launch  
      (see Checklist-User **R1** — agent does not mark this alone)
- [ ] Evidence after reboot: sysctl still `0` and drop-in still present
- [ ] Evidence after reboot: Epiphany launches again (User **R2**)

### Browsers

- [ ] Epiphany: Guix binary on PATH; GUI page load once **and** after reboot
- [ ] Firefox: installed from substitutes (weather was not 0%); GUI page load
- [ ] Status language: if reboot not done → mark browsers as **`[~] works this boot only`**, never full victory

---

## A6 — Confidence / docs (agent)

- [ ] Do not raise HP confidence past ~90% for “browsers done” until **A5 persistence** is `[x]`
- [ ] Update journal/LESSONS only with: drop-in path + reboot-verified yes/no
- [ ] If User defers reboot: write explicit **reboot deferred** note; do not claim day-1 complete

---

## A7 — Agent anti-patterns (do not)

- [ ] Do not equate `epiphany &` success with host ready
- [ ] Do not leave ad-hoc `/etc/sysctl.d/99-apparmor-userns.conf` as the only fix when pack uses `99-guix-userns.conf`
- [ ] Do not dismiss AppArmor as out of scope in a Guix-on-Ubuntu GUI session
- [ ] Do not run destructive disk/Windows dual-boot operations
- [ ] Do not encourage Firefox source builds on laptops

---

## Sign-off (agent)

| Field | Value |
|-------|--------|
| Date | |
| Host (hostname) | |
| Pack commit / tip | |
| Reboot-verified Epiphany? (yes/no) | |
| Agent notes | |

- [ ] Agent accepts: **not done** until User R1+R2 are checked (or reboot deferred recorded)
