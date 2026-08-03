# QA — Agent (ubuntu-len-yog-AMD64)

**Use case:** Yoga AMD64 reference host · Guix browsers / host gates  
**Pair:** [Checklist-User.md](./Checklist-User.md) · **Hub:** [README.md](./README.md)

Scripts: `install-host-sysctl.sh` · `setup-guix-browser-prereqs.sh` · `setup-guix-browsers-first-try.sh`

**How to use:** `- [ ]` / `- [x]` · or print + pen.  
**Victory rule:** Epiphany once ≠ QA pass. Pass = drop-in + `0` + GUI once + **User reboot + Epiphany again**.

---

## A0 — Scope

- [ ] Guix-on-Ubuntu; **x86_64** Yoga pack (not Snapdragon ARM)
- [ ] AppArmor unprivileged userns is **in-scope** for Guix GUI

---

## A1 — Pack / host artifacts

- [ ] `host-sysctl/99-guix-userns.conf` present
- [ ] `scripts/install-host-sysctl.sh` present
- [ ] Prereqs install drop-in (not only `sysctl -w`)
- [ ] LESSONS mention store `bwrap` vs `/usr/bin/bwrap` + reboot

---

## A2 — Live host (when agent can inspect)

- [ ] `/etc/sysctl.d/99-guix-userns.conf` exists
- [ ] `sysctl kernel.apparmor_restrict_unprivileged_userns` → `0`
- [ ] If only ad-hoc conf or runtime sysctl → User runs `install-host-sysctl.sh`

---

## A3 — Acceptance

- [ ] Epiphany once (User G1)
- [ ] User **rebooted** (User R1)
- [ ] Epiphany after reboot (User R2)
- [ ] Else: **`[~] works this boot only`** — no full QA pass

---

## A4 — Anti-patterns

- [ ] No close-out on single-boot GUI smoke alone
- [ ] No dismissing AppArmor in Guix GUI sessions
- [ ] No Firefox source builds on this ~6.5 GiB laptop

---

## Sign-off (agent QA)

| Field | Value |
|-------|--------|
| Date | |
| Reboot-verified Epiphany? | |
| Notes | |
