{ lib
, buildPythonPackage
, fetchurl
, pbr
, eventlet
, msgpack
, ncclient
, netaddr
, oslo-config
, packaging
, routes
, webob
}:

buildPythonPackage rec {
  pname = "os-ken";
  version = "3.1.0";
  format = "setuptools";

  src = fetchurl {
    url = "mirror://pypi/o/os-ken/os_ken-${version}.tar.gz";
    sha256 = "1wqhrsxbjxn7jbz50v9hkac0flj5dvg20nrgnyd4sa8nr2m125ls";
  };

  nativeBuildInputs = [ pbr ];

  propagatedBuildInputs = [
    eventlet
    msgpack
    ncclient
    netaddr
    oslo-config
    packaging
    pbr
    routes
    webob
  ];

  # ovs (python-openvswitch) is an optional dependency for OVSDB;
  # not packaged in nixpkgs, so currently omitted.
  # See: https://github.com/os-ken/os-ken/issues

  PBR_VERSION = version;

  pythonImportsCheck = [ "os_ken" ];

  meta = with lib; {
    description = "Component-based software defined networking framework for OpenStack";
    homepage = "https://github.com/os-ken/os-ken";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
