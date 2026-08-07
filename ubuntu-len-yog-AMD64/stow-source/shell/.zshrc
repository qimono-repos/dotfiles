# ~/.zshrc — interactive zsh configuration (stow-managed via ubuntu-len-yog-AMD64)
# Out-of-the-box defaults with commonly recommended options

# Only run for interactive shells
[[ $- != *i* ]] && return

# ---------------------------------------------------------------------------
# PATH (login-shell paths that may not be set in non-login terminals)
# ---------------------------------------------------------------------------
typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.grok/bin"
  /usr/lib/dotnet
  $path
)
export PATH

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt APPEND_HISTORY          # append rather than overwrite
setopt INC_APPEND_HISTORY      # write each command as it is entered
setopt SHARE_HISTORY           # share history across sessions
setopt HIST_IGNORE_DUPS        # ignore consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS    # drop older duplicate when adding
setopt HIST_IGNORE_SPACE       # commands starting with space are not saved
setopt HIST_REDUCE_BLANKS      # trim superfluous blanks
setopt HIST_VERIFY             # show expanded history before running
setopt EXTENDED_HISTORY        # record timestamps (":start:elapsed;command")

# ---------------------------------------------------------------------------
# Shell options (quality-of-life)
# ---------------------------------------------------------------------------
setopt AUTO_CD                 # `subdir` == `cd subdir`
setopt AUTO_PUSHD              # cd pushes old dir onto stack
setopt PUSHD_IGNORE_DUPS       # don't push duplicates
setopt PUSHD_SILENT            # don't print stack after pushd/popd
setopt CORRECT                 # gentle command correction
setopt INTERACTIVE_COMMENTS    # allow # comments in interactive shells
setopt NO_BEEP                 # silence terminal beep
setopt EXTENDED_GLOB           # richer globbing (#, ~, ^)
setopt GLOB_DOTS               # match dotted files in globs (still not . / ..)
setopt COMPLETE_IN_WORD        # complete from cursor position
setopt ALWAYS_TO_END           # move cursor to end after completion
setopt PATH_DIRS               # perform path search even on command names with /
setopt PROMPT_SUBST            # allow expansions in prompt

# ---------------------------------------------------------------------------
# Completion system
# ---------------------------------------------------------------------------
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${HOME}/.zcompcache"
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' rehash true

# ---------------------------------------------------------------------------
# Key bindings (emacs-style)
# ---------------------------------------------------------------------------
bindkey -e

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search   # Up
bindkey '^[[B' down-line-or-beginning-search # Down
bindkey '^P'   up-line-or-beginning-search
bindkey '^N'   down-line-or-beginning-search

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# ---------------------------------------------------------------------------
# Colors for ls / grep
# ---------------------------------------------------------------------------
if [[ -x /usr/bin/dircolors ]]; then
  if [[ -r "${HOME}/.dircolors" ]]; then
    eval "$(dircolors -b "${HOME}/.dircolors")"
  else
    eval "$(dircolors -b)"
  fi
fi

# ---------------------------------------------------------------------------
# Prompt (Oh My Posh fallback to standard zsh prompt)
# ---------------------------------------------------------------------------
if command -v oh-my-posh >/dev/null 2>&1; then
  if [[ -f "$HOME/.config/oh-my-posh/catppuccin.omp.json" ]]; then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/catppuccin.omp.json")"
  else
    eval "$(oh-my-posh init zsh)"
  fi
else
  autoload -Uz vcs_info
  precmd_vcs_info() { vcs_info }
  precmd_functions+=(precmd_vcs_info)
  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:git:*' formats ' (%b)'
  zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'
  PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f%# '
  RPROMPT='%F{244}%D{%H:%M:%S}%f'
fi

# Set terminal title to user@host:cwd
autoload -Uz add-zsh-hook
_set_title() {
  print -Pn "\e]0;%n@%m: %~\a"
}
add-zsh-hook precmd _set_title

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias d='dirs -v'
alias ..='cd ..'
alias ...='cd ../..'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias e=emacs
alias vi=nvim
alias cls=clear

# ---------------------------------------------------------------------------
# Plugins (zsh-autosuggestions, zsh-syntax-highlighting)
# ---------------------------------------------------------------------------
if [[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
fi

if [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ---------------------------------------------------------------------------
# Sourcing machine pack local snippets (.zshrc.local & .zshrc.d/*)
# ---------------------------------------------------------------------------
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"

export PATH="$HOME/.bun/bin:$PATH"
[[ -f "/home/qi/vega/env" ]] && source "/home/qi/vega/env"
export PATH="/home/qi/.local/bin:$PATH"
