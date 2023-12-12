#!/usr/bin/env bash

# Get the name of the current directory
dir=$(basename "$PWD")

# Navigate to the flake directory
cd ../flakes/$dir

# Activate the flake
NIXPKGS_ALLOW_UNFREE=1 nix develop --impure

# The script will end here, and you'll remain in the last directory navigated to by the script.
