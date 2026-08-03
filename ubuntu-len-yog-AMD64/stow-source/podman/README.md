# stow package: podman (optional)

Sample **systemd user** unit only — not applied by default `stow-apply.sh`.

```bash
stow -d stow-source -t "$HOME" -v podman
systemctl --user daemon-reload
# edit service name/container first
# systemctl --user enable --now qimono-podman-example.service
```

See `docs/podman-autostart.md`.
