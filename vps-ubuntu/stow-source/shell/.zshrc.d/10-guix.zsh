# GNU Guix current command and user profile.
if [[ -d "$HOME/.config/guix/current/bin" ]]; then
  path=("$HOME/.config/guix/current/bin" $path)
  export PATH
fi
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
if [[ -r "$HOME/.config/guix/current/etc/profile" ]]; then
  source "$HOME/.config/guix/current/etc/profile"
fi
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  source "$GUIX_PROFILE/etc/profile"
fi
export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
export SSL_CERT_DIR="${SSL_CERT_DIR:-/etc/ssl/certs}"
