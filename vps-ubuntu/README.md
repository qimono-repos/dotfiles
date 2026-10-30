# vps-ubuntu

Machine pack for the **root@179.236.239.149** Ubuntu VPS: install the AI coding
CLIs with plain `curl` (no npm, no Bun) and wire both of them to the LLM
providers from **one gitignored secrets file**.

| Item | Value |
|------|-------|
| Host | `179.236.239.149` |
| OS | Ubuntu (systemd) |
| Role | Headless dev box: Codex CLI + opencode |
| Installers | `curl` only (standalone Codex, opencode install script) |
| Secrets | `~/.config/qimono/providers.env` (mode 600, never in git) |

## Quickstart (on the VPS)

```bash
# either clone the repo, or rsync this folder from your laptop:
#   rsync -av vps-ubuntu/ root@179.236.239.149:/root/vps-ubuntu/
cd ~/dotfiles/vps-ubuntu
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

Then fill in keys and re-run only the wiring:

```bash
$EDITOR ~/.config/qimono/providers.env
./scripts/configure-llm.sh
exec bash          # or open a new SSH session
codex
opencode
```

`bootstrap.sh` is idempotent: re-running upgrades/probes rather than
re-downloading. `--dry-run` prints the plan and changes nothing.

## Layout

```
vps-ubuntu/
  README.md
  scripts/
    bootstrap.sh        # prereqs -> codex -> opencode -> configure -> status
    install-codex.sh    # curl https://chatgpt.com/codex/install.sh
    install-opencode.sh # curl https://opencode.ai/install
    configure-llm.sh    # providers.env -> config.toml + opencode.json + shell
    status.sh           # read-only expected-vs-actual probe
  llm/
    providers.env.example
  QA/
    Checklist.md
```

## What gets installed where

| Tool | Command | Binary | Config |
|------|---------|--------|--------|
| Codex CLI | `curl -fsSL https://chatgpt.com/codex/install.sh \| sh` | `~/.local/bin/codex` | `~/.codex/config.toml` |
| opencode | `curl -fsSL https://opencode.ai/install \| bash` | `~/.opencode/bin/opencode` | `~/.config/opencode/opencode.json` |

`install-codex.sh` falls back to
`https://github.com/openai/codex/releases/latest/download/install.sh` if
`chatgpt.com` is unreachable. Both installers add their bin dir to your shell;
`configure-llm.sh` also writes one guarded PATH + env block to `~/.bashrc`,
`~/.profile`, and `~/.zshrc` (when present), so non-interactive shells behave.

## Provider wiring

Keys go in `~/.config/qimono/providers.env` (created from
[`llm/providers.env.example`](./llm/providers.env.example)). The generated
configs reference the variables — they never contain the raw keys.

| Env var | opencode provider | Codex |
|---------|-------------------|-------|
| `OPENAI_API_KEY` | `openai` | built-in `openai` (`forced_login_method = "api"`) |
| `ANTHROPIC_API_KEY` | `anthropic` | — (not a Codex provider) |
| `OPENROUTER_API_KEY` | `openrouter` | `[model_providers.openrouter]` |
| `GOOGLE_GENERATIVE_AI_API_KEY` | `google` | — |
| `OLLAMA_BASE_URL` | `ollama` | `[model_providers.qimono_ollama]` |
| `CUSTOM_BASE_URL` | `custom` | `[model_providers.custom]` |

Codex provider auto-selection priority (override with `CODEX_PROVIDER`):
`custom` → `openrouter` → `qimono_ollama` → `openai`.

Choose defaults with `--codex-model`, `--opencode-model`, or the
`CODEX_MODEL` / `OPENCODE_MODEL` vars.

### Notes / gotchas

- **Codex custom providers must speak the Responses API.** Current Codex only
  supports `wire_api = "responses"`; plain chat-completions-only endpoints may
  not work. OpenAI, and OpenAI-compatible routers that expose `/responses`, are
  the safe choices.
- **Ollama is a reserved id** in Codex (`openai`, `ollama`, `lmstudio` cannot be
  overridden), hence the `qimono_ollama` id for a custom/remote URL.
- opencode's `/connect` still works for interactive OAuth; the config wiring
  here is for headless/API-key use.
- Re-running `configure-llm.sh` regenerates `~/.codex/config.toml` (a
  non-managed existing file is backed up once). It **merges** into
  `opencode.json` and keeps other keys such as `mcp`.

## Security

- The repo is public. Only `providers.env.example` is committed.
- `providers.env` is gitignored and forced to mode `600`.
- `status.sh` prints env-var **names** only, never values.
- Prefer per-provider keys with minimal spend limits on a VPS.

## Manual, step by step

```bash
./scripts/install-codex.sh [--dry-run] [--force] [--version X]
./scripts/install-opencode.sh [--dry-run] [--force] [--version X]
./scripts/configure-llm.sh [--dry-run] [--env-file PATH]
./scripts/status.sh
```
