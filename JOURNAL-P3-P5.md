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
