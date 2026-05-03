{ lib
, buildPythonPackage
, fetchFromGitHub
, pbr
}:

buildPythonPackage rec {
  pname = "beka";
  version = "0.4.2";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "faucetsdn";
    repo = "beka";
    rev = version;
    hash = "sha256-cwavpuOyOvjQbBDYgdGmbJrTaNZ/nKP6jnNJrp+SfZo=";
  };

  nativeBuildInputs = [ pbr ];

  propagatedBuildInputs = [ ];

  PBR_VERSION = version;

  pythonImportsCheck = [ "beka" ];

  meta = with lib; {
    description = "A bare-bones BGP speaker";
    homepage = "https://github.com/faucetsdn/beka";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
