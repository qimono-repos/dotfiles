# Qimono Guix Lobby: Post-install Automation

The minimal lobby is booting and `qi` can log in. This directory contains the next stage of the experiment: make its network portable, add coding agents, and optionally turn it into a KDE desktop. Shell code is executed with `bash` after downloading; GitHub's content API does not set the executable bit.

## Stage 1: wireless network

Run as `qi` while Ethernet is available:

```sh
wget -O setup-network-in-guix.sh https://raw.githubusercontent.com/qimono-repos/dotfiles/main/lobby-files/setup-network-in-guix.sh
bash setup-network-in-guix.sh
```

The script:
1. Writes a UTC-stamped log to `/var/log/qimono/`.
2. Captures networking and any available PCI/USB identifiers.
3. Chooses `config-network.scm` when a wireless interface is already detected; otherwise it selects `config-network-nonguix.scm` with standard Linux and firmware.
4. When needed, installs the authenticated Nonguix channel in the root Guix environment and authorizes its substitute signing key.
5. Runs `guix system build`, followed by `guix system reconfigure`.
6. Stores the successful definition at `/etc/config.scm`, and prints NetworkManager status.

Overrides:

```sh
QIMONO_FIRMWARE=libre bash setup-network-in-guix.sh
QIMONO_FIRMWARE=nonguix bash setup-network-in-guix.sh
QIMONO_WIFI_SSID='your-network-name' bash setup-network-in-guix.sh
```

When the script installs a new Linux kernel, reboot before concluding whether new wireless hardware is recognized. Then connect through NetworkManager:

```sh
nmcli radio wifi on
nmcli device wifi list
nmcli --ask device wifi connect 'your-network-name'
ip -br a
```

The `--ask` flag collects secrets interactively rather than including passwords in shell history. NetworkManager remembers successful connections.

## Local workspace: clone the repository once

After the network bootstrap has completed, use Git to make the full `dotfiles` repository available on the lobby. The `guix shell git` command provides Git without assuming it is installed in `qi`'s profile. `--depth 1` fetches the complete current working tree without the entire commit history.

```sh
guix shell git -- git clone --depth 1 https://github.com/qimono-repos/dotfiles.git "$HOME/qimono-dotfiles"
cd "$HOME/qimono-dotfiles/lobby-files"
```

For later iterations, fetch the newest scripts and Scheme configuration from main:

```sh
guix shell git -- git -C "$HOME/qimono-dotfiles" pull --ff-only
```

The scripts can now be executed locally, with no more `wget` for the repo files.

## Stage 2: Codex, OpenCode, Ollama

Run as `qi`, not `root`, from the cloned repository:

```sh
bash "$HOME/qimono-dotfiles/lobby-files/install-codex-opencode.sh"
```

- Codex: official latest Linux musl CLI archive from `openai/codex`.
- OpenCode: official current V2 Linux musl archive from `opencode.ai`.
- Ollama: install from Guix if the package is present; otherwise obtain the official Linux archive and adjust its ELF interpreter and library paths for Guix. This is a user-owned install, not a systemd unit.
- Packages are exposed through `~/.local/bin`, and `~/.bash_profile` is updated idempotently.
- Each stage reports a distinct result; scripts can be re-run.
- Logs are saved under `~/.local/state/qimono/`.

Ollama has a comparatively large binary bundle and model storage. In `auto` mode, the script defers Ollama when free space is below 3 GiB. Overrides:

```sh
QIMONO_OLLAMA=force bash "$HOME/qimono-dotfiles/lobby-files/install-codex-opencode.sh"
QIMONO_OLLAMA=off bash "$HOME/qimono-dotfiles/lobby-files/install-codex-opencode.sh"
```

After installation, start Ollama with `ollama serve`. Model downloads are separate.

## Stage 3: KDE Plasma + Bluetooth

Run as `qi` from the cloned repository:

```sh
bash "$HOME/qimono-dotfiles/lobby-files/install-kde-by.sh"
```

The KDE script deploys the adjacent local `config-kde.scm` and `channels-nonguix.scm` files when available, using `guix system reconfigure`. It adds Plasma, SDDM, BlueZ, NetworkManager, standard Linux, and firmware. Its desktop service composition uses `%desktop-services`, removes GDM, and adds SDDM.

KDE is not part of the minimal lobby concept, but the scripted configuration lets us experiment with it. The 7.5 GiB USB is substantially smaller than a typical Plasma system closure. The script reports disk usage and stops below 1 GiB free unless `QIMONO_FORCE=1` is supplied.

After reconfiguration, reboot to reach the graphical login manager. Bluetooth command-line checks:

```sh
bluetoothctl list
bluetoothctl show
bluetoothctl scan on
```

## Configuration variants and versions

| File | Marker | Purpose |
|---|---|---|
| `config.scm` | `v1.0.2` | minimal lobby originally installed |
| `config-network.scm` | `v1.1.0` | network manager and wireless, Linux-libre |
| `config-network-nonguix.scm` | `v1.2.0` | network plus non-libre kernel and firmware |
| `config-kde.scm` | `v1.3.0` | KDE/SDDM/Bluetooth with Nonguix |

Every variant prints its marker before reconfiguration. For each later change, increment the corresponding version marker and `Change:` comment in the repository.

## Primary references

- [GNU Guix documentation](https://guix.gnu.org/manual/en/)
- [Nonguix channel](https://gitlab.com/nonguix/nonguix)
- [Codex CLI](https://github.com/openai/codex)
- [OpenCode CLI](https://opencode.ai/docs/)
- [Ollama](https://docs.ollama.com/linux)

All scripts can be downloaded individually and inspected with `sed -n '1,200p' filename`.
