# Journal — P3 / P4 / P5 (continue next week)

**Repo:** `dotfiles`  
**Pack focus:** `ubuntu-len-yog-AMD64`  
**Constraint:** AI credit may end mid-run → small chunks, log everything here.  
**Note:** No physical SD card in the Yoga as of this journal; P5 is tutorial + scripts only.

---

## How to resume (next credit window)

1. Read this file top-to-bottom.  
2. Open `ubuntu-len-yog-AMD64/tasks-priority-plan.md`.  
3. Pick the first row still `[ ]` under **Pending next week**.  
4. After each chunk: append a **Session log** line here.

```bash
cd ~/source/repos/qimono-repos/dotfiles
less JOURNAL-P3-P5.md
```

---

## Chunk map + status

### P3 — tooling & quantum-host

| Chunk | ID | Deliverable | Status |
|-------|-----|-------------|--------|
| P3.1 | T22a | `quantum-host*.scm` + `profile-full.scm` | `[x]` |
| P3.2 | T22b | `docs/quantum-host-dotnet-rust.md` | `[x]` |
| P3.3 | T23 | `docs/editors-codeium-vscodium.md` | `[x]` |
| P3.4 | T24 | `docs/kde-connect.md` + `guix install kdeconnect` | `[x]` installed |
| P3.5 | T25 | `uv add jupyterlab` in quantum-workspace | `[x]` 4.6.2 |
| P3.6 | T26 | `docs/diagrams-and-math.md` | `[x]` (graphviz install deferred) |

### P4 — browsers & host experiments

| Chunk | ID | Deliverable | Status |
|-------|-----|-------------|--------|
| P4.1 | T27a | `docs/browsers-guix-vs-snap.md` research | `[x]` |
| P4.2 | T27b | Guix `epiphany` (Web 48.0) | `[x]` |
| P4.3 | T28 | Remove browser snaps | `[~]` **needs sudo** — only epiphany snap planned first |
| P4.4 | T29 | Podman autostart docs + sample unit | `[x]` |
| P4.5 | T30 | Nomad user without SD | `[~]` docs only; no card |

### P5 — portable SD workflow

| Chunk | ID | Deliverable | Status |
|-------|-----|-------------|--------|
| P5.1 | T31 | `SD-CARD-README.md` | `[x]` |
| P5.2 | T32 | `scripts/machine-discovery.sh` | `[x]` ran OK on Yoga |
| P5.3 | T33 | Linked from journal / task plan | `[x]` |

---

## Pending next week (priority order)

1. ~~snap remove epiphany/vivaldi~~ **done by user**. Keep **firefox** snap until Guix Firefox/Chromium OK.  
2. **`guix install ungoogled-chromium`** — large; free RAM first; additive `guix install` not bare `-m`.  
3. **Firefox via nonguix** — `guix pull` with channels, then `guix search firefox`.  
4. **Locale for KDE Connect** — Qt warned about non-UTF8; ensure `GUIX_LOCPATH` + `en_US.UTF-8` in shell (stow already sources locales path when present).  
5. **Optional `guix install graphviz plantuml`** and/or draw.io desktop.  
6. **Guix fixed-output package for .NET SDK tarball** (creative Strategy E).  
7. **Nix install experiment** (`guix install nix`) for .NET escape hatch.  
8. **LazyVim real tree** into `stow-source/nvim`.  
9. **Canonical emacs init** into `stow-source/emacs`.  
10. **Physical SD** → follow `SD-CARD-README.md`; create `qimono-nomad` uid 2000; run `machine-discovery.sh` on target.  
11. **Vega MCP** sample `mcp.json` from Amazon docs.  
12. **Never use slim `-m` alone** — always `profile-full.scm` or `guix install`.

---

## Lessons learned this session

### `guix package -m` replaces the profile

Running `guix package -m quantum-host-rust.scm` **removed** emacs, uv, stow, python, etc.  
**Recovery:** `guix package -m profile-full.scm` then `guix install kdeconnect epiphany`.

Always prefer:

```bash
guix install extra-pkg          # additive
# or
guix package -m guix/manifests/profile-full.scm   # full desired set
guix package --roll-back        # if disaster
```

