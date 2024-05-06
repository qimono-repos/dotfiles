# THE DOCS
## ISO installer

https://github.com/SystemCrafters/guix-installer/releases/latest

## System Crafter's refference guide

https://systemcrafters.net/craft-your-system-with-guix/full-system-install/


## Update the system
guix pull
sudo -E guix system reconfigure ~/.config/guix/system.scm

## HINTS
hint: Consider setting the necessary environment variables by running:

     GUIX_PROFILE="/home/qi/.config/guix/current"
     . "$GUIX_PROFILE/etc/profile"

Alternately, see `guix package --search-paths -p
"/home/qi/.config/guix/current"'.


hint: After setting `PATH', run `hash guix' to make sure your shell refers to
`/home/qi/.config/guix/current/bin/guix'.

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

## SSH
ssh-keygen -t ed25519 -C "your_email@example.com"

## ROOT

$ export GUIX_PROFILE="/root/.guix-profile"
$ . "$GUIX_PROFILE/etc/profile"

$ cat /etc/subuid
qi:10000:65536
$ cat /etc/subgid
qi:10000:65536

## PODMAN
$ podman network ls
NETWORK ID    NAME        DRIVER
2f259bab93aa  podman      bridge

$ sudo modprobe iptable_nat

### Run the container 

podman run -it --privileged --network podman quay.io/toolbx/ubuntu-toolbox:latest

apt-get install -y curl git unzip xz-utils zip libglu1-mesa

apt install -y snapd (won't work without systemd)
snap install flutter --classic  (only after runing successfuly systemctl start snapd)

- while runing the conatiner in other terminal

$ podman ps
CONTAINER ID  IMAGE                                 COMMAND     CREATED         STATUS         PORTS       NAMES
35852ade38a2  quay.io/toolbx/ubuntu-toolbox:latest  /bin/bash   15 seconds ago  Up 15 seconds              dreamy_cerf

$ distrobox enter dreamy_cerf
Error: unable to find user qi: no matching entries in passwd file

$ podman exec -it dreamy_cerf /bin/bash
root@35852ade38a2:/# whoami
root

- creating the distrobox with a existing image

qi@qimono-host ~  podman ps
CONTAINER ID  IMAGE                                 COMMAND     CREATED         STATUS         PORTS       NAMES
35852ade38a2  quay.io/toolbx/ubuntu-toolbox:latest  /bin/bash   26 minutes ago  Up 26 minutes              dreamy_cerf
qi@qimono-host ~  distrobox-create --name u-box --image quay.io/toolbx/ubuntu-toolbox:latest
Creating 'u-box' using image quay.io/toolbx/ubuntu-toolbox:latest        [ OK ]
Distrobox 'u-box' successfully created.
To enter, run:

distrobox enter u-box
