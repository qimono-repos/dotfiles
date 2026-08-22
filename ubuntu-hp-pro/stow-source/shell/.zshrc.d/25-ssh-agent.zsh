# Deterministic ssh-agent socket for GUI *and* bare-metal TTY sessions.
# Trap (2026-08-21): gcr-ssh-agent overwrites the manager-wide SSH_AUTH_SOCK
# during GNOME login; its socket (/run/user/$UID/gcr/ssh) only exists inside
# the graphical session, so TTY shells inherited a dead path and pushes died
# with "Could not open a connection to your authentication agent".
# ssh-agent.socket (systemd --user, enabled) listens on openssh_agent in
# EVERY session type — pin shells to it when present.
if [[ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/openssh_agent" ]]; then
  export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/openssh_agent"
fi
