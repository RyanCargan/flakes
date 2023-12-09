{
  description = "A versatile Nix flake for development and packaging";

  inputs = {
    nixpkgs.url = "nixpkgs";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Use stable channel packages
        pkgs = nixpkgs.legacyPackages.${system};
        # Use unstable channel packages
        # pkgs = nixpkgs-unstable.legacyPackages.${system};

        # Custom packages or overrides
        customPackages = with pkgs; [
          # Add custom packages or overrides here
          # Example: numbaOverride
        ];

        # Development environment
        devEnv = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.bashInteractive ];
          buildInputs = with pkgs; [
            nodePackages.prisma
            nodePackages.npm
            nodejs-slim
            # Include other packages needed for development
          ];

          shellHook = ''
            # Customize the shell prompt with a pretty blue color
            PS1="\[\033[1;34m\](nix-flake: webstack) \[\033[0m\]$PS1"

            # Export necessary environment variables
            export PRISMA_MIGRATION_ENGINE_BINARY="${pkgs.prisma-engines}/bin/migration-engine"
            export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
            export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
            export PRISMA_INTROSPECTION_ENGINE_BINARY="${pkgs.prisma-engines}/bin/introspection-engine"
            export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
          '';
        };
      in
      {
        devShell = devEnv;

        packages = {
          myEnv = devEnv; # Make the dev environment available as a package
          # Additional packages can be added here
        };
      });
}
