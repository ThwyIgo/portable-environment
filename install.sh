#!/usr/bin/env bash

# Script to install Emacs on (hopefully) any system without root privileges.
# It uses Nix (package manager)
# https://github.com/nix-community/nix-user-chroot
# Uninstall nix:
# chmod -R u+rw ~/.nix && rm -rf ~/.nix ~/.nix-profile ~/.nix-defexpr/ ~/.nix-channels ~/.local/bin/nix-user-chroot
# Remove Fira Code font:
# rm ~/.local/share/fonts/ttf/FiraCode-* ~/.local/share/fonts/variable_ttf/FiraCode-* ~/.local/share/fonts/woff/FiraCode-* ~/.local/share/fonts/woff2/FiraCode-* ~/.local/share/fonts/{fira_code.css,README.txt,specimen.html}
# This thing was tested on Ubuntu

DIR=~/.nix
CHROOTDIR=~/.local/bin

# Color variables
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# Functions
function askYesNo {
    # Return 1 for true or 0 for false
    # Arguments: <Message> <default value (true | false)>
    local QUESTION=$1
    local DEFAULT=$2
    if [ "$DEFAULT" = true ]; then
            OPTIONS="[Y/n]"
            DEFAULT="y"
        elif [ "$DEFAULT" = false ]; then
            OPTIONS="[y/N]"
            DEFAULT="n"
    else
	local OPTIONS="[y/n]"
	DEFAULT="none"
    fi
    read -p "$QUESTION $OPTIONS " -n 1 -s -r INPUT
    #If $INPUT is empty, use $DEFAULT
    local INPUT=${INPUT:-${DEFAULT}}
    echo ${INPUT}
    if [[ "$INPUT" =~ ^[yY]$ ]]; then
        return 1
        elif [[ "$INPUT" =~ ^[nN]$ ]]; then
        return 0
    else
	echo "Error. Type \"y\" or \"n\""
	askYesNo "$1" "$2"
    fi
}

if ! ([[ $(unshare --user --pid echo YES) = "YES" ]] || [[ $(echo -n "$( zgrep CONFIG_USER_NS /proc/config.gz )" | tail -c 1) = 'y' ]] || [[ $(echo -n "$( grep CONFIG_USER_NS /boot/config-$(uname -r) )" | tail -c 1) = 'y' ]]); then
    echo "The kernel does not support user namespaces. Installation failed."
    exit
fi

# Check if all required packages are installed
reqpkg=(curl grep awk wget unzip) ;
installed_pkg=( $(which ${reqpkg[@]} | awk -F/ '{ print $NF }') )
if [ "${installed_pkg[*]}" != "${reqpkg[*]}" ]; then
    # Array subtraction
    diff(){
	awk 'BEGIN{RS=ORS=" "}
       {NR==FNR?a[$0]++:a[$0]--}
       END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
    }
    #reqpkg - installed_pkg
    not_installed_pkg=($(diff reqpkg[@] installed_pkg[@]))
    echo -e "${RED}The following packages were not found in your system:${NC} ${not_installed_pkg[@]}"
    echo "Please, install them and try again."
    exit
fi

echo "The installation will be performaned on $DIR and $CHROOTDIR"
askYesNo "Continue?" true
if [ $? -eq 0 ]; then
    echo "The installation was canceled."
    exit
fi

# Downloading the lastest Nix realease from github. (May break if the release name changes)
curl -s https://api.github.com/repos/nix-community/nix-user-chroot/releases/latest |
    grep "tag_name" |
    awk '{print "https://github.com/nix-community/nix-user-chroot/releases/download/" substr($2, 2, length($2)-3) "/nix-user-chroot-bin-" substr($2, 2, length($2)-3) "-x86_64-unknown-linux-musl"}' |
    wget -i - -O nix-user-chroot
if [ ! -e ./nix-user-chroot ]; then
    echo "It was not possible to retrieve the nix-user-chroot binary."
    exit
fi

chmod u+x ./nix-user-chroot
mkdir -p $CHROOTDIR
mv ./nix-user-chroot $CHROOTDIR

if [[ ! "$PATH" = *$(echo $CHROOTDIR)* ]]; then
    echo "Updating \$PATH..."
    echo -e "\nexport PATH=$CHROOTDIR:\$PATH" >> ~/.bashrc
    PATH=$CHROOTDIR:$PATH
    echo "It is recommended to restart your terminal emulator or source ~/.bashrc to changes take effect!"
fi

echo -e "${BLUE}Installing fonts...${NC}"
fonts_dir="${HOME}/.local/share/fonts"
if [ ! -d "${fonts_dir}" ]; then
    echo "mkdir -p $fonts_dir"
    mkdir -p "${fonts_dir}"
else
    echo "Found fonts dir $fonts_dir"
fi
version=5.2
zip=Fira_Code_v${version}.zip
curl --fail --location --show-error https://github.com/tonsky/FiraCode/releases/download/${version}/${zip} --output ${zip}
unzip -o -q -d ${fonts_dir} ${zip}
rm ${zip}
rm ~/.local/share/fonts/{README.txt,specimen.html}
echo "fc-cache -f"
fc-cache -f

# Installing Nix
mkdir -m 0755 ~/.nix
nix-user-chroot ~/.nix bash -c "curl -L https://nixos.org/nix/install | bash"
# Inside nix-chroot...
nix-user-chroot ~/.nix bash -l <<"EOT"
nix-env -iA nixpkgs.emacs
mkdir -p ~/.emacs.d/pkgs
curl -s -L https://raw.githubusercontent.com/mickeynp/ligature.el/master/ligature.el > ~/.emacs.d/pkgs/ligature.el
curl -s -L https://raw.githubusercontent.com/ThwyIgo/dotfiles/main/.emacs.d/init.el > ~/.emacs.d/init.el
emacs
EOT
echo -e "${GREEN}To enter nix env, type 'nix-user-chroot ~/.nix bash -l'${NC}"

exit