# QA — ubuntu-len-yog-AMD64 (use case)

**Use case:** Lenovo **Yoga AMD64** pack — Guix-first laptop; reference host for Guix browsers + host gates (AppArmor userns).

## Qimono Human + AI QA

Same idea as the HP ProBook use case: **Human + AI** split checklists so neither claims victory alone.

| Role | Owns | File |
|------|------|------|
| **AI agent** | Pack/host evidence, anti false-victory | [Checklist-agent.md](./Checklist-agent.md) |
| **Human** | sudo, reboot, GUI, pen/git ticks | [Checklist-User.md](./Checklist-User.md) |

**Mark boxes:** `- [ ]` open · `- [x]` done · or **print + pen**.

**Victory rule:** Epiphany once ≠ done. **QA pass** after User **R1** (reboot) + **R2** (Epiphany again).

Sibling use case: `../ubuntu-hp-pro/QA/` (day‑1 bootstrap from bare Ubuntu).

Also: [../docs/LESSONS-guix-browsers.md](../docs/LESSONS-guix-browsers.md) · [../README.md](../README.md)
