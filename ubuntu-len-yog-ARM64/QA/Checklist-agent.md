# QA — Agent checklist (ubuntu-len-yog-ARM64)

Anti false-victory: the agent records **evidence** (real command output), not
intent. Run in order; tick only what actually passes.

## Host (must be done under sudo before agent can finish)

- [ ] GNU Guix binary installed: `guix --version` → `guix (GNU Guix) 1.5.0`
- [ ] Build users + trust store present:
      `ls -ld /var/guix/profiles/per-user/root` exists
- [ ] `guix pull` succeeded (or initial binary guix usable) —
      `~/.config/guix/current/bin/guix` on PATH

## Pack applied

- [ ] `scripts/install-host-sysctl.sh` ran →
      `sysctl kernel.apparmor_restrict_unprivileged_userns` == `0`
- [ ] `scripts/install-guix-python-uv.sh` ran →
      `guix package -I` shows `stow`, `python`, `uv`
- [ ] `scripts/stow-apply.sh` ran →
      `~/.zshrc` is a symlink into `stow-source/shell`
- [ ] `~/.zshrc.d/10-guix.zsh` exists and is sourced (via `.zshrc.local`)

## Smoke tests

- [ ] `guix package -I` lists expected packages (no crash)
- [ ] `uv --version` ok; `uv` refuses system python per 20-uv-python.zsh
- [ ] `stow --version | head -1`
- [ ] `~/.guix-profile/bin/python3 --version` is a Guix (store) python
- [ ] New login shell: `which python3` resolves under `~/.guix-profile`

## Reboot-persistence

- [ ] After R1: `sysctl kernel.apparmor_restrict_unprivileged_userns` still `0`
- [ ] After R1: new shell still has guix/uv/stow on PATH
