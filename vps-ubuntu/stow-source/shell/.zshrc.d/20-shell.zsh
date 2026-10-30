# Practical VPS defaults
setopt AUTO_CD INTERACTIVE_COMMENTS
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_REDUCE_BLANKS SHARE_HISTORY
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias vi='nvim'
