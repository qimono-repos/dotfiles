# QA — windows11 (use case)

**Use case:** Windows 11 **Snapdragon (ARM64)** "Yin" — parity install as close
as possible to the `ubuntu-len-yog-ARM64` Linux pack, within a ~500 MB download
budget (bandwidth-sensitive session).

## Qimono Human + AI QA

| Role | Owns | File |
|------|------|------|
| **AI agent** | Evidence (real command output), anti false-victory | [Checklist-agent.md](./Checklist-agent.md) |
| **Human** | sudo/elevation, reboots, GUI, pen/git ticks | [Checklist-User.md](./Checklist-User.md) |

**Mark boxes:** `- [ ]` open · `- [x]` done · or print + pen.

**Victory rule:** installed once ≠ done. QA pass after Qimono confirms a
fresh PowerShell session renders prompt + tools (R1) and the quantum smokes pass
again (R2, post-reboot).

Sibling use case: `../ubuntu-len-yog-ARM64/QA/` (Linux ARM64 pack).