{
  description = "AUTOMATIC1111/stable-diffusion-webui flake";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix }: (
let
  default-attr = { attr, default, attrset }:
    if builtins.hasAttr attr attrset then
      builtins.trace attrset.${attr}
    else
      builtins.trace default
  ;
in
{
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
            # "composite" and "tolerance" tests fail with:
            # tolerance-test                TIMEOUT        120.01s   killed by signal 15 SIGTERM
            # Probably due to large concurrency of builds.  Just disable the
            # tests.
            pixman = prev.pixman.overrideAttrs (prev-pixman: {
              doCheck = false;
            });

            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (pyfinal: pyprev: {
                astropy = pyprev.astropy.overridePythonAttrs (prev-pkg: {
                    doCheck = false;
                    disabledTests =
# (default-attr "disabledTests" [] prev-pkg) ++
                      [
                        "test_sidereal_lat_independent"
                      ];
                  });
                debugpy = pyprev.debugpy.overridePythonAttrs (prev-pkg: {
                  disabledTests = [
# (default-attr "disabledTests" [] prev-pkg) ++

# This test tries to fire up Flask and can't find an open port potentially, so
# it dies.  No automatic port allocation?
# I+00000.541: Running module 'flask'
# 
# D+00001.353: Debuggee exited via SystemExit: 1
#              
#              Traceback (most recent call last):
#                File "/nix/store/088kl5yyz3d4439ghn75pxclqh4bwsvb-python3.11-werkzeug-3.0.1/lib/python3.11/site-packages/werkzeug/serving.py", line 746, in __init__
#                  self.server_bind()
#                File "/nix/store/vaq6dyx5g8byyz4zgi4jdg3g7346dnzz-python3-3.11.8/lib/python3.11/http/server.py", line 136, in server_bind
#                  socketserver.TCPServer.server_bind(self)
#                File "/nix/store/vaq6dyx5g8byyz4zgi4jdg3g7346dnzz-python3-3.11.8/lib/python3.11/socketserver.py", line 472, in server_bind
#                  self.socket.bind(self.server_address)
#              OSError: [Errno 48] Address already in use
                    "test_flask_breakpoint_no_multiproc"
                    "test_flask_template_exception_no_multiproc"
                  ];
                });
                dnspython = pyprev.dnspython.overridePythonAttrs (prev-pkg: {
                    disabledTests =
# (default-attr "disabledTests" [] prev-pkg) ++
                      [
                        # External query attempted and failed.  This is actually
                        # 4 different sub-tests under various parent tests.
                        # Message:
                        # dns.resolver.NoNameservers: All nameservers failed to answer the query 8.8....
                        "testResolveName"
                        # Unsure why this fails.  Message is:
                        # AssertionError: False is not true
                        "test_basic_getaddrinfo"
                      ];
                  });
                ffmpy = pyprev.ffmpy.overridePythonAttrs (prev-pkg: {
                    disabledTests =
# (default-attr "disabledTests" [] prev-pkg) ++
                      [
                        # Uses an absolute path to /tmp on its assertion.
                        "test_invalid_executable_path"
                      ];
                  });
                # This test suite is also effected by build speed/load.  It
                # contains these helpful instructions for how to avoid the
                # timeouts seen, but I don't know if that's just increasing the
                # timeout such that a machine with more load will still timeout,
                # or if it actually makes the tests resilient to timeouts.  If
                # it's the latter, why not always have it on?  For now, just
                # disable the tests.  I also don't know how to configure it
                # because setting something doesn't really have any meaning to
                # me as a non-Pythonista.
                # The message:
                # Unreliable test timings! On an initial run, this test took
                # 283.12ms, which exceeded the deadline of 200.00ms, but on a
                # subsequent run it took 0.04 ms, which did not. If you expect
                # this sort of variability in your test timings, consider
                # turning deadlines off for this test by setting deadline=None.
                # And:
                # hypothesis.errors.FailedHealthCheck: Data generation is
                # extremely slow: Only produced 9 valid examples in 1.02 seconds
                # (26 invalid ones and 2 exceeded maximum size). Try decreasing
                # size of the data you're generating (with e.g. max_size or
                # max_leaves parameters).
                #   See
                #   https://hypothesis.readthedocs.io/en/latest/healthchecks.html
                #   for more information about this. If you want to disable just
                #   this health check, add HealthCheck.too_slow to the
                #   suppress_health_check settings for this test.
                hypothesis = pyprev.hypothesis.overridePythonAttrs (prev-pkg: {
                    doCheck = false;
                    disabledTests =
                      # builtins.trace (default-attr "disabledTests" [] prev-pkg) ++
                      [
                        "test_range_of_acceptable_outputs"
                      ];
                  });
                omegaconf = pyprev.omegaconf.overridePythonAttrs (prev-pkg: {
                  disabledTests =
                    # (default-attr "disabledTests" [] prev-pkg) ++
                    [
                      "test_case_json_hit_condition_error"
                      "test_case_skipping_filters"
                      "test_variable_presentation"
                    ];
                });
              })
            ];
            python311 = prev.python311.override {
              # packageOverrides = prev.lib.composeManyExtensions (defaultOverrides);
              packageOverrides =
                (pyfinal: pyprev: rec {
                  # I don't know how to just bump the version, so we just pull
                  # an entire copy of the package into the repo.
                  gradio = pyfinal.callPackage ./gradio/default.nix {};
                  gradio-client-why = pyfinal.callPackage ./gradio/client.nix { };
                  huggingface-hub_0_17_3 = pyfinal.callPackage ./huggingface-hub/default.nix { };
                  transformers_4_30 = pyfinal.callPackage ./transformers/default.nix { };
                  tokenizers_0_14 = pyfinal.callPackage ./tokenizers/default.nix { };
                  websockets_10 = pyfinal.callPackage ./websockets/default.nix { };
                })
              ;
            };
            python311Packages = final.python311.pkgs;
            python3 = final.python311;
            python3Packages = final.python3.pkgs;
            # Work around the build issue here until it moves to unstable:
            # https://github.com/NixOS/nixpkgs/pull/292480
            tzdata = prev.tzdata.overrideAttrs (_: {
              checkTarget = "check_back check_character_set check_white_space check_links check_name_lengths check_slashed_abbrs check_sorted check_tables check_ziguard check_zishrink check_tzs";
            });
            # Fails with:
            # RuntimeError: There is no current event loop in thread 'Dummy-1'.
            # Probably due to large concurrency of builds.  Just disable the
            # tests.
            xdist = prev.xdist.overrideAttrs (prev-xdist: {
              doCheck = false;
            });
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
transformers_4_30
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
});
}
