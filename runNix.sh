#!/usr/bin/env sh

runNix() (
    # Run a command inside Nix environment
    command=$*
    echo $command | nix-user-chroot ~/.nix bash -l
)
runNix $*