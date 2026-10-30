# Qimono VPS — Next Steps and Collaborative Build Plan

**Status:** Architecture and execution brief  
**Target:** `vps-ubuntu` on the Hostinger Ubuntu VPS  
**Control plane:** `qimono-repos/dotfiles`  
**Execution model:** GitHub is the canonical source of truth; the VPS is the runtime and development target.  
**Working style:** Architect together with Albert, then implement in small, independently verifiable milestones with fast feedback from the live machine.

---

## 1. Mission

Turn this low-cost VPS into a compact, resilient, self-hosted Qimono development and services environment.

The goal is not to imitate an enterprise cluster. The goal is to squeeze useful capability out of a constrained machine through careful scheduling, lightweight components, isolation, automation, and graceful degradation.

The VPS should support:

- Agent-assisted development directly on the server using Codex and OpenCode.
- Kotlin/Ktor application development and deployment, connected to MongoDB Atlas.
- Python quantum-computing work with Qiskit and related tooling.
- Clojure/Babashka scripting and REPL workflows.
- A browser-accessible VS Code-like development environment.
- Sovereign services such as a Bluesky Personal Data Server (PDS) and OpenCloud, even if they must share this low-cost host.
- A maintainable reverse-proxy and TLS entry point.
- Reproducible machine configuration maintained in this repository.

## 2. Current machine baseline

Last verified provisioning report (2026-10-30):

| Resource / component | Observed state |
|---|---|
| OS | Ubuntu 26.04.1 LTS, x86_64 |
| Kernel | Linux 7.0.0-38-generic |
| CPU | 1 vCPU, AMD EPYC 9354P |
| Memory | 3.8 GiB total; approximately 3.2 GiB available after provisioning |
| Storage | 48 GB filesystem; approximately 36 GB available |
| Java | OpenJDK 21 |
| Gradle | 9.2.1 in Guix profile |
| GNU Guix | Working; current generation reused without routine pull |
| Guix profile | 25 packages, including Git, Neovim, Gradle, tmux, Stow, jq, yq, ripgrep and build tools |
| Shell | Zsh 5.9, configured as login shell |
| Dotfiles | VPS-native Stow package applied from this repository |
| Oh My Posh | 31.9.1 installed; Catppuccin theme file exists but needs visual refinement |
| MongoDB tooling | Atlas CLI 1.59.4 installed; no local MongoDB server; mongosh intentionally omitted |
| Coding agents | Codex CLI 0.166.0 and OpenCode 1.19.5; user confirmed both launch |
| GitHub CLI | Not yet installed / verified |
| Kotlin/Ktor application | Not yet created or deployed |
| Nginx / TLS | Not yet provisioned on this VPS |
| Browser IDE | Not yet deployed |
| Bluesky PDS / OpenCloud | Not yet deployed |

These values are a dated baseline, not live telemetry. Re-inventory before making resource-sensitive decisions.

## 3. Non-negotiable operating principles

1. **Repository first.** Persistent configuration, scripts, service definitions, manifests, and documentation belong in `qimono-repos/dotfiles`. Avoid one-off shell changes that cannot be reproduced.
2. **VPS is the execution target.** Codex and OpenCode should read this plan and the repository from inside the VPS. Use their local shell, project files, build tools, and logs for tight feedback loops.
3. **Architect with Albert.** Do not silently make major product, exposure, security, data-retention, or resource-allocation decisions. Present meaningful trade-offs and ask for feedback at architectural decision points.
4. **Build capabilities, not command tutorials.** Prefer a complete, idempotent milestone over a series of tiny manual tests. Provide one deployment/convergence command per milestone where practical.
5. **Graceful degradation.** Failure of an optional service must not take down unrelated services or the host. Use separate service users, systemd units, resource limits, health checks, restart policies, and explicit dependencies.
6. **Constrained-host creativity.** The budget is a real constraint, not a reason to abandon useful services. Schedule workloads, keep idle services stopped where practical, and prefer lightweight modes.
7. **No routine rebooting.** Do not reboot the VPS as a normal deployment step. Prefer service-level reloads/restarts and preserve SSH recovery access.
8. **Protect credentials and data.** Never commit secrets, tokens, private keys, Atlas connection strings, or real environment files. Use root/service-owned secret files with restrictive permissions or a suitable secret mechanism.
9. **Measure before expanding.** Capture memory, CPU, disk, process, and service health before and after significant additions. Do not assume that a service is lightweight because its documentation says so.
10. **Document rollback.** Every service milestone must explain how to stop, disable, inspect, and roll back that service without damaging other workloads.

