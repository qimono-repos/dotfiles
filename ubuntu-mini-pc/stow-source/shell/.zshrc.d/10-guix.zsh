# Guix last on the interactive PATH so developer python/uv/jupyter are Guix.
# Apt /usr/bin/python3 stays on disk for Ubuntu shebangs.

# 1) guix *command* after `guix pull`
if [[ -d "$HOME/.config/guix/current/bin" ]]; then
  path=("$HOME/.config/guix/current/bin" $path)
  export PATH
fi
if [[ -r "$HOME/.config/guix/current/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/guix/current/etc/profile"
fi

# 2) user packages (python, uv, jupyter, stow, emacs, …)
export GUIX_PROFILE="${HOME}/.guix-profile"

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

# Wheels (NumPy, Aer) dlopen libz / libstdc++ from the Guix profile
if [[ -d "$GUIX_PROFILE/lib" ]]; then
  export LD_LIBRARY_PATH="$GUIX_PROFILE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

if [[ -f "/etc/ssl/certs/ca-certificates.crt" ]]; then
  export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
  export SSL_CERT_DIR="${SSL_CERT_DIR:-/etc/ssl/certs}"
  export GIT_SSL_CAINFO="${GIT_SSL_CAINFO:-/etc/ssl/certs/ca-certificates.crt}"
fi
