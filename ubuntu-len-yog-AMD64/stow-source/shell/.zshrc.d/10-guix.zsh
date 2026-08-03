# Guix profile on PATH (package manager rank #1)
# Loaded via ~/.zshrc.local

# 1) guix *command* after `guix pull` (channels, new packages like nonguix firefox)
# MUST win over /usr/local/bin/guix or "firefox: unknown package"
if [[ -d "$HOME/.config/guix/current/bin" ]]; then
  path=("$HOME/.config/guix/current/bin" $path)
  export PATH
fi
if [[ -r "$HOME/.config/guix/current/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/guix/current/etc/profile"
fi

# 2) user packages (epiphany, firefox, uv, stow, …)
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"

if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
fi

# Desktop apps (GNOME app grid)
if [[ -d "$GUIX_PROFILE/share" ]]; then
  export XDG_DATA_DIRS="$GUIX_PROFILE/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
fi

# Guix locales on foreign distros (Ubuntu host)
# Needed for Qt apps from Guix (e.g. kdeconnect) — avoids ANSI_X3.4-1968 warnings
if [[ -d "$GUIX_PROFILE/lib/locale" ]]; then
  export GUIX_LOCPATH="${GUIX_LOCPATH:-$GUIX_PROFILE/lib/locale}"
fi
# Prefer UTF-8 for GUI toolkits when unset/broken
if [[ -z "${LC_ALL:-}" && -z "${LC_CTYPE:-}" ]]; then
  export LANG="${LANG:-en_US.UTF-8}"
fi
# Guix-provided locales: after glibc-locales install you may use:
#   export LC_ALL=en_US.utf8
# if host locales conflict with Guix GUI apps.

# Prefer nonguix substitutes for Firefox etc. (daemon may still need authorize + default URLs)
export GUIX_SUBSTITUTE_URLS="${GUIX_SUBSTITUTE_URLS:-https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org}"

