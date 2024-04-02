{
  inputs = {
    nixpkgs.url = "nixpkgs";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    chrome.url = "github:r-k-b/browser-previews";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, chrome }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Use stable channel packages
        pkgs = nixpkgs.legacyPackages.${system};
        # Use unstable channel packages
        # pkgs = nixpkgs-unstable.legacyPackages.${system};

        # Overrides
        # numbaOverride = pkgs.python3Packages.numba.override { cudaSupport = true; };

        packages = with pkgs; [
          chrome.packages.x86_64-linux.google-chrome-dev
          pypy3
          libpcap
          xorg.libXxf86vm.dev
        ];
        inputsFrom = with pkgs; [
          libpcap
          xorg.libXxf86vm.dev
        ];

        devEnv = pkgs.mkShell {
          buildInputs = packages; # Include the packages directly

          shellHook =
            ''
              # Customize the shell prompt with a pretty blue color
              PS1="\[\033[1;34m\](nix-flake: compcode) \[\033[0m\]$PS1"

              # Export necessary environment variables
              export PATH=${pkgs.pypy3}/bin:$PATH
            '';
        };
      in
      {
        devShell = devEnv;

        packages = {
          myEnv = devEnv;
        };
      });
}
