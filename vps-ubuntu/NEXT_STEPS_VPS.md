# Qimono VPS — Next Steps and Collaborative Build Plan

**Status:** Execution record updated 2026-10-30
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
| Guix profile | 28 packages, including Git, Neovim, Gradle, tmux, Stow, jq, yq, ripgrep, `gh`, `bb`, and `uv` |
| Shell | Zsh 5.9, configured as login shell |
| Dotfiles | VPS-native Stow package applied from this repository |
| Oh My Posh | 31.9.1 installed; Catppuccin Mocha theme managed by Stow |
| MongoDB tooling | Atlas CLI 1.59.4 installed; no local MongoDB server; mongosh intentionally omitted |
| Coding agents | Codex CLI 0.166.0 and OpenCode 1.19.5; user confirmed both launch |
| GitHub CLI | Guix profile has gh 2.83.2; no GitHub authentication configured |
| Kotlin/Ktor application | Deployed as loopback-only systemd service; health succeeds, Atlas readiness awaits URI |
| Nginx / TLS | Not provisioned; domain currently resolves to a different IPv4 |
| Browser IDE | code-server 4.144.0 active on loopback port 13337; password auth, SSH tunnel access, disabled at boot |
| Bluesky PDS / OpenCloud | Not deployed; public domain/gateway and data decisions remain |

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

- [x] Refine the existing Oh My Posh theme into a Catppuccin Mocha palette in the VPS Stow package.
- [x] Verify Zsh startup, PATH ordering, Guix profile activation, and prompt initialization.
- [x] Install GitHub CLI (`gh`) from Guix and configure SSH protocol/editor. **Pending:** interactive `gh auth login`; no GitHub identity is authenticated yet.
- [x] Review existing editor configuration and add a minimal, repo-managed Neovim setup.
- [x] Configure Emacs with Evil mode; package and batch startup verified.
- [x] Configure and parse-check repo-managed tmux settings.
- [x] Install Babashka (`bb`) and run the repository smoke script.

**Acceptance:** A new SSH login gives the managed shell; `gh`, `bb`, tmux and selected editors work; configuration is reproducible from Stow and scripts. Tooling is verified; `gh` still needs interactive account authentication before private GitHub operations.

### Layer B — Application development

**Goal:** Deliver the first useful Qimono backend.

#### Kotlin + Ktor + MongoDB Atlas

- [x] Connect the existing `the-porketo` backend workspace.
- [x] Use Java 21 and add a Gradle wrapper; pin the existing Kotlin/Ktor dependencies.
- [x] Implement Ktor routing, environment configuration, structured logs, `/health`, and `/ready`.
- [ ] Connect to MongoDB Atlas using environment configuration. **Blocked:** production `MONGODB_URI` is not present; `/ready` correctly returns 503 until configured.
- [x] Separate local development configuration from the root-owned production environment file.
- [x] Create a dedicated unprivileged service account and bounded systemd unit.
- [x] Add build, deploy, health-check, log-inspection, stop, and rollback commands.
- [x] Keep the service bound to loopback pending a gateway decision.

**Acceptance:** One documented command builds and deploys the service; the health endpoint responds; Atlas connectivity is verified without exposing secrets; a failed deployment leaves the previous working version recoverable.

#### Python + quantum workspace

- [x] Use Python 3.12 in the scientific environment.
- [x] Use Guix + uv and the existing Qimono quantum assets.
- [x] Set up the project-local Qiskit, Qiskit Aer, PennyLane, and ipykernel environment.
- [x] Reuse and pass the Qiskit smoke test and register the `quantum` kernel.
- [ ] Keep Jupyter bound to loopback and expose it only through an authenticated access path if needed.
- [ ] Avoid installing large scientific stacks into the global Guix profile unless there is a clear reason.

**Acceptance:** A reproducible quantum workspace runs the existing Qiskit smoke test and can register its own Jupyter kernel.

#### Clojure / Babashka

- [x] Review `llm/clojure-proposal.md` and the existing Babashka direction. It proposes a learning-oriented Gemma port; implementation remains optional and Python stays authoritative until parity work is explicitly continued.
- [x] Install Babashka in the managed Guix profile.
- [x] Validate the repository script workflow.
- [ ] If continuing the Gemma harness port, preserve the Python implementation as the reference until parity tests pass.

**Acceptance:** `bb` is available to the target user and a small repository-owned smoke task succeeds.

### Layer C — Browser-based development

**Goal:** Access the VPS development environment through a browser from local computers and mobile devices.

