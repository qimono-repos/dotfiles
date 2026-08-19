# Console Font Setup

Quick reference for TTY console fonts on Ubuntu (bare-metal, no GUI needed).

## Preview (no changes made)

```bash
# Show all fonts with columns × rows for your resolution
./scripts/console-font-resize.sh

# Show recommended font for bigger text (~33 rows)
./scripts/console-font-resize.sh --big
```

## Live Preview on a TTY

Switch to a TTY (Ctrl+Alt+F3), then:

```bash
# Try a font immediately
sudo setfont Lat2-TerminusBold32x16

# Or restore the default
sudo setfont default
```

Return to desktop with Ctrl+Alt+F7.

## Make It Permanent

```bash
# Auto-detect resolution and install the big font
sudo ./scripts/console-font-resize.sh --apply --big

# Or install the font from etc/vconsole.conf directly
sudo ./scripts/install-vconsole.sh
```

## Fonts Available

| Font | Char size | Columns (1080p) | Rows (1080p) | Notes |
|------|-----------|-----------------|--------------|-------|
| `Lat2-TerminusBold16` | 8×16 | 240 | 67 | Small, dense |
| `Lat2-TerminusBold24x12` | 12×24 | 160 | 45 | Medium |
| `Lat2-TerminusBold28x14` | 14×28 | 137 | 38 | Large |
| `Lat2-TerminusBold32x16` | 16×32 | 120 | 33 | **Big** — matches CaskaydiaCove 16pt column feel |

## On Ubuntu Server (other machine)

Copy the config and apply:

```bash
sudo cp etc/vconsole.conf /etc/vconsole.conf
sudo setfont Lat2-TerminusBold32x16
```
