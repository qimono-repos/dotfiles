# Post-pull guix MUST win over /usr/local/bin/guix
if [[ -d "$HOME/.config/guix/current/bin" ]]; then
  path=("$HOME/.config/guix/current/bin" $path)
  export PATH
fi
if [[ -r "$HOME/.config/guix/current/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/guix/current/etc/profile"
fi

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
fi

if [[ -d "$GUIX_PROFILE/share" ]]; then
  export XDG_DATA_DIRS="$GUIX_PROFILE/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
fi
if [[ -d "$GUIX_PROFILE/lib/locale" ]]; then
  export GUIX_LOCPATH="${GUIX_LOCPATH:-$GUIX_PROFILE/lib/locale}"
fi
export LANG="${LANG:-en_US.UTF-8}"
