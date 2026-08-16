# Developer Python = Guix (apt Python stays)

## Rule

- **You** type `python3` → Guix (`~/.guix-profile/bin/python3`, 3.11.x).
- **Ubuntu** scripts use `#!/usr/bin/python3` → apt 3.14, untouched.
- Do **not** `apt remove python3`. Do **not** delete `/usr/bin` from PATH.

## How Guix wins

Live `~/.zshrc` is the old `dotfiles/ubuntu/.zshrc` (Kepler + Vega). This
pack does **not** replace it.

That file now sources `~/.zshrc.local` if present. Stow from this pack
provides `.zshrc.local` → loads `~/.zshrc.d/*.zsh` **last**, so:

1. `10-guix.zsh` sources `~/.guix-profile/etc/profile` (prepends Guix bins)
2. `20-uv-python.zsh` pins `UV_PYTHON_PREFERENCE=only-system` and
   `QIMONO_GUIX_PYTHON`

Check:

```bash
which -a python3
# first line must be /home/qi/.guix-profile/bin/python3
python3 --version          # 3.11.x
/usr/bin/python3 --version # 3.14.x, still there
```

## uv

Use the Guix `uv`. Do **not** `uv python install 3.12`. That is a second
interpreter and fights this policy.

```bash
export UV_PYTHON_PREFERENCE=only-system
uv python pin "$(readlink -f "$HOME/.guix-profile/bin/python3")"
```

Host `~/.local/bin/uv` (0.12.x) may still exist; after `10-guix.zsh` the
Guix binary is first.

## Do not put Guix `lib/` on `LD_LIBRARY_PATH` in the shell

Guix glibc is newer than Ubuntu’s. If `LD_LIBRARY_PATH` contains
`~/.guix-profile/lib`, host binaries (`ls`, `cat`, `date`) load Guix
`libm.so.6` and fail with `GLIBC_2.43 not found`.

Immediate repair in a broken session:

```bash
unset LD_LIBRARY_PATH
# then, after this pack’s 10-guix.zsh is updated:
source ~/.zshrc
```

Wheels that need `libz` / `libstdc++` get that path only in the Jupyter
user unit and in `install-quantum-python.sh`, not in every prompt.

## Wrong `GUIX_PROFILE`

The old zshrc sets `GUIX_PROFILE=~/.config/guix/current` (the *guix
command* after `guix pull`). User packages live in `~/.guix-profile`.
`10-guix.zsh` resets this. Do not copy the old assignment into new scripts.
