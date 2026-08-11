# Power aliases — sole-user fast reboot/poweroff (ignore inhibitor locks)
# Stow: shell → ~/.zshrc.d/50-power.zsh
#
# Why: GNOME blocks soft reboot when terminals have foreground jobs
# (e.g. ping, long CLI). -i = --ignore-inhibitors.
alias rebootf='sudo systemctl reboot -i'
alias powerofff='sudo systemctl poweroff -i'
