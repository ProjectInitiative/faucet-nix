{ lib
, buildPythonPackage
, fetchFromGitHub
, pbr
, setuptools
, beka
, chewie
, eventlet
, ncclient
, networkx
, os-ken
, prometheus-client
, pytricia
, requests
, ruamel-yaml
}:

buildPythonPackage rec {
  pname = "faucet";
  version = "1.10.12";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "faucetsdn";
    repo = "faucet";
    rev = version;
    hash = "sha256-HJIxQi96KiExNr8wqiOPKoYlnB1SDS8jFFG40qlv378=";
  };

  nativeBuildInputs = [
    pbr
    setuptools
  ];

  propagatedBuildInputs = [
    beka
    chewie
    eventlet
    ncclient
    networkx
    os-ken
    pbr
    prometheus-client
    pytricia
    requests
    ruamel-yaml
  ];

  PBR_VERSION = version;

  postPatch = ''
    substituteInPlace setup.py --replace-fail \
      '"install" in sys.argv or "bdist_wheel" in sys.argv' \
      'False'
  '';

  pythonImportsCheck = [ "faucet" ];

  meta = with lib; {
    description = "OpenFlow controller that implements a layer 2 and layer 3 switch";
    homepage = "https://faucet.nz";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "faucet";
  };
}
