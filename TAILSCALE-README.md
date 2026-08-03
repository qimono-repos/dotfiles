# Tailscale — SSH to qimono-localhost from anywhere (human tutorial)

**Works without any router configuration, public IP, or port forwarding.**  
Tailscale is a mesh VPN: every one of your devices gets a stable `100.x.y.z` address and can reach the others directly, from any network (home, Starbucks, office). Traffic is WireGuard-encrypted end to end.

Snapshot (this machine, 2026-08-03):

| What | Value |
|------|-------|
| Hostname | `qimono-localhost` |
| Tailnet | `tailbb5c9e.ts.net` |
| Tailnet IP | `100.75.158.18` |
| MagicDNS name | `qimono-localhost.tailbb5c9e.ts.net` |
| SSH | `qi@` via ed25519 key, port 22 |

Related: `~/ssh-config-for-other-machine.txt` · `~/AGENTS.md` · `dotfiles/SD-CARD-README.md` (style twin)

---

## Safety rules / best practices

1. **SSH keys only** — once the client key is installed, disable `PasswordAuthentication` (see Part 4).
2. **Prefer MagicDNS names over IPs** — they survive re-adds; tailnet IPs are stable but names are readable.
3. **No port forwarding, no public-IP SSH.** If you open the router later, keep it optional — Tailscale already works.
4. **Watch the free tier scope** — non-commercial Personal plan: 6 users, unlimited devices, forever.
5. **Remove devices you stop using** from the admin console (revoke = instant).
6. **Tailscale ≠ anonymizing VPN** — it doesn't hide your IP from websites; it is a private network overlay.

---

## Part 0 — What you need

- Two Ubuntu machines, each with an SSH key pair (`ssh-keygen -t ed25519`).
- A single account to sign in (Google / GitHub / Microsoft / email). Personal email → free Personal plan.
- `~/.ssh/config` on the client (template below).
- sshd running on the target (done here: `systemctl is-enabled ssh` → enabled).

---

## Part 1 — Install + join the tailnet (this machine, DONE)

```bash
# Ubuntu install
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate once; opens a browser link
sudo tailscale up

# Check state
tailscale status
tailscale ip -4            # e.g. 100.75.158.18
systemctl is-active tailscaled   # keep it active & enabled
```

`tailscaled` is already `active` and `enabled` here (survives reboot).

---

## Part 2 — Add the second device (the other Ubuntu machine)

From the other machine (the one you take to the office/coffee shop):

```bash
# 1. join the SAME tailnet with the SAME account
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# 2. after signing in, confirm you see this machine
tailscale status

# 3. make sure it has an SSH key
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"

# 4. install your key into this machine once (asks for qi's password)
ssh-copy-id qi@qimono-localhost.tailbb5c9e.ts.net

# 5. connect
ssh qimono-localhost
```

The admin console (`login.tailscale.com`) will show both devices after step 1. “Waiting for your second device” disappears once the other machine joins.

---

## Part 3 — The client config file

Paste into `~/.ssh/config` on the other machine, then `chmod 600 ~/.ssh/config`:

```ini
# Primary: MagicDNS name — resolves on the tailnet from anywhere
Host qimono-localhost
    HostName qimono-localhost.tailbb5c9e.ts.net
    User qi
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Fallback: raw Tailscale IP (if MagicDNS is disabled)
Host qimono-localhost-ts
    HostName 100.75.158.18
    User qi
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Legacy: public-IP path — ONLY if you later get router port-forwarding
Host qimono-localhost-wan
    HostName 200.59.178.116
    Port 2222
    User qi
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

Copy kept at: `~/ssh-config-for-other-machine.txt`.

---

## Part 4 — Hardening (do this AFTER the client key is installed)

With password login off, brute-force bots can't get in over the internet.

```bash
sudo tee /etc/ssh/sshd_config.d/60-tailscale-hardening.conf >/dev/null <<'EOF'
PasswordAuthentication no
PermitRootLogin no
EOF
sudo systemctl restart ssh
```

Check before locking yourself out:

```bash
grep -R '^PasswordAuthentication' /etc/ssh/sshd_config.d/ /etc/ssh/sshd_config
# test from the other machine FIRST: ssh qimono-localhost
```

If the client key was never installed, leave `PasswordAuthentication yes` until `ssh-copy-id` succeeds.

---

## Part 5 — Day-to-day

| Task | Command |
|------|---------|
| Status | `tailscale status` |
| Update client | `sudo tailscale update` (or `sudo apt update && sudo apt upgrade tailscale`) |
| Pause network | `sudo tailscale down` (service keeps running) |
| Resume | `sudo tailscale up` |
| Check path | `tailscale ping qimono-localhost` → `direct` or `via DERP` (relay fallback is fine) |
| Show devices | `tailscale status --json \| grep -i dnsname` |
| Leave tailnet | `sudo tailscale logout` |
| Manage/revoke | admin console at `login.tailscale.com` |

Direct vs DERP: Tailscale tries to punch a direct UDP path (lowest latency); if a network blocks it, it falls back to an encrypted relay. Both are private and encrypted — DERP only means the packets bounce via a Tailscale server.

---

## Part 6 — Troubleshooting

| Symptom | Check |
|---------|-------|
| “Waiting for your second device” | The other machine hasn't run `sudo tailscale up` with the same account yet |
| `ssh` hangs / host unreachable | `tailscale status` on both; both online? `tailscale ping qimono-localhost` |
| DNS name unknown | MagicDNS off on client: use the `-ts` alias (raw IP) or re-enable MagicDNS |
| Permission denied (publickey) | Client key not in `~/.ssh/authorized_keys` here → redo `ssh-copy-id` |
| Cannot `sudo apt install tailscale` | Distro mirror/arch mismatch; use the official installer script |
| Deleted a device, still shown | Remove it in the admin console (approval/revocation) |
| sshd not listening | `systemctl is-enabled ssh`, `ss -tlnp \| grep :22` |

---

## Checklist (print-friendly)

- [ ] `tailscaled` active + enabled on both machines
- [ ] Both devices visible in admin console under `tailbb5c9e.ts.net`
- [ ] `ssh-keygen -t ed25519` done on the client
- [ ] `ssh-copy-id qi@qimono-localhost.tailbb5c9e.ts.net` once
- [ ] `~/.ssh/config` copied, `chmod 600`
- [ ] `ssh qimono-localhost` works from home AND from an outside network
- [ ] Password authentication disabled (Part 4) only after key confirmed
- [ ] Client config also kept at `~/ssh-config-for-other-machine.txt`
