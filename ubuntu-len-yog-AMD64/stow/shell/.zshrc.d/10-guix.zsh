# Guix profile on PATH (package manager rank #1)
# Loaded via ~/.zshrc.local

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"

if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
fi

# Guix locales on foreign distros (Ubuntu host)
if [[ -d "$GUIX_PROFILE/lib/locale" ]]; then
  export GUIX_LOCPATH="${GUIX_LOCPATH:-$GUIX_PROFILE/lib/locale}"
fi

# Current guix after `guix pull`
if [[ -r "$HOME/.config/guix/current/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/guix/current/etc/profile"
fi
