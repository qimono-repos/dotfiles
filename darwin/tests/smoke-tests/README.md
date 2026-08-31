# darwin smoke tests

Run INSIDE the container machine (`container machine run qi-dev`) unless noted.
These are the proof the AI checklist's Guix section is honest: real output, not intent.

## Host-side (macOS)

```bash
sw_vers -productVersion            # 26.x
uname -m                           # arm64
container --version && podman --version
container machine list             # qi-dev present, default
bash -n ../scripts/*.sh            # all scripts parse
```

## In-machine (Linux)

```bash
ps -p 1 -o comm=                   # systemd
source ~/.guix-profile/etc/profile  # explicit; 05-guix.zsh does it in new shells
guix --version | head -1
guix package -I                    # darwin-base manifest applied
guix shell hello -- hello          # sandbox smoke → “Hello, world!”
which guix                         # under ~/.guix-profile
```

Save as one run:

```bash
./run-all.sh    # prints PASS/FAIL summary
```

Edit `run-all.sh` to add checks as the fleet grows.