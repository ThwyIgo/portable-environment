#!/usr/bin/env sh

# Script to install nix on (hopefully) any GNU/linux system without root privileges.
# https://github.com/DavHau/nix-portable
# This script was tested on Ubuntu 22.04

BINSPATH=~/.local/bin
FONTS_DIR=~/.local/share/fonts
PATH=$BINSPATH:$PATH

# Color variables
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"

#### Functions ####

toLower() (
    echo $1 | tr '[:upper:]' '[:lower:]'
)

askYesNo() (
    # Return 1 for true or 0 for false
    # Arguments: <Message> <default value (true | false)>
    QUESTION=$1
    DEFAULT=$2
    if [ "$DEFAULT" = "true" ]; then
            OPTIONS="[Y/n]"
            DEFAULT="y"
        elif [ "$DEFAULT" = "false" ]; then
            OPTIONS="[y/N]"
            DEFAULT="n"
    else
	    OPTIONS="[y/n]"
	    DEFAULT="none"
    fi
    read -p "$QUESTION $OPTIONS " -r INPUT
    #If $INPUT is empty, use $DEFAULT
    INPUT=${INPUT:-$DEFAULT}
    INPUT=$(toLower $INPUT)
    if [ "$INPUT" = "y" ]; then
        return 1
        elif [ "$INPUT" = "n" ]; then
        return 0
    else
	    printf "Error. Type \"y\" or \"n\"\n"
	    askYesNo "$1" "$2"
    fi
)

show_help() {
    printf "Usage: %s [OPTIONS]...\n" $0
    printf "Running this script without args will install nix\n\n"
    printf "[OPTIONS]
-n\tSkip Nix installation
-h\tHelp (show this message)\n"

    exit
}

## Tasks functions
installFonts() {
    printf "Installing Fira Code font\n"
    file="Fira_Code.zip"
    if [ ! -d ${FONTS_DIR} ]; then
        mkdir -p ${FONTS_DIR}
    fi

    curl -s https://api.github.com/repos/tonsky/FiraCode/releases/latest |
    grep "tag_name" |
    awk '{print "https://github.com/tonsky/FiraCode/releases/download/" substr($2, 2, length($2)-3) "/Fira_Code_v" substr($2, 2, length($2)-3) ".zip"}' |
    wget -i - -O $file
    unzip -o -q -d $FONTS_DIR $file

    fc-cache -f
}

#### ENTRYPOINT #####
#### Checking the system #####

if ! ([ $(unshare --user --pid echo YES) = "YES" ] || [ $(echo -n "$( zgrep CONFIG_USER_NS /proc/config.gz )" | tail -c 1) = 'y' ] || [ $(echo -n "$( grep CONFIG_USER_NS /boot/config-$(uname -r) )" | tail -c 1) = 'y' ]); then
    printf "The kernel does not support user namespaces. Installation failed.\n"
    exit
fi

mkdir -p $BINSPATH

#### Parsing CL args ####

INSTALL_NIX=1
while getopts hn OPT
do
    case $OPT in
    h)  show_help
        exit ;;
    n)  INSTALL_NIX=0
        ;;
    ?)  printf "Type %s -h for help\n" $0
        exit 2 ;;
    esac
done
shift "$((OPTIND - 1))"

#### Instalation ####

# Installing Nix
if [ $INSTALL_NIX -eq 1 ]; then
    printf "Installing Nix...\n"

    # Downloading the lastest nix-portable realease from github. (May break if the release name changes)
    curl -s https://api.github.com/repos/DavHau/nix-portable/releases/latest |
	grep "tag_name" |
	awk '{print "https://github.com/DavHau/nix-portable/releases/download/" substr($2, 2, length($2)-3) "/nix-portable"}' |
	wget -i - -O nix-portable
    # Check if file exists and it's size to be sure it isn't an empty file
    if [ ! -e ./nix-portable ] || [ $(du --apparent-size --block-size=1 "nix-portable" | awk '{ print $1}') -le 1 ]; then
	printf "It was not possible to retrieve the nix-portable binary.\n" >&2
	exit
    fi
    chmod u+x ./nix-portable
    mkdir -p $BINSPATH
    mv ./nix-portable $BINSPATH

    # Convenience script to install packages
    printf "#!/usr/bin/env sh

if [ \$# -ne 2 ]; then
    printf \"Usage: \$0 [PKGNAME] [EXECUTABLENAME]\\n\"
    exit 1
fi

printf \"$BINSPATH/nix-portable nix-shell -p \$1 --run \$2\" > $BINSPATH/\$2
chmod u+x $BINSPATH/\$2
" > $BINSPATH/nixp-install
    chmod u+x $BINSPATH/nixp-install
fi
