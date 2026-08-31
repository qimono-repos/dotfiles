# Guix profile — ONLY inside the container machine (Linux), not on macOS.
# This ~/.zshrc is mirrored into `container machine qi-dev`, so the same file
# fires on both OSes; guard hard on uname + guix presence on PATH.
if [[ "$(uname -s)" == "Linux" ]] && [[ -x "${HOME}/.guix-profile/bin/guix" ]]; then
  export GUIX_PROFILE="${HOME}/.guix-profile"
  # shellcheck disable=SC1091
  [[ -r "${GUIX_PROFILE}/etc/profile" ]] && source "${GUIX_PROFILE}/etc/profile"
fi