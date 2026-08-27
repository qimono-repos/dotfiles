# qimono fleet bootstrap — `curl -fsSL https://qimono.online/install | sh`

One URL to take a **brand-new machine** from nothing to a working Qimono dev box,
no package manager or git setup required (the "chicken-and-egg" solver).

## Entrypoints

| Platform | Command | Dispatches to |
|----------|---------|---------------|
| Linux (Ubuntu) | `curl -fsSL https://qimono.online/install \| sh` | `fleet/guix.sh` |
| macOS | `curl -fsSL https://qimono.online/install \| sh` | `fleet/brew.sh` |
| Windows (no WSL) | `irm https://qimono.online/install.ps1 \| iex` | `fleet/winget.ps1` |

**Raw URLs before DNS is wired** (same files, served by GitHub):

  https://raw.githubusercontent.com/qimono-repos/dotfiles/main/fleet/install
  https://raw.githubusercontent.com/qimono-repos/dotfiles/main/fleet/install.ps1

The bash entrypoint self-fetches the whole `fleet/` kit (via the repo tarball) to
`~/.qimono/fleet` and runs the per-OS bootstrap — so the kit is on-disk for
inspection and reruns.

## Why it solves the chicken-and-egg

A fresh machine has **no** package manager, **no** git, **no** dotfiles. The
bootstrap installs only the minimum needed to fetch the dotfiles repo, then
hands off — the heavy lifting stays in the existing per-pack scripts:

1. **Linux:** `apt`-installs `curl git zsh tar` → clones the **public** repo over
   HTTPS (no auth) → detects the pack → **Guix-first** binary install (sudo) →
   runs the pack's `bootstrap.sh`.
2. **macOS:** ensures Xcode CLT → installs **Homebrew** (`NONINTERACTIVE=1`) →
   `brew bundle` → clones repo.
3. **Windows:** ensures winget → `winget import` → clones repo — *no WSL,
   full PowerShell*.

Because the repo is **public**, no SSH key / token is needed to fetch it. The
`.ssh/config` key is only used *after* bootstrap, for pushes.

## Rules / invariants

- **Public repo by design.** The bootstrap always clones over HTTPS. Keep
  secrets out of the public tree; keys live under `~/repos/.../.ssh` in
  private storage, not this repo.
- **Thin entrypoints, reuse the packs.** `fleet/` never duplicates pack
  scripts (`install-guix-binary.sh`, `finish-guix-binary.sh`,
  `bootstrap.sh`, `stow-apply.sh`); it only fetches and orchestrates.
- **Idempotent.** Safe to re-run anywhere; nothing is force-clobbered.
- **Per-OS manager:** Linux → Guix-first; macOS → Homebrew; Windows → winget.

## Files

| File | Role |
|------|------|
| `install` | bash `curl\|sh` entrypoint (Linux + macOS dispatch) |
| `install.ps1` | PowerShell `irm\|iex` entrypoint (Windows) |
| `guix.sh` | Linux/Ubuntu: apt prereqs → clone → Guix-first → pack bootstrap |
| `brew.sh` | macOS: Xcode CLT → Homebrew → `brew bundle` → clone+stow |
| `winget.ps1` | Windows: execpolicy → winget import → clone |
| `Brewfile` | macOS Homebrew manifest |
| `winget.json` | Windows winget import manifest |
| `QA/` | per-OS checklists (Human + AI) |

## Test locally before pushing

```bash
# Dry-run the bash entrypoint without touching the system:
bash fleet/install -- --dry-run     # fetches kit to ~/.qimono/fleet, prints plan

# Syntax checks
bash -n fleet/install fleet/guix.sh fleet/brew.sh
# PowerShell (if available):
#   pwsh -Command " [System.Management.Automation.Language.Parser]::ParseFile('fleet/install.ps1',[ref]$null,[ref]$null)"
```

## DNS/redirect setup (registrar side — you apply this, I can't touch it)

For `qimono.online/install` and `qimono.online/install.ps1` to work, add a
redirect from the apex (or `www`) to GitHub. Two options:

**Option A — GitHub Pages (recommended):** point `qimono.online` at Pages.
```text
qimono.online.  CNAME  qimono-repos.github.io
```
Then create a `gh-pages` branch (or Pages from `main`) whose root has `install`
and `install.ps1` — or put GitHub Pages behind the repo with a
`_redirects`/301 to `raw.githubusercontent.com`. Apex CNAME requires your
registrar to support **CNAME flattening / ALIAS** (most do; otherwise use `www`).

**Option B — raw redirect:** some registrars let you URL-forward
`qimono.online/install` → the raw GitHub URL above. Simpler, but depends on the
registrar's forwarder (often a 302 frame/page).

**Caveat:** `raw.githubusercontent.com` serves `Content-Type: text/plain`, so a
bare `curl | sh` works, but a browser hitting `/install` will show text unless
you wrap it in Pages (which lets you set the right headers) — hence Option A is
cleanest for a "branded" installer.

After wiring DNS, verify:
```bash
curl -fsSL https://qimono.online/install | head -5   # should show the script
```
