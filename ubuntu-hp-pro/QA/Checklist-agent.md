# QA — Agent (ubuntu-hp-pro)

**Use case:** HP ProBook · Guix browsers / host gates  
**Pair:** [Checklist-User.md](./Checklist-User.md) · **Hub:** [README.md](./README.md)

**How to use:** `- [x]` in git, or print + pen.  
**Do not** mark host gates complete until User QA has **reboot-verified** Epiphany (or reboot deferred, signed by human).

**Victory rule:** Epiphany once = smoke, not QA pass. Pass = drop-in + sysctl `0` + GUI once + **User reboot + Epiphany again**.

---

## A0 — Before claiming anything works

- [ ] Read pack `CONFIDENCE.md` + [Day1-browsers.md](./Day1-browsers.md) + this file + User QA
- [ ] Confirm **x86_64** Ubuntu foreign distro + Guix (not ARM assumptions)
- [ ] Scope: Epiphany + Firefox via substitutes; not full quantum day‑1

---

## A1 — Pack integrity (no machine sudo required)

- [ ] `host-sysctl/99-guix-userns.conf` sets `kernel.apparmor_restrict_unprivileged_userns=0`
- [ ] `scripts/install-host-sysctl.sh` installs that file to `/etc/sysctl.d/`
- [ ] `scripts/30-browser-prereqs.sh` fails if userns ≠ `0`
- [ ] `scripts/40-install-browsers.sh` hard-gates: post-pull guix, ≥40 G free, `guix weather firefox`
- [ ] `keys/nonguix-signing-key.pub` vendored (or curl fallback documented)
- [ ] `bash -n scripts/*.sh` clean
- [ ] Resume map documented (`bootstrap.sh --from N` / Day1 QA card)

---

## A2 — Root cause (AppArmor / bwrap) — know before win

- [ ] Ubuntu default: `apparmor_restrict_unprivileged_userns=1`
- [ ] Host `/usr/bin/bwrap` may work; Guix store `bwrap` may not
- [ ] `sysctl -w` alone **dies on reboot** — drop-in required
- [ ] Never say “fixed” after only `sysctl -w` without `/etc/sysctl.d/`

---

## A3 — Preflight assistance

- [ ] Remind User Day 0: arch, disk ≥40 G, network, sudo, graphical session
- [ ] Optional: `guix weather firefox` on nonguix (record if 0%)

---

## A4 — During bootstrap (coaching / log watch)

- [ ] Point User at `./scripts/bootstrap.sh` (or `--skip-snap`)
- [ ] After step 2: `which guix` → `…/.config/guix/current/bin/guix`
- [ ] After step 3: drop-in **and** live `0` (not “Epiphany opened”)
- [ ] Step 4: `firefox-*.source` / long compile → stop User (Ctrl+C)
- [ ] After install: User QA **G1** smoke

---

## A5 — Acceptance (evidence only)

### Host policy

- [ ] `/etc/sysctl.d/99-guix-userns.conf` installed
- [ ] `apparmor_restrict_unprivileged_userns = 0` live
- [ ] Epiphany launched **once** (User G1)

### Persistence (mandatory QA)

- [ ] User **rebooted** after first Epiphany (User **R1**)
- [ ] After reboot: sysctl `0` + drop-in present
- [ ] After reboot: Epiphany again (User **R2**)

### Browsers

- [ ] Epiphany: page load once **and** after reboot
- [ ] Firefox: substitutes path; page load
- [ ] If reboot not done → **`[~] works this boot only`** — not full QA pass

---

## A6 — Confidence / docs

- [ ] Do not raise “browsers done” confidence past ~90% until A5 persistence `[x]`
- [ ] Journal/LESSONS: drop-in path + reboot-verified yes/no
- [ ] Reboot deferred → record it; do not claim day‑1 complete

---

## A7 — Anti-patterns

- [ ] Do not equate `epiphany &` with host ready
- [ ] Do not leave only ad-hoc `99-apparmor-userns.conf` when pack uses `99-guix-userns.conf`
- [ ] Do not dismiss AppArmor in Guix-on-Ubuntu GUI work
- [ ] Do not encourage Firefox source builds on laptops

---

## Sign-off (agent QA)

| Field | Value |
|-------|--------|
| Date | |
| Host | |
| Pack tip | |
| Reboot-verified Epiphany? | |
| Notes | |

- [ ] Agent: **not done** until User R1+R2 `[x]` (or reboot deferred recorded)
