# QA — darwin pack (macOS fleet)

**Use case:** the 2026 Apple Silicon fleet — **MacBook Air (M3)** + **Mac mini (M3)**,
macOS 26 Tahoe, Homebrew host + Apple Container machine running **Guix**.
Same idea as the Linux packs: **Human + AI** split checklists, no false victory.

| Role | Owns | File |
|------|------|------|
| **AI agent** | Pack/host evidence, anti false-victory | [Checklist-agent.md](./Checklist-agent.md) |
| **Human** | macOS update, GUI, admin sudo, pen ticks | [Checklist-User.md](./Checklist-User.md) |

**Mark boxes:** `- [ ]` open · `- [x]` done · or **print + pen**.

**Victory rule:** installs once ≠ done. **QA pass** after **R1** (fresh macOS
login) + **R2** (fresh shell re-sources zshrc with brew/container on PATH) +
the in-machine Guix smoke set runs green on **both** Macs.

## Run this test once

```bash
bash -n scripts/*.sh
./scripts/machine-discovery.sh | tee machine-$(hostname).txt
./scripts/bootstrap.sh --dry-run
```