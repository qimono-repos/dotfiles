# Tasks priority — ubuntu-len-yog-ARM64

Order of work for this machine. Tick as done.

1. [ ] Install GNU Guix binary (aarch64) + build users + trust keys
2. [ ] Install host sysctl (userns=0) — survives reboot
3. [ ] Apply base manifest (stow, python, uv, jupyter, editors, git …)
4. [ ] Stow shell + guix-env + nvim config into $HOME
5. [ ] Install oh-my-posh (optional)
6. [ ] Quantum workspace: uv + qiskit + pennylane
7. [ ] Jupyter user service on 127.0.0.1:5005
8. [ ] Ollama + gemma4:e2b (optional; 30 GiB RAM is fine)
9. [ ] Reboot R1/R2 QA + commit pack
