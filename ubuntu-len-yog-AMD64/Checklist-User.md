# Checklist — User / human (Guix browsers / host gates)

**Machine pack:** `ubuntu-len-yog-AMD64` (this Yoga)  
**Pair file:** [Checklist-agent.md](./Checklist-agent.md)

**How to use:** `- [ ]` → `- [x]` in git, or print and tick with a **pen**.

**Victory rule:** After Epiphany works once, **reboot** and open Epiphany again. That is the real pass.

---

## G1 — First launch (this boot)

```bash
source ~/.guix-profile/etc/profile
epiphany &
```

- [ ] Epiphany launched once and opened a page

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns   # want 0
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
```

- [ ] Live userns value is **0**
- [ ] Drop-in `/etc/sysctl.d/99-guix-userns.conf` exists  
      (if not: `cd …/ubuntu-len-yog-AMD64 && ./scripts/install-host-sysctl.sh`)

---

## R1 — Reboot after Epiphany launched once  ← mandatory

- [ ] **Reboot** after a successful first Epiphany launch

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
- [ ] Epiphany launches again and opens a page

---

## Optional

- [ ] Firefox Guix GUI smoke (substitutes only — no source build)
- [ ] Tell agent R1+R2 are done so host gate can be marked complete

---

## Sign-off (human)

| Field | Value |
|-------|--------|
| Date | |
| Reboot done? | |
| Epiphany after reboot? | |
