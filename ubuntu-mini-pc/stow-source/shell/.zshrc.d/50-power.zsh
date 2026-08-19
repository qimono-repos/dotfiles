# Power — sole-user fast reboot / poweroff (ignore GNOME inhibitor locks)
# Stow: shell → ~/.zshrc.d/50-power.zsh
#
# Why not `alias rebootf=…` + `sudo rebootf`?
#   sudo does not run shell aliases; it looks for an external binary named
#   "rebootf" and fails with "command not found". Elevation must live *inside*
#   the command you type.
#
# Why functions (not aliases)?
#   Functions can call sudo themselves. You type: too
#   Optional: install scripts/install-passwordless-power.sh so sudo asks no
#   password for these two systemctl lines only.

# too — reboot now, ignore inhibitors (GNOME "session inhibited", open terminals, …)
too() {
  sudo /usr/bin/systemctl reboot -i
}

# powerofff — same idea for poweroff
powerofff() {
  sudo /usr/bin/systemctl poweroff -i
}
