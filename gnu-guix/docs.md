# ISO installer

https://github.com/SystemCrafters/guix-installer/releases/latest

# System Crafter's refference guide

https://systemcrafters.net/craft-your-system-with-guix/full-system-install/


# Update the system
guix pull
sudo -E guix system reconfigure ~/.config/guix/system.scm

# HINTS
hint: Consider setting the necessary environment variables by running:

     GUIX_PROFILE="/home/qi/.config/guix/current"
     . "$GUIX_PROFILE/etc/profile"

Alternately, see `guix package --search-paths -p
"/home/qi/.config/guix/current"'.


hint: After setting `PATH', run `hash guix' to make sure your shell refers to
`/home/qi/.config/guix/current/bin/guix'.

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# SSH
ssh-keygen -t ed25519 -C "your_email@example.com"
