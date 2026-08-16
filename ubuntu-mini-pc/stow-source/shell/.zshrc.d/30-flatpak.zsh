# Guix-owned Flatpak: export desktop files from ~/.local/share/flatpak.
# The package ships this snippet; source it if present. Do not apt-install
# a second flatpak.

if [[ -r "${GUIX_PROFILE:-$HOME/.guix-profile}/etc/profile.d/flatpak.sh" ]]; then
  # shellcheck disable=SC1091
  source "${GUIX_PROFILE:-$HOME/.guix-profile}/etc/profile.d/flatpak.sh"
fi

# Ubuntu AppArmor blesses only /usr/bin/bwrap (see docs/flatpak-guix.md).
# Guix store bwrap lands in profile unprivileged_userns and dies (ldconfig 256).
# This is foreign-distro only; a future Guix System should not need it.
if [[ -x /usr/bin/bwrap ]]; then
  export FLATPAK_BWRAP="${FLATPAK_BWRAP:-/usr/bin/bwrap}"
fi

