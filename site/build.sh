#!/usr/bin/env bash

NIXPKGS_ALLOW_UNFREE=1 nix build .#myEnv --impure -o site-flake-gcroot-result
