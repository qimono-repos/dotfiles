# Login-shell PATH: post-pull guix MUST beat /usr/local/bin/guix
# (Otherwise: firefox: unknown package)
# Stow → ~/.zprofile — if you already have a real ~/.zprofile, merge manually
# or source this file from it.

if [[ -d "$HOME/.config/guix/current/bin" ]]; then
  path=("$HOME/.config/guix/current/bin" $path)
fi
if [[ -d "$HOME/.guix-profile/bin" ]]; then
  path=("$HOME/.guix-profile/bin" $path)
fi
typeset -U path PATH
export PATH
