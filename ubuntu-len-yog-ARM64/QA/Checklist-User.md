# QA — User checklist (ubuntu-len-yog-ARM64)

Human-owned steps (sudo, reboot, GUI). Use print + pen or edit in `git`.

## R0 — before reboot (needs sudo password)

- [ ] `sudo tar ... guix-binary-1.5.0.aarch64-linux.tar.xz -C /` unpacked
- [ ] Guix build users + `/var/guix/profiles/per-user/root` created
- [ ] `/gnu/store` world-readable (`chmod 755`) and trusted substitute keys
- [ ] `sudo ./scripts/install-host-sysctl.sh` done (once)
- [ ] Guix profile sourced: `source ~/.guix-profile/etc/profile`
- [ ] `guix package -I` shows stow/python/uv

## R1 — first reboot

- [ ] Machine reboots cleanly into Ubuntu
- [ ] `sysctl kernel.apparmor_restrict_unprivileged_userns` == `0` (survived boot)
- [ ] New terminal: `which python3` → `~/.guix-profile/...` (Guix python)
- [ ] `uv --version` works without sourcing anything extra

## R2 — second login smoke

- [ ] Re-open a fresh shell — prompt/oh-my-posh (if installed) renders
- [ ] `echo $PATH` includes `~/.guix-profile/bin` and `~/.config/guix/current/bin`
- [ ] Quantum workspace path `$QIMONO_QUANTUM_HOME` set
- [ ] Browser (Guix epiphany/firefox, or host snap) launches from app grid

## Day-1

- [ ] Everything above passes → append a **Session log** line to `JOURNAL-P3-P5.md`
- [ ] Commit the new pack