Evaluate these alternatives before committing:

- **code-server:** self-hosted VS Code-like experience, using Open VSX by default.
- **OpenVSCode Server:** alternative closer to upstream VS Code distribution.

Compare extension compatibility, authentication, update strategy, resource consumption, terminal behavior, and maintenance burden. Prefer one initially; do not run both continuously without a reason.

Deployment requirements:

- [x] Prepare a pinned installer for a dedicated unprivileged code-server user.
- [x] Installer is designed for loopback binding and no raw public port.
- [x] Use password auth over SSH local forwarding while the public HTTPS route is blocked pending DNS alignment and gateway choice.
- [x] Keep extensions minimal on the 1-vCPU host.
- [x] Make it independently startable/stoppable; installer leaves it disabled at boot.
- [x] Keep editor identity separate from root and application secrets.

**Acceptance:** Browser IDE is reachable through the protected SSH-tunnel URL, opens separate service-user copies of both canonical repositories, and has the Guix toolchain without root or API secrets. A public HTTPS hostname remains future work.

**Resource note:** Idle code-server measured about 60 MiB in its systemd cgroup (about 86 MiB process RSS). After provisioning, the host had about 2.9 GiB available RAM and 32 GiB free disk. Browser IDE documentation may recommend more CPU/RAM than this VPS provides; measure again under active editing before adding always-on services.

### Layer D — Gateway and sovereign infrastructure

#### Nginx and TLS

- [x] Inventory existing domains, DNS, firewall rules, and ports. `qimono.vip` resolves to `194.195.126.37`, not the VPS IPv4 `179.236.239.149`; UFW is inactive; listeners were limited to SSH and loopback services.
- [ ] Install Nginx only after defining the shared reverse-proxy layout. **Blocked:** `qimono.vip` resolves to `194.195.126.37`; the VPS public IPv4 is `179.236.239.149`.
- [ ] Route each service by hostname or path as appropriate.
- [ ] Use TLS certificates with automated renewal.
- [ ] Keep backend/editor/service ports private on loopback or a private interface.
- [ ] Ensure proxy configuration changes are validated before reload.
- [ ] Preserve SSH access and a known-good configuration during changes.

#### Bluesky Personal Data Server (PDS)

- [x] Review the official PDS deployment requirements and installer behavior.
- [ ] Plan DNS, domain ownership, email/identity requirements, storage, backups, and public ports. The current official installer supports Ubuntu 20.04/22.04/24.04 and Debian 11–13, not Ubuntu 26.04, and assumes it can own ports 80/443; see [official installer](https://github.com/bluesky-social/pds/blob/main/installer.sh) and [deployment guide](https://github.com/bluesky-social/pds#installing-on-ubuntu-200422042404-and-debian-111213).
- [ ] Integrate with the shared Nginx/TLS design rather than blindly assuming the PDS installer can own ports 80 and 443.
- [ ] Run independently with explicit resource limits and persistent data storage.
- [ ] Define backup/restore and graceful stop/start procedures.

#### OpenCloud

- [x] Review the current official deployment model and minimum resource needs.
- [ ] Prefer a minimal deployment without optional heavyweight integrations initially. Official minimum for up to 10 users is 1 GHz single core and 512 MB RAM, but required storage depends on user data; see [OpenCloud requirements](https://docs.opencloud.eu/docs/admin/getting-started/requirements/). Disk capacity and backup retention still need a decision.
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

1. [x] Fix Catppuccin prompt colors and verify shell startup.
2. [ ] Install/configure GitHub CLI and verify repository SSH workflow (**interactive auth remains**).
3. [x] Build and deploy the Ktor service; Atlas connectivity is pending its production URI.
4. [x] Add systemd deployment, health checks, logs, and rollback.
5. [x] Start the protected browser IDE with SSH forwarding; public HTTPS remains pending DNS/gateway.
6. [x] Add Python 3.12 + uv + Qiskit workspace using existing Qimono assets.
7. [x] Add Babashka and validate its script workflow.
8. [ ] Configure Nginx/TLS after DNS points at this VPS and public exposure policy is settled.
9. [ ] Deploy Bluesky PDS after the supported-OS path, domain, email, storage, and proxy integration are resolved.
10. [ ] Deploy minimal OpenCloud after storage, backup/restore, and gateway details are settled.
11. [ ] Add optional service schedules after safe stop/start behavior and service needs are proven.
12. [x] Review Emacs Evil and add a minimal Neovim setup; revisit ergonomics after browser IDE use.

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
