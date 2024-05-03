#!/usr/bin/env bash

# Set environment variables to control the build process
export NIXPKGS_ALLOW_UNFREE=1    # Allow building packages with non-free licenses
export NIX_BUILD_CORES=4         # Limit the number of cores per build
export MAKEFLAGS="-j4"           # Limit the number of jobs for make

# Run the Nix build with additional options for job control
nix build .#myEnv --impure -o sd-flake-gcroot-result --max-jobs 4
