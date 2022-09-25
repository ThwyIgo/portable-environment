#!/usr/bin/env bash

function runNix {
    # Run a command inside Nix environment
    local command=$1
    echo $command
    echo $command | nix-user-chroot ~/.nix bash -l
}

runNix $1