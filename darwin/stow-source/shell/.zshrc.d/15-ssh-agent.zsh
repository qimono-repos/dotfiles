# ssh-agent on macOS: GUI sessions get SSH_AUTH_SOCK from launchd; tmux/SSH
# sessions from a terminal may find a stale path. Pin to launchd's socket when
# present and the current one is unusable.
# (Finder-style GUI ssh-agent persistence: load keys once via `ssh-add ~/.ssh/id_*`.)
if [[ "$(uname -s)" == "Darwin" ]]; then
  if ! ssh-add -l >/dev/null 2>&1; then
    for _sock in /tmp/com.apple.launchd.*/Listeners; do
      if [[ -S "$_sock" ]]; then
        export SSH_AUTH_SOCK="$_sock"
        break
      fi
    done
    unset _sock
  fi
fi