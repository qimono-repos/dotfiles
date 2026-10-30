# vps-ubuntu QA checklist

Run on `root@179.236.239.149` unless noted.

## Install

- [ ] `bash -n scripts/*.sh` — all scripts parse
- [ ] `./scripts/bootstrap.sh --dry-run` — prints plan, changes nothing
- [ ] `./scripts/bootstrap.sh` — completes without `MISS`
- [ ] `codex --version` and `opencode --version` — both resolve
- [ ] `exec bash` then `command -v codex opencode` — both on PATH

## Secrets

- [ ] `stat -c '%a' ~/.config/qimono/providers.env` — `600`
- [ ] `git status` in the repo — `providers.env` never staged
- [ ] `grep -R "sk-" .` in repo — no keys leaked
- [ ] `./scripts/status.sh` — prints var names only, no values

## Provider wiring

- [ ] `~/.codex/config.toml` exists and starts with the managed header
- [ ] `~/.config/opencode/opencode.json` valid JSON:
      `python3 -m json.tool ~/.config/opencode/opencode.json`
- [ ] Re-running `./scripts/configure-llm.sh` is a no-op for other keys (MCP kept)
- [ ] `grep qimono vps-ubuntu ~/.bashrc ~/.profile` — guard block present once

## Smoke (after keys filled)

- [ ] `codex exec "say hi in 3 words"` — returns text (API key path)
- [ ] `opencode run "say hi in 3 words"` — returns text
- [ ] `echo $OPENAI_API_KEY` in a fresh shell — non-empty when configured

## Rollback

- [ ] Codex: remove `~/.codex/config.toml` / restore `.pre-vps-ubuntu.*` backup
- [ ] opencode: restore `opencode.json` from git or `.pre-vps-ubuntu.*` backup
- [ ] Uninstall binaries: `rm ~/.local/bin/codex`, `rm -rf ~/.opencode`
- [ ] Remove the guarded block between the `qimono vps-ubuntu LLM env` markers
