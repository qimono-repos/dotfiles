# Skill: bare-metal TTY font management (Ctrl+Alt+F2–F6 consoles)

> Origin: ubuntu-mini-pc console-font work, reviewed against
> qimono-localhost state 2026-08-21.
> Goal: readable, GUI-matching fonts on kernel virtual consoles — set once,
> persistent across reboots.

## When to use this skill

Font size/appearance complaints about the *bare metal* terminals (VTs,
Ctrl+Alt+F2–F6) — the ones that exist before X/Wayland starts. These are
kernel framebuffer consoles: bitmap PSF fonts loaded into the GPU console,
NOT fontconfig/GUI fonts. GUI font tools are irrelevant here.

## The stack (Ubuntu foreign distro)

| Piece | Role | Source |
|---|---|---|
| `kbd` | `setfont`, `showconsolefont`, keymaps | apt |
| `console-setup`, `console-setup-linux` | boot-time font service + `.psf.gz` fonts in `/usr/share/consolefonts/` | apt |
| Guix | nothing — keep console tooling host-owned | — |

## Two config files, know which one wins

| File | Consumed by | Fleet standard |
|---|---|---|
| `/etc/vconsole.conf` | `systemd-vconsole-setup` at boot | ✅ use this |
| `/etc/default/console-setup` | legacy `setupcon`/console-setup.sh (`FONTFACE`/`FONTSIZE`) | leave defaults |

Minimal working `vconsole.conf`:

```
KEYMAP=us
FONT=Lat2-TerminusBold32x16
```

## Font naming and sizes

Names come from `/usr/share/consolefonts/*.psf.gz`; format
`Lat2-Terminus{Bold}{Size}` (Lat2 = Latin-2 + box-drawing glyphs).

Available sizes: `12x6 14 16 18x10 20x10 22x11 24x12 28x14 32x16`.

**Sizing math** (bitmap cells, so pick by target columns):

> CaskaydiaCove Nerd Mono 16pt at 1920×1080 ≈ 120 cols × 67 rows
> ≈ `Lat2-TerminusBold32x16` at 1920×1080

Same width logic transfers per panel: 1920×1200 panels get identical
column counts with a few bonus rows. Halve the size for "tiny but huge
workspace" mode (`Lat2-TerminusBold16` ≈ 240 cols).

## Apply paths

```bash
# immediate — ONLY works while sitting ON a VT (fails harmlessly from GUI)
sudo setfont Lat2-TerminusBold32x16

# persistence = install vconsole.conf, then either reboot or:
sudo systemctl restart systemd-vconsole-setup   # if unit exists
```

Test loop: `Ctrl+Alt+F3` → look → `Ctrl+Alt+F7` (or F2↔F1 on GNOME Wayland)
back to session. Full proof lands at next boot.

## QA discipline (fleet rules apply)

- Agent CANNOT sudo: ship `etc/vconsole.conf` + an installer script in the
  machine pack; human runs `sudo ./scripts/install-vconsole.sh [--font X]`.
- Installer should: verify each `${FONT}.psf.gz` exists in
  `/usr/share/consolefonts` BEFORE installing, apply via `setfont`,
  restart `systemd-vconsole-setup` when present, print the Ctrl+Alt+F3 test hint.
- `setfont` failing from inside a GUI session is NORMAL — do not chase it.

## Reference implementations

- `ubuntu-mini-pc/etc/vconsole.conf` (+ sizing rationale comments)
- `ubuntu-mini-pc/scripts/install-vconsole.sh` (installer, `--font` override)
- `ubuntu-mini-pc/scripts/install-console-fonts.sh` (apt deps + font audit)

## Known state per node (2026-08-21)

| Node | Panel | Status |
|---|---|---|
| mini-pc | 1920×1080 | done — TerminusBold32x16 |
| Yoga (localhost) | 1920×1200 | pending — still stock `Fixed 8x16` (microscopic); fonts already on disk |
