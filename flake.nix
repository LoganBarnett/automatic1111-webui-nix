{
  description = "AUTOMATIC1111/stable-diffusion-webui flake";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/master;
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix }: {
    devShells.aarch64-darwin.default =  let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
      };

    in pkgs.mkShell {
      packages = [];
    };

    packages.aarch64-darwin.default = let
      system = "aarch64-darwin";

      defaultOverrides = [
        (final: prev: {
          gradio = prev.gradio.overridePythonAttrs (oldAttrs: rec {
            version = "3.19.2";
            src = prev.fetchPypi {
              pname = "gradio";
              inherit version;
              hash = "sha256-JQn+rtpy/OA2deLszSKEuxyttqBzcAil50H+JDHUdCE=";
            };
          });
        })
      ];

      pkgs = import nixpkgs {
        inherit system;
        overlays = [

          (final: prev: {
            python311 = prev.python311.override {
              # packageOverrides = prev.lib.composeManyExtensions (defaultOverrides);
              packageOverrides =
                (pyfinal: pyprev: {
                  # I don't know how to just bump the version, so we just pull
                  # an entire copy of the package into the repo.
                  gradio = pyfinal.callPackage ./gradio/default.nix {};
                  gradio-client = pyfinal.callPackage ./gradio/client.nix { };
                })
              ;
            };
            python311Packages = final.python311.pkgs;
          })

        ];
      };
      src = (pkgs.fetchFromGitHub {
        owner = "AUTOMATIC1111";
        repo = "stable-diffusion-webui";
        rev = "v1.8.0";
        hash = "sha256-HsHFY2OHgGC/WtZH8Is+xGbQUkcM1mhOSVZkJEz/t0k=";
      });
      patches = [
        # There's no poetry.lock in stable-diffusion-webui, and the project is
        # not structured such that it would be a "working" Poetry package.  We
        # must patch that.  At some point we should make the creation of the
        # poetry.lock something done by nix instead of by hand.
        ./poetry-lock.patch
      ];
      patched-src = pkgs.applyPatches {
        name = "stable-diffusion-webui-source-patched";
        inherit src;
        inherit patches;
      };
      # inherit
      #   (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
      #   mkPoetryApplication
      # ;
    in
      # pkgs.python311Packages.toPythonModule (pkgs.stdenv.mkDerivation {
      pkgs.python311Packages.buildPythonPackage {
        pname = "stable-diffusion-webui";
        version = "v1.8.0";
        pyproject = true;
        nativeBuildInputs = [
          pkgs.python311Packages.setuptools
          pkgs.python311Packages.setuptools-scm
        ];
        buildInputs = with pkgs.python311Packages; [
gitpython
pillow
accelerate

# basicsr
# blendmodes
clean-fid
einops
fastapi
# gfpgan
gradio
inflection
jsonmerge
kornia
lark
numpy
omegaconf
open-clip-torch

piexif
psutil
pytorch-lightning
#realesrgan
requests
resize-right

safetensors
scikit-image
timm
# tomesd
torch
torchdiffeq
torchsde
transformers
          # pkgs.python311Packages.clean-fid
          # pkgs.python311Packages.clean-fid
        ];
        # Without this, we'll get the "No such file or directory: 'setup.py'"
        # error.
        # format = "pyproject";
        src = patched-src;
      };
      # mkPoetryApplication {
      #   projectDir = patched-src;
      #   overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {
      #     # …
      #     # workaround https://github.com/nix-community/poetry2nix/issues/568
      #     structlog = super.structlog.overridePythonAttrs (old: {
      #       buildInputs = old.buildInputs or [ ] ++ [ pkgs.python310.pkgs.flit-core ];
      #     });
      #   });
      # };
    darwinModules.aarch64-darwin.default = let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
      };
    in pkgs.callPackage ./launchd-service.nix {};
  };
}
