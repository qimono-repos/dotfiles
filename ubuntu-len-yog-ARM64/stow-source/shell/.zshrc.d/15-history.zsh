# History — fleet baseline: keep at least the last 1000 commands across sessions
# Stow package: shell → ~/.zshrc.d/15-history.zsh
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=1000
SAVEHIST=1000

# Write history as you go and share it across shells
setopt APPEND_HISTORY          # append to HISTFILE, don't overwrite
setopt INC_APPEND_HISTORY      # save each command as soon as it runs
setopt SHARE_HISTORY           # import new lines from HISTFILE in other sessions

# Quality-of-life history filters
setopt HIST_IGNORE_DUPS        # skip consecutive duplicate commands
setopt HIST_IGNORE_SPACE       # ignore lines that start with a space
setopt HIST_REDUCE_BLANKS      # strip superfluous blanks
setopt HIST_VERIFY             # expand history (!!) for edit before running
