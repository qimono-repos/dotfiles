# KDE Connect — phone as laptop extension (2026+)

**Chunk:** P3.4 · Feedback F10

## Why

Ying-Yang infrastructure treats the **phone as a real extension** of the PC (continuity-class UX): notifications, clipboard, input, file push, remote commands.

## Install (Guix-first)

Package exists on Guix: **`kdeconnect`** (KDE Frameworks 6 era on current channels).

```bash
guix install kdeconnect
# or via base.scm which lists kdeconnect
guix package -m guix/manifests/base.scm
source "$HOME/.guix-profile/etc/profile"
```

Fallback if Guix build is huge/broken on low RAM:

```bash
sudo apt install kdeconnect
```

## First-run checklist

1. Install **KDE Connect** (or GSConnect) on the phone from F-Droid / Play / vendor store.  
2. Same Wi‑Fi (or trusted VPN) as the laptop.  
3. Laptop: start indicator / app:

```bash
# GUI
kdeconnect-app &
# or CLI discovery
kdeconnect-cli -l
```

4. Pair: accept on both devices.  
5. GNOME users: optional **GSConnect** extension (often smoother than full KDE stack on GNOME).

### GNOME path (this Yoga is GNOME)

| Option | Notes |
|--------|-------|
| Guix/apt `kdeconnect` + `kdeconnect-app` | Works; may pull Qt deps |
| **GSConnect** GNOME Shell extension | Feels native on Ubuntu GNOME |

```bash
# if using apt world for GSConnect deps:
# sudo apt install gnome-shell-extension-gsconnect
# then enable in Extension Manager
```

## Firewall

KDE Connect uses ports in the **1714–1764** range (UDP/TCP). On strict UFW:

```bash
# only on trusted networks
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp
```

## Security notes

- Pair only known devices.  
- On public Wi‑Fi, prefer off or VPN.  
- Do not expose KDE Connect ports on a VPS security group.

## Verify

```bash
kdeconnect-cli -l
kdeconnect-cli --pair --device <id>   # if needed
```

## Journal

If Guix install OOMs on 6.5 GiB, log failure in `JOURNAL-P3-P5.md` and use apt/GSConnect until a better machine or `guix gc` + free RAM.
