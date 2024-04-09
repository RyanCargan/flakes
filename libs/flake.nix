{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        libraries = with pkgs; [
          xorg.libX11
          xorg.libXxf86vm
          xorg.libXrender
        ];


        packages = with pkgs; [ ] ++ libraries;

        devEnv = pkgs.mkShell {
          buildInputs = with pkgs; [ ] ++ packages; # Include the packages directly


          shellHook = with pkgs;
            ''
              # Customize the shell prompt with a pretty blue color
              PS1="\[\033[1;34m\](nix-flake: libs) \[\033[0m\]$PS1"

              # Export necessary environment variables
              export LD_LIBRARY_PATH=${stdenv.cc.cc.lib}:${lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
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
