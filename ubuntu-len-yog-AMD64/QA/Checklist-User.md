# QA — User / human (ubuntu-len-yog-AMD64)

**Use case:** this Yoga · Guix browsers / host gates  
**Pair:** [Checklist-agent.md](./Checklist-agent.md) · **Hub:** [README.md](./README.md)

**How to use:** `- [ ]` → `- [x]` · or **print + pen**.  
**Victory rule:** after Epiphany works once → **reboot** → Epiphany again = QA pass.

---

## G1 — First launch (this boot)

```bash
source ~/.guix-profile/etc/profile
epiphany &
```

- [ ] Epiphany opened a page

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns   # want 0
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
```

- [ ] Live userns **0**
- [ ] Drop-in exists (else: `./scripts/install-host-sysctl.sh` from this pack)

---

## R1 — Reboot after Epiphany launched once  ← mandatory QA

- [ ] **Reboot** after successful first Epiphany

---

## R2 — After reboot

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
source ~/.guix-profile/etc/profile
epiphany &
```

- [ ] sysctl still **0**
- [ ] drop-in still present
- [ ] Epiphany opens a page again

---

## Optional

- [ ] Firefox Guix GUI (substitutes only)
- [ ] Tell agent R1+R2 done for QA pass

---

## Sign-off (human QA)

| Field | Value |
|-------|--------|
| Date | |
| Reboot done? | |
| Epiphany after reboot? | |
