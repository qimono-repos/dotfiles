# QA — User checklist (darwin pack)

Human-owned steps (macOS update, admin sudo, GUI dialogs). Print + pen or edit in git.

## R0 — before anything (needs the full macOS account)

- [ ] **Both Macs updated to macOS 26 (Tahoe)** — Software Update; verify `sw_vers`
- [ ] User is an Administrator on both
- [ ] `curl -fsSL https://qimono.online/install | sh` (or raw fleet URL) ran
- [ ] `container system start` kernel-install prompt accepted (one-time)
- [ ] Rosetta 2 installed (System Settings → Software Update → install) — needed to BUILD images
- [ ] `container machine run qi-dev` entered the machine with a prompt
- [ ] Inside machine: `sudo bash ~/.qimono/guix-system-install.sh` completed
- [ ] Inside machine: `bash ~/.qimono/guix-user-bootstrap.sh` completed

## R1 — first macOS reboot

- [ ] Actual macOS reboot (not just re-login)
- [ ] Fresh shell: `which brew` and `which container` resolve
- [ ] `container machine run qi-dev` still starts the machine

## R2 — second login smoke

- [ ] Fresh shell: oh-my-posh catppuccin prompt renders on macOS
- [ ] `alias dev` exists (darwin zshrc.d/30-container.zsh)
- [ ] Inside machine, fresh login shell: `guix --version` works without manual sourcing
- [ ] Guix sandbox: `guix shell hello -- hello`

## Day-1

- [ ] Everything above passes on **both** Macs → append a **Session log** line to `JOURNAL-P3-P5.md`
- [ ] Fill `darwin/MACHINE.md` from both `machine-*.txt` discovery reports
- [ ] Commit the darwin pack + fleet changes