## 4. Layered roadmap

### Layer A — Developer workstation

**Goal:** A comfortable, reproducible shell and editor environment.

- [ ] Refine the existing Oh My Posh theme into a real Catppuccin Mocha palette. Keep the theme in the VPS Stow package.
- [ ] Verify Zsh startup, PATH ordering, Guix profile activation, and prompt initialization.
- [ ] Install and configure GitHub CLI (`gh`); support SSH authentication, repository operations, releases, and automation.
- [ ] Review existing repository configurations for Neovim/LazyVim/LayVim. Reuse existing Qimono configuration where appropriate; do not blindly import an unrelated desktop setup.
- [ ] Configure Emacs with Evil mode as an alternative editor, if its memory and maintenance footprint is reasonable.
- [ ] Configure tmux for persistent remote sessions and recovery after SSH disconnects.
- [ ] Install Babashka (`bb`) for lightweight Clojure scripting and REPL workflows. JVM Clojure is optional and should be justified by a concrete need.

**Acceptance:** A new SSH login gives the managed shell; `gh`, `bb`, tmux and selected editors work; configuration is reproducible from Stow and scripts.

### Layer B — Application development

**Goal:** Deliver the first useful Qimono backend.

#### Kotlin + Ktor + MongoDB Atlas

- [ ] Create or connect the intended `the-porketo` backend repository/workspace.
- [ ] Use Java 21 and a committed Gradle wrapper. Pin the Kotlin and Ktor plugin/dependency versions in the project.
- [ ] Implement a minimal Ktor service with routing, configuration, structured logs, and a health endpoint.
- [ ] Connect to MongoDB Atlas using environment-based configuration. Do not store credentials in Git.
- [ ] Separate local development configuration from production service configuration.
- [ ] Create a dedicated unprivileged service account and systemd unit.
- [ ] Add build, deploy, health-check, log-inspection, stop, and rollback commands.
- [ ] Keep the service bound to loopback until the reverse proxy and exposure policy are ready.

**Acceptance:** One documented command builds and deploys the service; the health endpoint responds; Atlas connectivity is verified without exposing secrets; a failed deployment leaves the previous working version recoverable.

#### Python + quantum workspace

- [ ] Use Python 3.12 for scientific package compatibility rather than assuming Ubuntu's Python 3.14 is supported by every wheel.
- [ ] Prefer the existing Qimono Guix + uv approach and quantum workspace installer/manifests already in the repository.
- [ ] Set up a project-local environment for Qiskit, Qiskit Aer, PennyLane, NumPy, Matplotlib, and ipykernel as justified.
- [ ] Reuse existing Qiskit smoke tests and quantum documentation.
- [ ] Keep Jupyter bound to loopback and expose it only through an authenticated access path if needed.
- [ ] Avoid installing large scientific stacks into the global Guix profile unless there is a clear reason.

**Acceptance:** A reproducible quantum workspace runs the existing Qiskit smoke test and can register its own Jupyter kernel.

#### Clojure / Babashka

- [ ] Review `llm/clojure-proposal.md` and the existing Babashka direction.
- [ ] Install Babashka as a user-local, idempotent tool.
- [ ] Validate REPL and script workflows.
- [ ] If continuing the Gemma harness port, preserve the Python implementation as the reference until parity tests pass.

**Acceptance:** `bb` is available to the target user and a small repository-owned smoke task succeeds.

### Layer C — Browser-based development

**Goal:** Access the VPS development environment through a browser from local computers and mobile devices.

Evaluate these alternatives before committing:

- **code-server:** self-hosted VS Code-like experience, using Open VSX by default.
- **OpenVSCode Server:** alternative closer to upstream VS Code distribution.

Compare extension compatibility, authentication, update strategy, resource consumption, terminal behavior, and maintenance burden. Prefer one initially; do not run both continuously without a reason.

Deployment requirements:

- [ ] Run as a dedicated unprivileged user.
- [ ] Bind to loopback; do not expose the editor port directly to the public internet.
- [ ] Put it behind the Nginx gateway with HTTPS and an authentication/access-control plan.
- [ ] Keep extensions minimal on the 1-vCPU host.
- [ ] Make it independently startable/stoppable and recoverable.
- [ ] Ensure editor sessions do not own or require root access to application secrets.

