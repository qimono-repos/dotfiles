HISTSIZE=1000
HISTFILESIZE=2000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
mkdir -p $HOME/tmp

## SSH 

if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi

ssh-add /root/.ssh/id_ed_sat_digi_us

## EXPORTS

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export DOTNET_ROOT=$HOME/dotnet
export JAVA_HOME=/usr/lib/jvm/jdk
export ANDROID_HOME=$HOME/source/repos/android-sdk
export TMPDIR=$HOME/tmp

## PATH

PATH=$PATH:/root/.local/bin
PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
PATH="$HOME/sorce/repos:$PATH"
PATH="$JAVA_HOME:$PATH"
PATH="$JAVA_HOME/bin:$PATH"
PATH="$PATH:$ANDROID_HOME/platform-tools"
PATH="$PATH:$ANDROID_HOME/cmdline-tools/bin"


## ALIAS
alias v='/root/.local/bin/lvim'
alias code='emacs'
alias cls='clear && fastfetch && echo DIGITAL OCEAN US New York'
alias gg=gg.sh

## DOTNET COMPLETION
autoload -Uz compinit
compinit

_dotnet_zsh_complete()
{
  local completions=("$(dotnet complete "$words")")

  # If the completion list is empty, just continue with filename selection
  if [ -z "$completions" ]
  then
    _arguments '*::arguments: _normal'
    return
  fi

  # This is not a variable assignment, don't remove spaces!
  _values = "${(ps:\n:)completions}"
}

compdef _dotnet_zsh_complete dotnet

## STARTUP
eval "$(oh-my-posh init zsh --config ~/.poshthemes/catppuccin.omp.json)"
#eval "$(oh-my-posh --shell zsh --config ~/.poshthemes/catppuccin.omp.json)"
#eval "$(oh-my-posh init zsh)"

clear
fastfetch 

printf "DIGITAL OCEAN US New York"
cd $HOME
chmod +x ./.secrets/secrets.sh
. ./.secrets/secrets.sh

cd $HOME/source/repos/qimono-repos/
printf  "..." 
