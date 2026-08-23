# TODO-H — human handoff (next session starter)

**Where we stopped:** 2026-08-22 · Yoga→hp-pro parity port COMPLETE on the agent side
(17/17 tasks) + **H1 ✅** (ollama unit live, `gemma4:e2b` served from `~/.ollama/models`)
+ **H2 ✅** (TTY font installed and tested live on VT3). Plan of record:
[`agent-plan.json`](./agent-plan.json).

Review order next time: this file → `agent-plan.json` → `JOURNAL-P3-P5.md` P6.2 row.

---

## H3 — SSH client onboarding (Yoga server access)

Follow [`README_SSH_CLIENT.md`](./README_SSH_CLIENT.md) top-to-bottom:

- [ ] `ssh-keygen -t ed25519 -C "qi@$(hostname)"` (no default key exists yet)
- [ ] Install Tailscale + `sudo tailscale up` (same account as Yoga)
- [ ] `ssh-copy-id qi@<yoga>` — pick the target name AFTER H4 rename below,
      otherwise you'll ssh into yourself (`qimono-localhost` currently resolves HERE)
- [ ] Client `~/.ssh/config` block + `chmod 600`
- [ ] Prove: key login OK *and* `PubkeyAuthentication=no` still asks password
- [ ] Then Yoga operator runs `install-ssh-hardening.sh --client-tested`

## H4 — hostname rename decision

This box's static hostname is **`qimono-localhost`**, which every doc assigns to the
Yoga SSH server — fleet-naming collision, breaks H3 as-is.

- [ ] Decide name (candidate: `hp-pro`) → `sudo hostnamectl hostname hp-pro`
      (+ `/etc/hosts` entry)
- [ ] Update docs that hard-code hostnames (MACHINE.md caveat section, README_SSH_CLIENT)

## H5 — reboot QA (R1/R2 discipline — nothing is "done" without this)

One reboot proves four things at once:

- [ ] **R1**: reboot after Epiphany has launched once
- [ ] After reboot: `sysctl kernel.apparmor_restrict_unprivileged_userns` → **0**
      and `/etc/sysctl.d/99-guix-userns.conf` exists
- [ ] **R2**: `epiphany &` opens a page again (browsers officially DONE)
- [ ] Autostart fires: Firefox guarded launch + Ptyxis + VSCodium appear
- [ ] Ghostty tile click opens a window with a working zsh (D-Bus activation persists)
- [ ] TTY3 shows TerminusBold32x16 (H2 boot-persistence proof)
- [ ] Tell the agent R1+R2 are `[x]` so agent QA can close out (per `QA/Checklist-agent.md` A5)

---

### Quick state check (paste into terminal)

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro
guix package -I | wc -l                    # expect 24
systemctl --user is-active qimono-jupyter  # active (:5005)
systemctl is-active ollama                 # active (gemma4:e2b)
~/.local/bin/ghostty +version              # Ghostty 1.3.1 via flatpak
```