### Snap removal needs interactive sudo

Agent could not complete `snap remove` without password. User command:

```bash
sudo snap remove epiphany
# later, only if Guix browsers cover you:
# sudo snap remove firefox
```

---

## Session log

| 2026-08-03 | browsers | epiphany needs userns sysctl=0; firefox via nonguix substitutes.nonguix.org + archive --authorize; see docs/guix-browsers-foreign-distro.md |
| When | Chunks | Notes |
|------|--------|-------|
| 2026-08-03 | journal created | P3 start |
| 2026-08-03 | P3.1–P3.6 | docs + rust + jupyter + kdeconnect |
| 2026-08-03 | P4.1–P4.2, P4.4 | epiphany Guix; podman samples |
| 2026-08-03 | P5.1–P5.3 | SD-CARD-README + machine-discovery |
| 2026-08-03 | incident | rust-only `-m` wiped profile → restored profile-full |

| 2026-08-03 | snaps + policy | User removed snap epiphany+vivaldi; firefox snap remains. Prefer profile-full.scm; last resort installing-daily-use-apps.sh |

---

## Current Guix profile intent (after restore)

`profile-full.scm` packages + additive:

- neovim, emacs, git, ripgrep, fd, fzf, tree, htop, openjdk  
- stow, python, uv, glibc-locales, openssl, zlib, pkg-config  
- rust + rust:cargo  
- kdeconnect, epiphany  

Verify:

```bash
source ~/.guix-profile/etc/profile
guix package -I
rustc --version
uv --version
epiphany --version
kdeconnect-cli -l
```

---

## Artifacts index

| Path | Chunk |
|------|-------|
| `JOURNAL-P3-P5.md` | this file |
| `SD-CARD-README.md` | P5.1 |
| `ubuntu-len-yog-AMD64/scripts/machine-discovery.sh` | P5.2 |
| `ubuntu-len-yog-AMD64/guix/manifests/quantum-host.scm` | P3.1 |
| `ubuntu-len-yog-AMD64/guix/manifests/quantum-host-rust.scm` | P3.1 |
| `ubuntu-len-yog-AMD64/guix/manifests/quantum-host-native.scm` | P3.1 |
| `ubuntu-len-yog-AMD64/guix/manifests/profile-full.scm` | P3.1 recovery |
| `ubuntu-len-yog-AMD64/docs/quantum-host-dotnet-rust.md` | P3.2 |
| `ubuntu-len-yog-AMD64/docs/editors-codeium-vscodium.md` | P3.3 |
| `ubuntu-len-yog-AMD64/docs/kde-connect.md` | P3.4 |
| `ubuntu-len-yog-AMD64/docs/diagrams-and-math.md` | P3.6 |
| `ubuntu-len-yog-AMD64/docs/browsers-guix-vs-snap.md` | P4.1 |
| `ubuntu-len-yog-AMD64/docs/podman-autostart.md` | P4.4 |
| `ubuntu-len-yog-AMD64/stow-source/podman/` | P4.4 sample |

