#!/usr/bin/env bash

function runNix {
    # Run a command inside Nix environment
    local command=$*
    echo $command | nix-user-chroot ~/.nix bash -l
}

runNix $*