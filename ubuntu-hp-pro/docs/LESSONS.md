# Lessons (shared with Yoga pack)

Full write-up lives in the proven pack:

**`../ubuntu-len-yog-AMD64/docs/LESSONS-guix-browsers.md`**

Critical six:

1. Post-pull guix: `~/.config/guix/current/bin/guix` ≠ `/usr/local/bin/guix`  
2. Epiphany needs **`kernel.apparmor_restrict_unprivileged_userns=0`** **and** drop-in **`/etc/sysctl.d/99-guix-userns.conf`** (runtime `sysctl -w` dies on reboot)  
3. Root cause: Ubuntu AppArmor allows host `/usr/bin/bwrap`; Guix uses `/gnu/store/*-bubblewrap-*/bin/bwrap` → denied until the gate is off  
4. Firefox via **nonguix substitutes** + `guix archive --authorize`  
5. Prefer `guix install epiphany firefox` first try  
6. Never compile Firefox from source on a laptop if substitutes exist  

## This pack — install userns early

```bash
./scripts/install-host-sysctl.sh          # alone (sudo once)
# or full browser path:
./scripts/bootstrap.sh                    # step → 30-browser-prereqs.sh → install-host-sysctl.sh
```

After any reboot:

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns   # must be 0
test -f /etc/sysctl.d/99-guix-userns.conf && echo drop-in-ok
epiphany &
```

Keep `host-sysctl/99-guix-userns.conf` **byte-identical intent** with Yoga pack.

**Checklists:** [Checklist-agent.md](../Checklist-agent.md) · [Checklist-User.md](../Checklist-User.md)  
User **R1**: reboot after Epiphany once · **R2**: Epiphany after reboot. Agent must not mark victory without those.
