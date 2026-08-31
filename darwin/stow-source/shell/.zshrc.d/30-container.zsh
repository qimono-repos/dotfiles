# Apple Container + Podman helpers (macOS HOST).
if [[ "$(uname -s)" != "Darwin" ]]; then return; fi

alias dev='container machine run qi-dev'   # drop into the persistent dev machine
alias cps='container ps'
alias cmach='container machine list'
alias cpup='podman ps'

# Surface machine status quietly on each shell (only if CLI exists).
if command -v container >/dev/null 2>&1; then
  _qimono_container_status() {
    local out
    out="$(container machine list 2>/dev/null)" || return 0
    # print nothing unless the default machine is listed
    echo "$out" | grep -q qi-dev && print -P "%F{green}[container] dev machine 'qi-dev' ready%f"
  }
  precmd_functions+=(_qimono_container_status)
fi