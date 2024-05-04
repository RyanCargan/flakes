{
  inputs = {
    nixpkgs.url = "nixpkgs";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        lib = nixpkgs.lib;
        # Use stable channel packages
        # pkgs = nixpkgs.legacyPackages.${system};
        # Use unstable channel packages
        pkgs = nixpkgs-unstable.legacyPackages.${system};

        # Overrides
        torchOverride = pkgs.python3Packages.torch.override { cudaSupport = true; };
        torchSdeOverride = pkgs.python3Packages.torchsde.override { torch = torchOverride; };
        torchVisionOverride = pkgs.python3Packages.torchvision.override { torch = torchOverride; };
        torchAudioOverride = pkgs.python3Packages.torchaudio.override { torch = torchOverride; };
        transformersOverride = pkgs.python3Packages.transformers.override {
          torch = torchOverride;
          torchvision = torchVisionOverride;
          torchaudio = torchAudioOverride;
        };
        safetensorsOverride = pkgs.python3Packages.safetensors.override { torch = torchOverride; };
        korniaOverride = pkgs.python3Packages.kornia.override { torch = torchOverride; };

        python = (pkgs.python3.withPackages (ps: with ps; [
          torchOverride
          torchSdeOverride
          torchVisionOverride
          torchAudioOverride
          einops
          transformersOverride
          safetensorsOverride
          aiohttp
          pyyaml
          pillow
          scipy
          tqdm
          psutil
          korniaOverride
        ])).override (args: { ignoreCollisions = true; });

        libraries = with pkgs; [
          cudaPackages.cudatoolkit # pkg/lib combo
          # cudaPackages.cudnn
          # cudaPackages.libcublas
          # cudaPackages.libcufft
          # cudaPackages.libcurand
          # cudaPackages.libcusolver
          # cudaPackages.libcusparse
          # linuxHeaders
        ];

        packages = with pkgs; [
          python
        ] ++ libraries;

        devEnv = pkgs.mkShell {
          buildInputs = packages; # Include the packages directly

          shellHook =
            ''
              # Customize the shell prompt with a pretty blue color
              PS1="\[\033[1;34m\](nix-flake: sd) \[\033[0m\]$PS1"

              # Export necessary environment variables
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
              export PATH=${pkgs.cudaPackages.cudatoolkit}/bin:${python}/bin:$PATH # Add CUDA toolkit to PATH for nvcc to avoid PTXAS errors
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
