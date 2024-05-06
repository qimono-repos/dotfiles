# TODO add shebang here

## GUIX PACKAGES

guix install openjdk
# guix install openjdk@17.0.10

guix install 
zsh 
git 
icecat 
bat 
tree 
neovim 
gnu-tweaks 
konsole 
#java 
flatpak 
nix 
neofetch 
nix 
python
curl
wget
unzip
file
ungoogled-chromium
glibc
glibc-locales
binutils


htop
python-httplib2
python-pyparsing

clojure
docker
podman
distrobox
iptables

pkg-config


## FLATPAK PACKAGES

sudo flatpak install flathub com.microsoft.Edge -y
sudo flatpak install flathub com.google.Chrome -y
sudo flatpak install flathub com.discordapp.Discord -y
sudo flatpak install flathub com.github.IsmaelMartinez.teams_for_linux -y
sudo flatpak install flathub com.visualstudio.code -y
sudo flatpak run com.jetbrains.IntelliJ-IDEA-Community -y
flatpak run com.google.Chrome &
flatpak run com.github.IsmaelMartinez.teams_for_linux &

## Visual Studio Code authentication for Github sync

https://github.com/login/device

## Visual Studio Sdk setup

$ flatpak install flathub org.freedesktop.Sdk.Extension.dotnet
$ flatpak install flathub org.freedesktop.Sdk.Extension.golang
$ FLATPAK_ENABLE_SDK_EXT=dotnet,golang flatpak run com.visualstudio.code

## Clojure
curl -L -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh
chmod +x linux-install.sh
sudo ./linux-install.sh

### To install in a custom location

sudo ./linux-install.sh --prefix /opt/infrastructure/clojure

## Distrobox
sudo sh -c 'echo \'{"default": [{"type":"insecureAcceptAnything"}]\' > /etc/containers/policy.json'
sudo sh -c 'echo "{}" > /etc/containers/policy.json'
sudo touch /etc/gshadow
sudo grpck
distrobox create -n ubu-box -i quay.io/toolbx/ubuntu-toolbox:latest -Y

