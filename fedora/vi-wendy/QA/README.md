# QA — fedora/vi-wendy

**Use case:** legacy Fedora notebook discovery, GitHub access, and remote-access cleanup.

## Qimono Human + AI QA

This pack is evidence-driven. The host is not promoted to a server or bare-metal Guix role just because a command succeeds once.

| Role | Owns | File |
|------|------|------|
| **AI agent** | Pack integrity, read-only discovery, no false role claims | [Checklist-agent.md](./Checklist-agent.md) |
| **Human** | sudo cleanup, reboot/health checks, firewall decisions | [Checklist-User.md](./Checklist-User.md) |
| **Both** | Host snapshot + access verification | [MACHINE.md](../MACHINE.md), [GITHUB.md](../GITHUB.md) |

**Victory rule:** discovery snapshot current, GitHub SSH verified, TeamViewer absent, and role boundaries still honest.
