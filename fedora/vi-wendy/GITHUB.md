# GitHub access — vi-wendy

Working Git access to `qimono-repos/dotfiles` was configured on 2026-11-22.

## Git

```text
user.name  Qimono
user.email albert.tan.2.pi.0@gmail.com
origin     git@github.com:qimono-repos/dotfiles.git
main       tracks origin/main
```

Global extras: `init.defaultBranch=main`, `pull.rebase=false`, `push.autoSetupRemote=true`, `fetch.prune=true`.

## SSH

- Dedicated key: `~/.ssh/id_ed25519_github`
- Public key: `~/.ssh/id_ed25519_github.pub`
- Fingerprint: `SHA256:5Sc7CjkupZ/6zOzJwCo5zY+hRNHoWW3+d14CVYZzNhU`
- `~/.ssh/config` selects that key for `Host github.com`.
- GitHub host keys were verified against `https://api.github.com/meta` before being added to `~/.ssh/known_hosts`.
- The older `~/.ssh/id_rsa` key was not authorized and is not used for GitHub.
- No private key material belongs in this repository.

Verify:

```bash
ssh -o BatchMode=yes -T git@github.com
git ls-remote origin HEAD
```

Expected: `Hi qimono-repos!` and the current `HEAD` SHA. `ssh` exits non-zero after the GitHub message because GitHub does not provide shell access.

## GitHub CLI

`gh` 2.105.0 is installed at `~/.local/bin/gh` from the official checksummed Linux amd64 release tarball. The repeatable installer lives in this pack:

```bash
./fedora/vi-wendy/scripts/install-github-cli.sh
```

It is idempotent, user-owned, verifies the release checksum, and sets `git_protocol=ssh`. Pin a release with `QIMONO_GH_VERSION=v2.105.0` if the GitHub API is unavailable.

```text
gh config get git_protocol -> ssh
```

The CLI still needs an interactive login when `gh api`, `gh pr`, or `gh issue` commands are used:

```bash
gh auth login --web --git-protocol ssh --scopes repo,workflow
```

This prints a one-time device code; no clipboard utility is required. Enter the code in the browser when prompted. Do not put tokens in shell history, chat, or this repository.