| 2026-08-03 | LESSONS browsers | Encoded: PATH current guix, userns, nonguix key+substitutes, no source build, first-try scripts |
| 2026-08-03 | userns reboot trap | After reboot Epiphany died again: only runtime `sysctl -w` had been applied. Pack already had `host-sysctl/99-guix-userns.conf` but **not installed** to `/etc`. Root cause detail: AppArmor allows `/usr/bin/bwrap`, not Guix store bwrap. Added `scripts/install-host-sysctl.sh` on **Yoga + HP Pro**; Yoga `bootstrap.sh` step 0; docs/AGENTS/MACHINE updated. **User must run** `./scripts/install-host-sysctl.sh` once on this host (and on ProBook). |
| 2026-08-03 | QA framework | **Human + AI QA** per use case: `ubuntu-hp-pro/QA/` and `ubuntu-len-yog-AMD64/QA/` (not repo-root). Checklists agent/user + Day1; reboot R1/R2 mandatory. Celebrate error → process. |
| 2026-08-21 | **P6.1 local LLM stack** | Black-hole fix: fleet had Ollama on machines but **no recorded model choice** anywhere. Fleet standard set: **Ollama + `gemma4:e2b`**. New shared topic dir `dotfiles/llm/`: idempotent `install-ollama-stack.sh` (`--dry-run`/`--smoke`, expected-vs-actual probe, RAM/disk preflight), `hello-llm.sh` smoke test (JSON API, no CLI spinner noise), `docs/local-llm.md` (sizing + measurements), `gemma4-report.md` moved in from `~/gemma-report.md`. Wired: windows11 `install-ollama.ps1` pulls model + smoke; mini-pc `status.sh` LLM probe section; hp-pro + Yoga README pointers. Measured on Yoga: PASS ~26–29 tok/s CPU with Chrome closed (~19 s load); **OOM-kill lesson**: loading with Chrome open (~<3 GiB avail) gets the loader kernel-OOM-killed → installer warns under 3 GiB. Bonus discovery: Ollama sees Radeon 760M via Vulkan, dropped by default — `OLLAMA_IGPU_ENABLE=1` experiment pending. AGENTS/MACHINE/READMEs updated. Not committed yet. |
|---|---|---|
| 2026-08-22 | **P6.2 Yoga→hp-pro parity port** | Full port of the flagship pack onto HP ProBook 440 G9 (i7-1255U, **30 GiB RAM** — roomiest node; MACHINE.md captured). Manifest extended to full parity (24 pkgs incl. rust+cargo/kdeconnect/flatpak/vscodium-fixed) and applied live; stow wired properly (stow now Guix-installed); shell guards ported+verified (22-uv-python refusal policy, 25-ssh-agent gcr pin, 35-flatpak FLATPAK_BWRAP); environment.d absolute XDG_DATA_DIRS; Ghostty flatpak installed + D-Bus activation verified via gtk-launch scope test; TTY font pack staged (`sudo ./scripts/install-vconsole.sh` pending). Fixed live defects: `.zshrc.local` double-source, `.zprofile` literal `$MARKER`, jupyter unit CHDIR (missing quantum-workspace dir → created; now active on :5005). LLM sizing table corrected (hp-pro was marked "tight" pre-capture). **New traps:** tool-session SIGKILL mid-substitute corrupts /gnu/store items ("mkdir File exists" + "corrupt input") — retry loop clears one per attempt, run guix transactions detached; this box's curl has NO default CA bundle — always export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt (flatpak remote-add hangs without it). Plan of record: `ubuntu-hp-pro/agent-plan.json`. Human handoff: ollama service unit missing (binary-only install) → create+enable pointing OLLAMA_MODELS=/home/qi/.ollama/models (model **already pulled + smoke PASS**: load 21 s, 4.3 tok/s on the U-class chip); vconsole font; SSH/Tailscale onboarding; hostname rename decision (collides with Yoga's qimono-localhost); reboot R1/R2 QA. Committed 1216844. |
| 2026-08-27 | **P6.3 NEW ARM64 pack: `ubuntu-len-yog-ARM64`** | Bootstrapped the **Snapdragon X Elite Yoga Slim 7 14Q8X9** (aarch64, `qi-yoga-ubu-rr-lts`, 30 GiB RAM, Ubuntu 26.04.1) from bare metal — the planned ARM64 sibling pack. **Guix binary install (1.5.0 aarch64):** verified tarball signature (Efraim Flashner key A28B…); **trap — the aarch64 tarball does NOT ship `/usr/local/bin/guix`** (guix lives at `/var/guix/profiles/per-user/root/current-guix/bin/guix`), nor a systemd unit, nor auto-authorized keys → wrote `install-guix-binary.sh` + `finish-guix-binary.sh` (symlink + authorize bordeaux/ci/berlin keys + `guix-daemon.service`). **ARM64 trap — `guix jupyter` package is not aarch64-supported** → JupyterLab comes via uv in the workspace (docs/jupyter-arm64.md). **Wheel trap — scipy-openblas/numpy dlopen libz.so.1 → ImportError with Guix python; adding host /lib/aarch64-linux-gnu to LD_LIBRARY_PATH SEGFAULTS the Guix python** → added `zlib` to manifest and export `LD_LIBRARY_PATH=$GUIX_PROFILE/lib` in 20-uv-python.zsh (safe). Base manifest applied (16 pkgs: editor/CLI/uv/python/stow/glibc-locales/kdeconnect/zlib). Stow applied (shell, guix-env, quantum, nvim, jupyter); fixed `.ssh/config` to this box's actual key `id_ed25519_git_repos` (auths as qimono-repos). Quantum workspace: uv + **qiskit 2.5.2 / pennylane 0.45.1 / qiskit-aer 0.17.2 / qdk**; smoke-tests run-all **ALL OK**. JupyterLab user service enabled+running on **127.0.0.1:5005**. bwrap-userns sysctl still needs sudo (value=1). |
| 2026-10-16 | **P6.4 mini-pc Python 3.11 → 3.12 (apply the policy commits)** | The 2026-10-16 commits set `python@3.12` in every manifest + docs but the **live mini-pc profile was never re-applied** (still `python 3.11.14`), so PROXORA (`requires-python = ">=3.12"`) could only run inside a per-project `guix shell`. Applied `profile-full.scm` **detached** (`setsid nohup … > /tmp/guix-profile-apply.log`, per the hp-pro SIGKILL lesson) → **generation 7**: python 3.12.12, uv 0.10.12, gcc-toolchain 16.2.0, openssl 3.5.7, flatpak 1.16.6 (~540 MB substitutions, no builds). **Two traps found:** (1) **`GUIX_PROFILE` clobber** — `~/.zshrc`'s installer block exports `GUIX_PROFILE=$HOME/.config/guix/current` *before* `~/.guix-profile/etc/profile` is sourced; that snippet prepends `${GUIX_PROFILE}/bin`, so the pull-profile bin was prepended and `~/.guix-profile/bin` (python3/uv/stow) **never reached PATH** → `python3` was host `/usr/bin/python3` 3.14 and `status.sh` stayed red. Fixed by pinning `GUIX_PROFILE=$HOME/.guix-profile` in `10-guix.zsh`. (2) **manifest incompleteness** — `blender` + `bat` were installed but unlisted, so a bare `-m` would have deleted them; both added. Also fixed **`40-oh-my-posh.zsh`**: it re-prepended `~/.local/bin` (to find the prompt binary) *after* 10-guix, silently shadowing Guix `uv` with host `~/.local/bin/uv`; now appends. Verified: `python3` 3.12.12, `uv` 0.10.12 (Guix), PROXORA `uv sync --frozen` + `uv run` OK, `status.sh` green. **Fleet drift remains:** hp-pro + AMD64 `10-guix.zsh` share the `${GUIX_PROFILE:-…}` pattern and hp-pro `40-oh-my-posh.zsh` shares the prepend bug — port pending. **Pre-existing/unsolved:** `quantum-workspace` dir missing → `qimono-jupyter.service` fails CHDIR (same trap as hp-pro P6.2). |
| 2026-10-16 | **P6.5 fleet Guix wheel shim (PROXORA `libz.so.1` ImportError)** | PROXORA (`proxora/python`) died on `import numpy` with `libz.so.1: cannot open shared object file`. **Root cause:** the venv interpreter is Guix CPython, whose `ld.so` searches only the Guix store (not `/usr/lib/x86_64-linux-gnu`); manylinux wheels strip RPATH and `dlopen` `libz`/`libstdc++` by soname. Host `ldd` resolves it (host loader) — misleading. **Fix generalised to the fleet:** promoted the shim to the dotfiles repo root — `scripts/sitecustomize-guix-native.py` (moved from `ubuntu-mini-pc/scripts/`) — and added `scripts/install-guix-wheel-shim.sh` (fleet-standard ok/bad/warn/plan, `--dry-run`/`--help`, idempotent, `TARGET` = venv/project/site-packages, backs up a differing `sitecustomize.py`, best-effort verifies `import numpy`). `ubuntu-mini-pc/scripts/install-quantum-python.sh` now calls it; docs (`quantum.md`, `python-path.md`) updated. Reference added to `proxora/python/README.md`. Proven: removed shim → reproduce ImportError → run helper → numpy imports. **Note:** ARM64 uses the `LD_LIBRARY_PATH=$GUIX_PROFILE/lib` approach instead (port to the helper optional). |
| 2026-10-16 | **P6.6 static-TLS: `cannot allocate memory in static TLS block`** | After the P6.5 shim, the fresh `quantum-workspace` venv (created by `install-quantum-python.sh`, which had been dead since the dir was missing → `qimono-jupyter.service` status=200/CHDIR) failed on `import scipy`/qiskit with `…_accelerate.abi3.so: cannot allocate memory in static TLS block`. **Diagnosis (isolated empirically over all 2²⁴ soname subsets):** the shim *was* involved for qiskit but not solely — SciPy and Qiskit-Aer `dlopen` `libgomp` after start-up, which claims initial-exec TLS from glibc's static-TLS surplus; qiskit **2.6**'s Rust `_accelerate` (2.5.2 in PROXORA was fine) is the one that then overflows. Dropping `libgomp` from the preload list only moved the failure onto Aer; `LD_PRELOAD` of the Guix libs failed too; **setting `GLIBC_TUNABLES` from inside `sitecustomize.py` cannot work** — glibc parses tunables in ld.so before `site` runs (proved by test A). **Fix:** the shim now re-execs the interpreter once with `glibc.rtld.optional_static_tls=65536` (guarded by a `QIMONO_STATIC_TLS` sentinel, skipped when already present, `sys.orig_argv` replayed via `execve`). Tunable is Ubuntu-safe (glibc 2.44, no warnings, `ls`/`date`/`grep` unaffected). Helper's verify now imports the full stack (5/5: numpy, scipy, matplotlib, qiskit, qiskit-aer). **Verified:** workspace venv + `uv run` + PROXORA + a live `Python (quantum)` kernel driven through `jupyter_client` → `KERNEL-OK qiskit 2.6.0 aer 0.17.2`. Jupyter itself revived by `mkdir` on `~/source/repos/qimono-repos/quantum-workspace` then `systemctl --user restart qimono-jupyter.service` (127.0.0.1:5005). |
| 2026-10-16 | **P6.7 the PROXORA `libz.so.1` failure kept recurring → make the shim durable** | Investigated why PROXORA (`proxora/python`) broke again after P6.5/P6.6. **Root cause of the recurrence:** the shim lived as an untracked `sitecustomize.py` inside `.venv/site-packages`, so *any* venv rebuild (`uv venv --clear`, fresh clone) silently deleted it — and the helper's own `import numpy` check was **fooled** because it verified with `LD_LIBRARY_PATH=$GUIX_PROFILE/lib`, which lets the import succeed *without* the shim (false confidence). Reproduced in a throwaway clone: fresh `uv sync` → no shim → `Original error was: libz.so.1: cannot open shared object file`. **Fix (smallest, uv-native, no 2nd package manager):** ship the shim **inside the project's own wheel** — `uv_build` allows only one top-level module, but the PEP 427 wheel-data `purelib` scheme does not, so `proxora/python/pyproject.toml` gained `[tool.uv.build-backend.data] purelib = "shim"` with the file at `python/shim/sitecustomize.py`. `uv sync` now reinstalls `site-packages/sitecustomize.py` every time — proven in **both editable (uv default) and non-editable** modes, and across `uv venv --clear`. Also made the canonical dotfiles shim a **true no-op when `~/.guix-profile/lib` is absent** (no re-exec, no preload) so it is safe to publish in a package. Added `proxora/python/scripts/verify-env.sh` (imports numpy/scipy/qiskit/qiskit_aer in the project interpreter; `--recreate` = `uv venv --clear && uv sync` first) and rewrote the README root-cause section. **Proof:** positive = `uv sync` installs shim → 4/4 OK; negative control (data mapping removed) → no shim → exact historical error. Commits: dotfiles `51c7f76`, proxora `5cfdff5`. **Remaining:** `uv sync --no-install-project` skips the shim; proxora's shim mirrors the dotfiles canonical (kept byte-identical); fleet `uv` 0.10.12 vs `build-system` pin `uv_build>=0.12,<0.13`. |


