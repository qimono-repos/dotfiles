# WSL vs "real Linux" — for when the Windows machine joins the herd

Your forecast was right; this is the Windows-side counterpart to
`macos-vs-linux.md`. WSL is **not** a VM and **not** "Linux in a window" — it's
a Microsoft-built Linux *compatibility* layer that runs a real distro's
**userspace** on the Windows kernel. That distinction is the whole story.

## The core model

| | WSL1 (legacy) | WSL2 (default) | Real Linux |
|---|---|---|---|
| Kernel | none — syscalls translated to Windows | **real Linux kernel in a lightweight Hyper-V VM** | real kernel |
| Boot | instant | fast (VM) | native |
| FS access | native Linux→Windows bridge, can browse `C:\` | Linux FS in a `.vhdx`; **do NOT edit Linux files from Windows apps** (corruption) | native |
| Docker/podman | painful | **works** (real kernel) | native |
| Networking | shared | virtual NAT NIC | native |

You'll be on **WSL2** — it behaves like Linux (containers work) but lives
inside a `.vhdx` disk file with its own space budget, and it has a texture of
"Linux-shaped but Microsoft-managed."

## The pain points (what your Linux instincts will hit)

1. **Never edit WSL files from Windows** (`\\wsl$`, notepad.exe) — risks
   corruption on WSL2. Edit inside WSL or via `code .` from a WSL terminal.
2. **Disk/sizes**: the `.vhdx` grows, needs `wsl --shutdown` + `wsl --manage
   <distro> --set-sparse true` (modern) to shrink. Homebrew-level caching adds
   up.
3. **No systemd by default** → the launchd/systemd gap becomes "enable
   `[boot] systemd=true` in `/etc/wsl.conf`" — that makes real systemd services
   work (contrast: macOS has no such opt-in).
4. **Windows quirk layer**: `wsl.exe` runs Windows binaries, `.bashrc`
   differences, `Windows PATH` leaking into WSL (`WSLENV`), and the 
   `\\wsl.localhost` network.
5. **The Windows side still exists** — file explorer, `C:\`, Windows services.
   You navigate TWO worlds.

## Homebrew vs winget (the package-manager comparison)

| Linux | macOS | Windows |
|-------|-------|---------|
| apt | Homebrew | **winget** |
| systemd | launchd | Windows Services |
| `~/.cache` | `~/Library/Caches` | `%LOCALAPPDATA%` / `%APPDATA%` |
| `/home/qi` | `/Users/qi` | `C:\Users\qi` |
| shell | zsh | PowerShell |

The fleet's three managers converge through the same dotfiles + stow + tmux
story: winget (host, Windows), brew (host, macOS), apt (host, Ubuntu) — and on
all three you can additionally get a real package-managed dev env via Guix
(Linux/WSL) or Homebrew (macOS).

## Practical conclusion for the herd

- Treat **WSL2 as "Linux with a Windows-recovery parachute"** for the Windows
  machine — it's where the shared zsh/tmux/Guix story land there.
- Keep your **real-Linux habits** (they work); add the Windows-native reflexes
  (don't mix filesystems, know where `.vhdx` lives, systemd opt-in).
- This is the Windows-side sibling; keep it updated alongside
  `macos-vs-linux.md` as the fleet grows.