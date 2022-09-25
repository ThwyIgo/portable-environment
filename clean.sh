#!/usr/bin/env bash

# Warning: This script will remove your ~/.emacs.d/

# Remove Nix
chmod -R u+rw ~/.nix && rm -rf ~/.nix ~/.nix-profile ~/.nix-defexpr/ ~/.nix-channels ~/.local/bin/nix-user-chroot ~/.local/bin/runNix.sh
# Remove Fira Code
rm ~/.local/share/fonts/ttf/FiraCode-* ~/.local/share/fonts/variable_ttf/FiraCode-* ~/.local/share/fonts/woff/FiraCode-* ~/.local/share/fonts/woff2/FiraCode-* ~/.local/share/fonts/{fira_code.css,README.txt,specimen.html}
# Remove emacs
rm -rf ~/.emacs.d/ ~/.local/share/applications/emacs-nix.*
# Remove Icons
rm -rf ~/.local/share/icons/