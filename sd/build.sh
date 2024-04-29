#!/usr/bin/env bash

NIXPKGS_ALLOW_UNFREE=1 nix build .#myEnv --impure -o sd-flake-gcroot-result
