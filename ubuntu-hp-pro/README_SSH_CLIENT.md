# SSH client onboarding — HP ProBook → qimono-localhost

Give **this machine** key access to the Yoga SSH server (works on LAN and,
via Tailscale, from anywhere — no router config). Doing this is what allows
the server to lock out password brute-force afterwards.

Server-side proposal: `~/TAILSCALE-README.md` (Parts 2–4) ·
hardening script: `ubuntu-len-yog-AMD64/scripts/install-ssh-hardening.sh`

---

## Step 1 — One-time setup on this machine

```bash
# ed25519 key pair (skip if `ls ~/.ssh/id_ed25519.pub` already shows a key)
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"

# join the tailnet (skip if `tailscale status` already works)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up          # browser auth, same account as the Yoga
```

## Step 2 — Install your key on the server (asks qi's password — last time)

```bash
ssh-copy-id qi@qimono-localhost.tailbb5c9e.ts.net
# fallback without MagicDNS:
ssh-copy-id qi@100.75.158.18
```

## Step 3 — Client config → `~/.ssh/config` (`chmod 600` after)

```ini
# Primary: MagicDNS name — resolves anywhere on the tailnet
Host qimono-localhost
    HostName qimono-localhost.tailbb5c9e.ts.net
    User qi
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Fallback: raw tailnet IP
Host qimono-localhost-ts
    HostName 100.75.158.18
    User qi
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

Note: this pack's `~/.ssh` may already carry a GitHub-CLI key named like
`id_ed25519_github_cli_*` — that key is for git remotes, not for this.
Generate/use the default `id_ed25519` for host login.

## Step 4 — Prove key login works

```bash
ssh qimono-localhost 'echo KEY-AUTH-OK from $(hostname)'   # no password prompt
ssh -o PubkeyAuthentication=no qimono-localhost            # must STILL ask password today
```

## Step 5 — Hand the result to the server

Once Step 4 succeeded, on **qimono-localhost** run:

```bash
~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64/scripts/install-ssh-hardening.sh --client-tested
```

That flips `PasswordAuthentication no` safely. Verify anytime from here with
`ssh qimono-localhost` (must keep working) — the negative test
(`PubkeyAuthentication=no`) must now FAIL.

---

## Checklist

- [ ] `~/.ssh/id_ed25519(.pub)` exists here
- [ ] `tailscale status` shows both devices (`hp-pro`, `qimono-localhost`)
- [ ] `ssh-copy-id` done, no errors
- [ ] `ssh qimono-localhost` logs in WITHOUT password
- [ ] Server operator ran the hardening script with `--client-tested`
