# AMSTERPLAN — five small brains instead of one big upgrade

> Strategy against the 2026 memory crisis ("RAMageddon"): DRAM contract prices
> rose 90–95% QoQ in Q1 2026 (TrendForce) and AI datacenters now consume ~70%
> of global memory output; analysts see no relief before H2 2027. Upgrading a
> workstation is off the table — so we federate the fleet we already own.
>
> Thesis: **5 machines × lightweight Gemma ≫ 1 machine you cannot afford to
> expand.** Every node runs Ollama + one Gemma 4 variant sized to its RAM,
> reachable over Tailscale, each specialized for a slice of the quantum-
> computing workload.

---

## The fleet

RAM figures are **verified ground truth where probed**, not marketing specs.

| # | Node | Hardware | RAM | Role | Model | Status |
|---|------|----------|-----|------|-------|--------|
| 1 | `qimono-localhost` (Yoga) | Ryzen 5 8640HS · Radeon 760M | **~6.5 GiB** ⚠️ | daily-driver terminal copilot | `gemma4:e2b` | ✅ landed 2026-08-21 |
| 2 | `qi-mini-pc-ubu-rr` | Ryzen 7 7730U | ~14.5 GiB | always-on brain: heavier reasoning, corpus/RAG host | `gemma4:e4b` (+optional `12b`) | 📦 pack ready, needs rollout |
| 3 | HP ProBook | ? | ? | Jupyter-twin notebook copilot | `gemma4:e4b` | 📦 pack ready, needs rollout |
| 4 | greenfield-α | ? | ? | candidate: Stim/QEC experiment node | sized on arrival | 🌱 |
| 5 | greenfield-β | ? | ? | candidate: eval/benchmark runner | sized on arrival | 🌱 |

⚠️ The Yoga is **not** a 16 GB machine — treat its 6.5 GiB as the floor case:
E2B only, close Chrome before loading (measured 2026-08-21).

### Sizing rules (from `gemma4-report.md`)

| Variant | Effective params | Fits | Assign to |
|---|---|---|---|
| `gemma4:e2b` | ~2.3 B | ≤8 GB class, shared desktops | Yoga |
| `gemma4:e4b` | ~4.5 B | laptops w/ headroom | ProBook, mini-pc daily |
| `gemma4:12b` | dense 12 B | "standard 16 GB laptops", dedicated sessions | mini-pc on demand |
| `26b-a4b` MoE | 3.8 B active | consumer GPU — none in fleet yet | aspirational/greenfield |

## Division of labor — mapped to the quantum stack

Workload source: `~/source/repos/qimono-repos/qu` (Q#/Azure Quantum,
Cirq, Stim, Qiskit — polyglot, single contributor, straight to main).

| Task | Owner node | Why |
|---|---|---|
| shell/git/commit copilot, quick circuit Q&A | Yoga (e2b) | zero-latency local, already wired to zsh workflow |
| qiskit/pennylane code review & refactors | mini-pc (e4b/12b) | most RAM + hosts `quantum-workspace` |
| corpus Q&A / paper summarization (RAG over `corpus/` + `index/`) | mini-pc | index builder lives there too |
| notebook cell assistance (Cirq demos, plots) | ProBook (e4b) | Jupyter twin on 5005 |
| Stim/error-correction experiment scripting | greenfield-α | isolate memory-heavy sweeps |
| prompt/model evals across variants | greenfield-β | `eval/` harness runs where nobody works |

## Communication topology

All nodes join the tailnet `tailbb5c9e.ts.net`; peers talk to Ollama's HTTP
API over MagicDNS names — **no router config, no LAN exposure**.

Current blocker (2026-08-21): `tailscale status` shows **only this Yoga**.
Phase 1 is literally "turn the other four on".

### Exposing Ollama to the tailnet (per node)

Default bind is `127.0.0.1:11434` — peers can't reach it. Recommended:

```bash
# /etc/systemd/system/ollama.service.d/10-fleet-bind.conf
[Service]
Environment=OLLAMA_HOST=0.0.0.0:11434

sudo systemctl daemon-reload && sudo systemctl restart ollama
# fence it to the tailnet interface only:
sudo ufw allow in on tailscale0 to any port 11434 proto tcp
```

Alternative (zero firewall dependency): bind straight to the node's tailnet
IP, e.g. `Environment=OLLAMA_HOST=100.75.158.18:11434` — caveat: ollama must
start *after* tailscaled has raised the interface.

Verify from another node:

```bash
curl http://qi-mini-pc-ubu-rr.tailbb5c9e.ts.net:11434/api/tags
```

Probe the whole fleet anytime:

```bash
dotfiles/llm/fleet-status.sh          # FLEET_HOSTS="..." to extend
```

## Rollout phases

- [x] **P0 — Yoga node**: ollama 0.32.15 active+enabled, `gemma4:e2b` pulled, terminal workflow + prompts landed.
- [ ] **P1 — onboard known nodes**: both laptops on tailscale; run `install-ollama-stack.sh --model gemma4:e4b` on each (idempotent, safe to re-run).
- [ ] **P2 — expose + verify**: `10-fleet-bind.conf` drop-in per node, ufw fence, `fleet-status.sh` all-green.
- [ ] **P3 — greenfield bootstrap**: same one-liner per new machine; record specs back into this table.
- [ ] **P4 — orchestration**: ask-by-role dispatcher (route prompt to the right node), wire `modelfile/GemmaQ` + `mcp/gemma-tools-server.py` into the fleet path.

## Rules

1. Never pull a model larger than the sizing table allows for that RAM class.
2. Secrets stay out of git; tailnet-only exposure, no port forwarding.
3. SSH between nodes follows the same keys-only hardening as Part 4 of
   `TAILSCALE-README.md` (pending on this Yoga).
4. Any hardware change → update the fleet table here AND `AGENTS.md`.