**Acceptance:** Browser IDE is reachable through the intended protected URL, can open the canonical repositories, and can use the installed toolchain without requiring a public raw editor port.

**Resource note:** Browser IDE documentation may recommend more CPU/RAM than this VPS provides. Treat the documented baseline as a warning, not a guarantee. Measure real idle and active usage before adding other always-on services.

### Layer D — Gateway and sovereign infrastructure

#### Nginx and TLS

- [ ] Inventory existing domains, DNS, firewall rules, and ports before configuring.
- [ ] Install Nginx only after defining the shared reverse-proxy layout.
- [ ] Route each service by hostname or path as appropriate.
- [ ] Use TLS certificates with automated renewal.
- [ ] Keep backend/editor/service ports private on loopback or a private interface.
- [ ] Ensure proxy configuration changes are validated before reload.
- [ ] Preserve SSH access and a known-good configuration during changes.

#### Bluesky Personal Data Server (PDS)

- [ ] Review the official PDS deployment requirements and installer behavior.
- [ ] Plan DNS, domain ownership, email/identity requirements, storage, backups, and public ports.
- [ ] Integrate with the shared Nginx/TLS design rather than blindly assuming the PDS installer can own ports 80 and 443.
- [ ] Run independently with explicit resource limits and persistent data storage.
- [ ] Define backup/restore and graceful stop/start procedures.

#### OpenCloud

- [ ] Review the current official deployment model and minimum resource needs.
- [ ] Prefer a minimal deployment without optional heavyweight integrations initially.
- [ ] Integrate with the shared Nginx/TLS gateway.
- [ ] Use independent service/container boundaries and persistent data volumes.
- [ ] Define backup, restore, upgrade, and graceful shutdown procedures.

**Budget constraint:** Bluesky PDS and OpenCloud are intended to share this VPS because the budget does not currently justify separate hosts. Design them to be small and robust. If they compete for resources, they must fail gracefully rather than destabilize the Kotlin backend, SSH access, or the host.

## 5. Scheduling and resource strategy

Always-on operation is not mandatory for every service.

Explore a scheduler-controlled operating model:

- Core access and essential backend services remain available according to product needs.
- Browser IDE, OpenCloud, and other interactive services may be stopped when unused.
- Heavy or optional services may run on weekends, on demand, or during explicitly chosen windows.
- If useful, align selected workloads with NYSE trading hours, but do not assume the VPS timezone or market calendar. Use an explicit timezone and account for holidays and daylight-saving changes.
- Use systemd timers or another repository-managed scheduler. Jobs must be idempotent and observable.
- Define what happens to active sessions and background jobs before stopping a service.
- Never stop a service that is performing a write, migration, backup, or other critical operation without a safe drain/stop procedure.

Potential operating profiles to evaluate:

1. **Core:** SSH, monitoring, and essential backend only.
2. **Development:** Core plus browser IDE and coding tools.
3. **Research:** Core plus Python/Jupyter and quantum workloads.
4. **Sovereign services:** Core plus PDS and OpenCloud, subject to measured headroom.
5. **Weekend / maintenance:** optional workloads enabled for a bounded window.

Do not implement schedules until the service dependencies and safe shutdown behavior are known.

## 6. Resilience and graceful-failure requirements

Every optional service should have:

- A separate systemd unit or container boundary.
- A dedicated unprivileged identity where practical.
- Explicit memory/CPU limits where supported and tested.
- Restart behavior with backoff, not an uncontrolled restart loop.
- Health checks and useful logs.
- Persistent data stored separately from disposable application binaries.
- A documented backup/restore procedure when it owns user data.
- A safe disabled/stopped state.
- No dependency that makes SSH or the host's core management inaccessible.

The failure of code-server, Bluesky PDS, OpenCloud, Jupyter, or an experimental workload must not prevent the Kotlin backend or SSH from functioning.

Use resource budgets based on measurements. Keep deliberate headroom for the OS, SSH, package management, and emergency recovery. Do not allocate all available RAM to service limits.

## 7. Collaboration workflow: Codex + OpenCode + ChatGPT + Albert

This document is the shared mission brief for coding agents running inside the VPS.

