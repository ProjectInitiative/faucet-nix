{ lib
, buildPythonPackage
, fetchFromGitHub
, pbr
}:

buildPythonPackage rec {
  pname = "chewie";
  version = "0.0.25";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "faucetsdn";
    repo = "chewie";
    rev = version;
    hash = "sha256-mMaGvA+IwA7l69aAWLGjPDOn1UEH2912cGystqdxeX0=";
  };

  nativeBuildInputs = [ pbr ];

  propagatedBuildInputs = [ ];

  PBR_VERSION = version;

  pythonImportsCheck = [ "chewie" ];

  meta = with lib; {
    description = "A bare-bones EAPOL/802.1x implementation";
    homepage = "https://github.com/faucetsdn/chewie";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
