# QA — ubuntu-hp-pro (use case)

**Use case:** bare Ubuntu **HP ProBook** → Guix + Epiphany + Firefox (day‑1 browsers).

## Qimono Human + AI QA

We celebrate the hard lesson: a single-boot “Epiphany works!” was **not** done until reboot.  
That error became process.

| Role | Owns | File |
|------|------|------|
| **AI agent** | Pack integrity, hard gates, log coaching, no false victory | [Checklist-agent.md](./Checklist-agent.md) |
| **Human** | sudo, reboot, GUI clicks, pen/git ticks | [Checklist-User.md](./Checklist-User.md) |
| **Together** | Day‑1 ritual + smoke | [Day1-browsers.md](./Day1-browsers.md) |

**Mark boxes:** `- [ ]` open · `- [x]` done · or **print + pen**.

**Victory rule:** Epiphany once is a smoke. **QA pass** = drop-in on disk + sysctl `0` + first GUI + **reboot** + Epiphany again (User **R1/R2**).

Born from AppArmor / Guix `bwrap` on Ubuntu — host policy must survive reboot.

Also: [../CONFIDENCE.md](../CONFIDENCE.md) · [../README.md](../README.md)