1. Start Codex or OpenCode from the canonical dotfiles checkout or the relevant application repository.
2. Ask the agent to read this file and the relevant existing scripts, manifests, docs, and service definitions before proposing changes.
3. Keep the GitHub repository as the canonical control plane. Do not leave important changes only on the VPS.
4. Use the VPS for direct builds, runtime inspection, integration feedback, and logs. This avoids unnecessary web-first or copy/paste-only workflows.
5. Work in one coherent milestone at a time. Before implementation, present the intended changes and meaningful risks to Albert.
6. After implementation, run automated checks and produce a concise machine-readable or human-readable report.
7. Commit changes with clear messages. Do not overwrite unrelated local work or silently discard changes.
8. Report exact files changed, commands executed, checks passed/failed, resource deltas, and the next decision needed.
9. Never print or include secret values in reports, logs, commits, or prompts.
10. If an action could interrupt SSH, lock out the host, expose a private service, delete data, or materially alter the public network surface, stop and request explicit approval first.

### Preferred milestone output

Each milestone should provide:

- Objective and acceptance criteria.
- Existing repository assets reused.
- Files changed.
- One primary deployment/convergence command where practical.
- Automated validation results.
- Resource impact (CPU, RAM, disk).
- Rollback / disable command.
- Any unresolved decision for Albert.

## 8. Suggested execution order

1. [ ] Fix Catppuccin prompt colors and verify shell startup.
2. [ ] Install/configure GitHub CLI and verify repository SSH workflow.
3. [ ] Build the first Kotlin/Ktor + MongoDB Atlas service.
4. [ ] Add systemd deployment, health checks, logs, and rollback.
5. [ ] Add the browser IDE behind a protected access design.
6. [ ] Add Python 3.12 + uv + Qiskit workspace using existing Qimono assets.
7. [ ] Add Babashka and continue the Clojure workflow.
8. [ ] Configure Nginx and TLS as the shared gateway.
9. [ ] Deploy Bluesky PDS with independent lifecycle and resource controls.
10. [ ] Deploy minimal OpenCloud with independent lifecycle and resource controls.
11. [ ] Add optional service schedules and operating profiles after safe stop/start behavior is proven.
12. [ ] Review Emacs Evil mode, LayVim/LazyVim, and remaining editor ergonomics.

This order is a proposal, not permission to make every change automatically. Revisit priorities with Albert as the project evolves.

## 9. Repository assets to inspect and reuse

Before creating parallel implementations, inspect the current versions of:

- `vps-ubuntu/guix/manifest.scm`
- `vps-ubuntu/guix/channels.scm`
- `vps-ubuntu/scripts/provision-vps.sh`
- `vps-ubuntu/scripts/install-mongodb-tools.sh`
- `vps-ubuntu/scripts/install-oh-my-posh.sh`
- `vps-ubuntu/stow-source/shell/`
- `ubuntu-len-yog-AMD64/scripts/install-quantum-python.sh`
- `ubuntu-len-yog-AMD64/guix/manifests/quantum-host.scm`
- `ubuntu-len-yog-AMD64/tests/smoke-tests/hello_qiskit.py`
- `llm/clojure-proposal.md`
- `ubuntu/etc/nginx/sites-available/`

These paths are starting points. Verify they still exist and are appropriate for this VPS before reuse.

## 10. First task for the next coding session

Start with a read-only reconnaissance pass from inside the VPS:

1. Read this file and the current `vps-ubuntu/README.md`.
2. Inspect the current repository status and uncommitted changes.
3. Capture a concise baseline of CPU, RAM, disk, active services, listening ports, and installed tool versions.
4. Inspect the existing Kotlin/Ktor project location or confirm that it has not yet been created.
5. Inspect the relevant existing quantum, Clojure, Nginx, and editor assets listed above.
6. Present a proposed Kotlin/Ktor + Atlas implementation plan with files, dependencies, service lifecycle, secrets handling, validation, and rollback.
7. Wait for Albert's architectural feedback before making public network, data-destructive, or host-wide changes.

**First delivery target:** a working, locally bound Kotlin/Ktor health endpoint with a reproducible Gradle build and a clear path to MongoDB Atlas integration.

---

*Qimono principle: constraints are design inputs. Build the smallest useful system, measure it, automate it, and let optional capabilities sleep when they are not needed.*
