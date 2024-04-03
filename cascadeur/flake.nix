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
          libxml2
          krb5
          xorg.libxcb
          qt5.qtbase
        ];


        packages = with pkgs; [ ] ++ libraries;

        devEnv = pkgs.mkShell {
          buildInputs = with pkgs; [ ] ++ packages; # Include the packages directly
          nativeBuildInputs = with pkgs; [
            # qt5.wrapQtAppsHook
          ];


          shellHook = with pkgs;
            ''
              # Customize the shell prompt with a pretty blue color
              PS1="\[\033[1;34m\](nix-flake: compcode) \[\033[0m\]$PS1"

              # Export necessary environment variables
              export DISPLAY=:0
              export LD_LIBRARY_PATH=${lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
              export QT_DEBUG_PLUGINS=1
              export QT_QPA_PLATFORM_PLUGIN_PATH=“${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins”;
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
