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
        pkgs = nixpkgs.legacyPackages.${system};
        # Use unstable channel packages
        # pkgs = nixpkgs-unstable.legacyPackages.${system};

        # Overrides
        tensorflowOverride = pkgs.python3Packages.tensorflow.override { cudaSupport = true; };
        torchOverride = pkgs.python3Packages.torch.override { cudaSupport = true; };
        torchVisionOverride = pkgs.python3Packages.torchvision.override { torch = torchOverride; };
        opencv4Override = pkgs.python3Packages.opencv4.override { enableCuda = true; };
        customCudnn = pkgs.cudaPackages.cudnn.overrideAttrs (oldAttrs: {
          postFixup = if pkgs.lib.versionAtLeast oldAttrs.version "8.0.5" then ''
            patchelf $out/lib/libcudnn.so --add-needed libcudnn_cnn_infer.so
            patchelf $out/lib/*.so --add-needed libcublas.so.11
            patchelf $out/lib/*.so --add-needed libcublasLt.so.11
          '' else "";
        });
        jaxlibOverride = pkgs.python3Packages.jaxlib.override {
          cudaSupport = true;
        };

        # Define the jaxtyping package
        jaxtyping = pkgs.python3Packages.buildPythonPackage rec {
          pname = "jaxtyping";
          version = "0.2.20";
          format = "pyproject";

          src = pkgs.python3Packages.fetchPypi {
            inherit version;
            inherit pname;
            sha256 = "3CvRXgCy84rF3cAtOouwIC8XA62RAx6RS8d6do2duMU=";
          };

          buildInputs = [
            pkgs.python3Packages.hatchling
            pkgs.python3Packages.numpy
            pkgs.python3Packages.typeguard
            pkgs.python3Packages.typing-extensions
          ];
        };

        # Define the equinox package
        equinox = pkgs.python3Packages.buildPythonPackage rec {
          pname = "equinox";
          version = "0.10.1";
          # format = "pyproject"; # Comment out for setup.py, setuptools may be another option.

          src = pkgs.python3Packages.fetchPypi {
            inherit version;
            inherit pname;
            sha256 = "468UMuOQmt08bl0MDmxRzedXTfrxFUz9n58DX921TfQ=";
          };

          buildInputs = [
            pkgs.python3Packages.hatchling
            pkgs.python3Packages.jax
            jaxtyping
            pkgs.python3Packages.typing-extensions
            pkgs.python3Packages.typeguard
          ];

          doCheck = false; # Disable the check/test phase
        };

        # Define the Gooey package
        Gooey = pkgs.python3Packages.buildPythonPackage rec {
          pname = "Gooey";
          version = "1.0.8.1";

          src = pkgs.python3Packages.fetchPypi {
            inherit version;
            inherit pname;
            sha256 = "CNa/U09NUNUNr7pc/Gjc8xpunu7xOpTL4+oXxORcRnE=";
          };

          buildInputs = [
            pkgs.python3Packages.wxPython_4_2
            pkgs.python3Packages.pygtrie
            pkgs.python3Packages.colored
            pkgs.python3Packages.psutil
          ];

          doCheck = false; # Disable the check/test phase, since it seems to require an X display
        };

        python = pkgs.python3.withPackages (ps: with ps; [
          # General dependencies
          numpy typing-extensions jax optax jaxlibOverride fastapi psycopg2 pyautogui opencv4Override tesserocr pillow

          # Gooey and its dependencies
          Gooey psutil colored pygtrie wxPython_4_2

          # GUI libraries
          pygobject3 pyside6 pynput

          # Data loading utilities for JAX
          torchOverride
          torchVisionOverride
          # torchvision

          # Machine learning
          tensorflowOverride
          transformers
          sentencepiece
          pandas

          # Visualization
          matplotlib

          # Simulation
          pyglet pygame pybullet pyopengl

          # Equinox and its dependencies
          equinox jaxtyping typeguard

          # PDF manipulation
          pdf2image

          # DOCX manipulation
          python-docx

          # Anki
          genanki
        ]);

        libraries = with pkgs; [
          cudaPackages.cudatoolkit # pkg/lib combo
          customCudnn
          cudaPackages.libcublas
          cudaPackages.libcufft
          cudaPackages.libcurand
          cudaPackages.libcusolver
          cudaPackages.libcusparse
          # linuxHeaders
        ];

        packages = with pkgs; [
          python
          scrot
        ] ++ libraries;

        devEnv = pkgs.mkShell {
          buildInputs = packages; # Include the packages directly

          shellHook =
            ''
              # Customize the shell prompt with a pretty blue color
              PS1="\[\033[1;34m\](nix-flake: automation) \[\033[0m\]$PS1"

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
