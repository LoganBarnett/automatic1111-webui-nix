{
  description = "AUTOMATIC1111/stable-diffusion-webui flake";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
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
        overlays = [
        ];
      };

    in pkgs.mkShell {
      packages = [];
    };

    packages.aarch64-darwin.default = let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
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
      inherit
        (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
        mkPoetryApplication
      ;
    in
      mkPoetryApplication {
        projectDir = patched-src;
        overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {
          # …
          # workaround https://github.com/nix-community/poetry2nix/issues/568
          structlog = super.structlog.overridePythonAttrs (old: {
            buildInputs = old.buildInputs or [ ] ++ [ pkgs.python310.pkgs.flit-core ];
          });
        });
      };
    darwinModules.aarch64-darwin.default = let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
      };
    in pkgs.callPackage ./launchd-service.nix {};
  };
}
