# ALIAS 
alias v='nvim'
alias e='emacs -q -l ~/.config/emacs/init.el'
alias edge='flatpak run com.microsoft.Edge'
alias chr='flatpak run com.google.Chrome'
alias teams="flatpak run com.github.IsmaelMartinez.teams_for_linux &"
alias vz='nvim ~/.zshrc'
alias ez='emacs -q -l ~/.config/emacs/init.el ~/.zshrc'
alias ei='emacs -q -l ~/.config/emacs/init.el ~/.config/emacs/init.el'
alias sou='source ~/.zshrc'
alias ll='ls -la'
alias discord='flatpak run com.discordapp.Discord &'
alias code='flatpak run com.visualstudio.code'
alias start='chr & ' #TODO convert to startup script
alias clj='java -jar $(guix build clojure)/share/java/clojure-1.11.1.jar'
## alias h='$HOME'

# ENVIRONMENT VARIABLES

GUIX_PROFILE="$HOME/.config/guix/current"
. "$GUIX_PROFILE/etc/profile"
GUIX_PROFILE="$HOME/.guix-profile"
. "$GUIX_PROFILE/etc/profile"

export SDK_ROOT="/home/qi/android-sdk/cmdline-tools/latest/bin"

export PATH="$PATH:$HOME/bin" 
export PATH="$PATH:$HOME/development/gh_2.46.0_linux_amd64/bin"
export PATH="$PATH:$HOME/bin/VSCode-linux-x64/bin"
export PATH="${GUIX_PROFILE:-/gnu/store/551yflyffsirx5jm9jnqpwl2izshx3yb-profile}/bin${PATH:+:}$PATH"
export PATH="$PATH:$(guix build clojure)/share/java"
export PATH="$PATH:$SDK_ROOT" #be aware of order: other tool can define a previus path, or this can override a new tool setup


export EDITOR='$HOME/.guix-profile/bin/nvim'

XDG_DATA_DIRS="$XDG_DATA_DIRS:$HOME/.local:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/export/share"

export GUIX_LOCPATH=$HOME/.guix-profile/lib/locale
# 
eval "$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json')"

# STARTUP

## tmux
neofetch --disable uptime


