{ lib
, buildPythonPackage
, fetchFromGitHub
, pythonOlder
, pythonRelaxDepsHook
# pyproject
, hatchling
, hatch-requirements-txt
, hatch-fancy-pypi-readme
# runtime
, setuptools
, fsspec
, httpx
, huggingface-hub
, packaging
, requests
, typing-extensions
, websockets10
# checkInputs
, pytestCheckHook
, pytest-asyncio
, pydub
, rich
, tomlkit
, gradio
}:

buildPythonPackage rec {
  pname = "gradio-client";
  version = "0.4.0";
  format = "pyproject";

  disabled = pythonOlder "3.8";

  # no tests on pypi
  src = fetchFromGitHub {
    owner = "gradio-app";
    repo = "gradio";
    #rev = "refs/tags/v${gradio.version}";
    rev = "a22f3e062d8d30f630e0cf8e373ad7cb0f99330f"; # v4.9.1 is not tagged...
    sparseCheckout = [ "client/python" ];
    hash = "sha256-kBjUQ9j5+4kOBOd8ltHVhJvErtEG2xqNeupndhWR1wc=";
  };
  prePatch = ''
    cd client/python
  '';

  disabledTests = [
    # Requires a queue running somewhere.
    "test_cancel_subsequent_jobs_state_reset"
    "test_progress_updates"
    "TestClientPredictions::test_progress_updates"
    "TestClientPredictions::test_cancel_subsequent_jobs_state_reset"
  ];

  # upstream adds upper constraints because they can, not because the need to
  # https://github.com/gradio-app/gradio/pull/4885
  pythonRelaxDeps = [
    # only backward incompat is dropping py3.7 support
    "websockets"
  ];

  nativeBuildInputs = [
    hatchling
    hatch-requirements-txt
    hatch-fancy-pypi-readme
    pythonRelaxDepsHook
  ];

  propagatedBuildInputs = [
    setuptools # needed for 'pkg_resources'
    fsspec
    httpx
    huggingface-hub
    packaging
    typing-extensions
    websockets10
  ];

  nativeCheckInputs = [
    pytestCheckHook
    pytest-asyncio
    pydub
    rich
    tomlkit
    gradio.sans-reverse-dependencies
  ];
  # ensuring we don't propagate this intermediate build
  disallowedReferences = [ gradio.sans-reverse-dependencies ];

  # Add a pytest hook skipping tests that access network, marking them as "Expected fail" (xfail).
  preCheck = ''
    export HOME=$TMPDIR
    cat ${./conftest-skip-network-errors.py} >> test/conftest.py
  '';

  pytestFlagsArray = [
    "test/"
    "-m 'not flaky'"
    #"-x" "-W" "ignore" # uncomment for debugging help
  ];

  pythonImportsCheck = [ "gradio_client" ];

  __darwinAllowLocalNetworking = true;

  meta = with lib; {
    homepage = "https://www.gradio.app/";
    description = "Lightweight library to use any Gradio app as an API";
    license = licenses.asl20;
    maintainers = with maintainers; [ pbsds ];
  };
}
