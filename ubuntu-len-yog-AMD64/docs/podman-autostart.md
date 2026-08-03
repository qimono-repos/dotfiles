# Podman auto-start on Ubuntu (systemd user) — P4.4

**Not** a second init system. Stage 1 keeps **systemd**; Guix **Shepherd** comes with Guix System later  
(see `teach-inits-shepherd.md`).

## Pattern A — oneshot start existing container

```ini
# ~/.config/systemd/user/qimono-podman-example.service
[Unit]
Description=Qimono example podman container
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/podman start qimono-example
ExecStop=/usr/bin/podman stop qimono-example

[Install]
WantedBy=default.target
```

```bash
mkdir -p ~/.config/systemd/user
# create container once: podman create --name qimono-example ...
systemctl --user daemon-reload
systemctl --user enable --now qimono-podman-example.service
loginctl enable-linger "$USER"   # optional: run without login session
```

## Pattern B — Quadlet (preferred modern Podman)

Drop a `.container` file under `~/.config/containers/systemd/` and let Podman generate systemd units.  
See `man podman-systemd.unit`.

## Sample stow location (optional later)

```text
stow-source/podman/.config/systemd/user/qimono-podman-example.service
```

Do not enable linger on shared/untrusted machines without thinking about security.
