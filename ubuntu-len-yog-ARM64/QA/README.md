# QA — ubuntu-len-yog-ARM64 (use case)

**Use case:** Lenovo **Yoga Slim 7 Snapdragon (ARM64)** pack — first-time
bootstrap from a bare Ubuntu 26.04, Guix-first, no x86_64 blobs.

## Qimono Human + AI QA

Same idea as the other packs: **Human + AI** split checklists so neither
claims victory alone.

| Role | Owns | File |
|------|------|------|
| **AI agent** | Pack/host evidence, anti false-victory | [Checklist-agent.md](./Checklist-agent.md) |
| **Human** | sudo, reboot (R1/R2), GUI, pen/git ticks | [Checklist-User.md](./Checklist-User.md) |

**Mark boxes:** `- [ ]` open · `- [x]` done · or **print + pen**.

**Victory rule:** installs once ≠ done. **QA pass** after User **R1** (reboot)
+ **R2** (re-enable Guix env and re-run the smoke checks).

Sibling use case: `../ubuntu-len-yog-AMD64/QA/` (AMD Yoga) ·
`../ubuntu-hp-pro/QA/` (Intel ProBook).
