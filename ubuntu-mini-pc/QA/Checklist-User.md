# Checklist — Human (`ubuntu-mini-pc`)

Print or tick. Born from Yoga profile-wipe + HP Jupyter lessons.

## Before bootstrap

- [ ] Network works
- [ ] `guix --version` prints 1.5.x
- [ ] You will **not** run a partial `guix package -m`
- [ ] Disk headroom ≥ 10 G (`df -h /`)

## After `./scripts/bootstrap.sh`

- [ ] New terminal: `which python3` starts with `~/.guix-profile/bin/python3`
- [ ] `python3 --version` is 3.11.x
- [ ] `/usr/bin/python3 --version` still works (3.14.x)
- [ ] `which uv` is under `~/.guix-profile`
- [ ] `systemctl --user status qimono-jupyter.service` is active (or activating)

## Auth (you, once)

- [ ] `./scripts/setup-jupyter-auth.sh` wrote `~/.secrets/jupyter_auth.py` mode 600
- [ ] Passphrase stored in the password manager (not in git)
- [ ] http://127.0.0.1:5005 asks for a password (no token in the URL)
- [ ] Login works

## After `./scripts/install-quantum-python.sh`

- [ ] `cd ~/source/repos/qimono-repos/quantum-workspace && uv run python tests/smoke-tests/hello_qiskit.py` prints `qiskit OK`
- [ ] Notebook kernel **Python (quantum)** exists
- [ ] `./scripts/status.sh` is all green except items you deferred

## Reboot (R1 / R2)

- [ ] R1: reboot
- [ ] R2: after login, http://127.0.0.1:5005 still serves (user unit)
- [ ] `which python3` is still Guix
