# Checklist — Agent (Guix browsers / host gates)

**Machine pack:** `ubuntu-len-yog-AMD64` (reference Yoga AMD64)  
**Pair file:** [Checklist-User.md](./Checklist-User.md)

Same discipline as `ubuntu-hp-pro` (AppArmor userns + reboot). Use this pack’s scripts:

- `./scripts/install-host-sysctl.sh`
- `./scripts/setup-guix-browser-prereqs.sh`
- `./scripts/setup-guix-browsers-first-try.sh`

**How to use:** `- [ ]` open · `- [x]` done · or print and pen-tick.

**Victory rule:** Epiphany once ≠ done. Done = drop-in + sysctl `0` + GUI once + **User reboot + Epiphany again**.

---

## A0 — Scope

- [ ] Guix-on-Ubuntu foreign distro; x86_64 Yoga pack (not Snapdragon ARM)
- [ ] Host gate includes AppArmor unprivileged userns (not optional flavor text)

---

## A1 — Pack / host artifacts

- [ ] `host-sysctl/99-guix-userns.conf` present
- [ ] `scripts/install-host-sysctl.sh` present
- [ ] Bootstrap / browser prereqs install drop-in (not only `sysctl -w`)
- [ ] LESSONS mention store `bwrap` vs `/usr/bin/bwrap` and reboot

---

## A2 — On this host (when agent can inspect)

- [ ] Check `/etc/sysctl.d/99-guix-userns.conf` exists on the live machine
- [ ] Check `sysctl kernel.apparmor_restrict_unprivileged_userns` → `0`
- [ ] If only ad-hoc `99-apparmor-userns.conf` or runtime sysctl: insist User run `install-host-sysctl.sh`

---

## A3 — Acceptance

- [ ] Evidence: Epiphany launched once (User G1)
- [ ] Evidence: User **rebooted** after that launch (User R1)
- [ ] Evidence: Epiphany after reboot (User R2)
- [ ] If reboot deferred: status **`[~] works this boot only`** — no full victory

---

## A4 — Anti-patterns

- [ ] Do not close browser/host tasks on single-boot GUI smoke alone
- [ ] Do not dismiss AppArmor in Guix GUI sessions
- [ ] Do not encourage Firefox source builds on this 6.5 GiB laptop

---

## Sign-off (agent)

| Field | Value |
|-------|--------|
| Date | |
| Reboot-verified Epiphany? | |
| Notes | |
