# Dotfiles Repository AI Instructions

## Project Context
This is a cross-platform dotfiles repository managing configuration files and setup scripts for multiple operating systems, including Linux (Ubuntu, Fedora, GNU Guix), macOS, and Windows 11. 

## General Guidelines
- **Cross-Platform Awareness:** Always consider the target OS when modifying or creating scripts/configurations. Be mindful of differences between bash, zsh, and PowerShell.
- **Idempotency:** Installation and setup scripts must be idempotent. They should safely run multiple times without causing errors or duplicating configurations (e.g., check if a tool is installed before trying to install it).
- **Non-Destructive:** Do not overwrite existing user configurations without backing them up first or prompting the user.

## Repository Structure & File Placement
- **OS-Specific Configurations:** Place configurations and scripts that are specific to an operating system in its dedicated folder (`/ubuntu`, `/fedora`, `/windows11`, `/gnu-guix`).
- **Tool-Specific Configurations:** Place cross-platform configurations for specific tools in their dedicated directories (e.g., `/zsh`, `/tmux`, `/ssh`).
- **Scripts:** General-purpose or shared scripts should go into `/scripts`. Use `.sh` for Unix-based scripts and `.ps1` for Windows PowerShell scripts.
- **Documentation:** All instructional guides and environment setups should be placed in the `/docs` directory using Markdown format.

## Scripting Best Practices
### Shell Scripts (Linux/macOS)
- Use `#!/usr/bin/env bash` or `#!/usr/bin/env zsh` as shebangs.
- Always quote variables to prevent word splitting (e.g., `"$VAR"`).
- Use `set -e` to exit on error when appropriate, but be careful in interactive configuration scripts.

### PowerShell Scripts (Windows)
- Use standard PowerShell idioms.
- Prefer explicit parameter names and avoid aliases in permanent scripts for readability.
- Ensure scripts handle execution policies gracefully.

## Documentation
- When adding a new setup script or configuration, update or add a corresponding `.md` file in `/docs`.
- Keep the `README.md` updated if major new directories or OS targets are introduced.

## Code Style
- Keep files modular and concise.
- Use comments to explain *why* a particular configuration or workaround is used, especially for OS-specific quirks.
