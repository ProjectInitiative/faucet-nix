{
  description = "Faucet SDN — Nix wrapper around upstream source (no code in repo)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    upstream-src = {
      url = "github:faucetsdn/faucet/1.10.12";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      upstream-src,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          py = pkgs.python3;

          overrides = fetchurl: self: super: {
            os-ken = super.buildPythonPackage rec {
              pname = "os-ken";
              version = "3.1.0";
              format = "setuptools";
              src = fetchurl {
                url = "mirror://pypi/o/os-ken/os_ken-${version}.tar.gz";
                sha256 = "1wqhrsxbjxn7jbz50v9hkac0flj5dvg20nrgnyd4sa8nr2m125ls";
              };
              nativeBuildInputs = with super; [ pbr ];
              propagatedBuildInputs = with super; [
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
              PBR_VERSION = version;
            };

            beka = super.buildPythonPackage rec {
              pname = "beka";
              version = "0.4.2";
              format = "setuptools";
              src = super.fetchPypi {
                inherit pname version;
                sha256 = "11p8ylr32j0jr5i7xj5kha6gd2d5qa10c3zsdh63nl6ldn937vsb";
              };
              nativeBuildInputs = with super; [ pbr ];
              propagatedBuildInputs = with super; [ ];
              PBR_VERSION = version;
            };

            chewie = super.buildPythonPackage rec {
              pname = "chewie";
              version = "0.0.25";
              format = "setuptools";
              src = super.fetchPypi {
                inherit pname version;
                sha256 = "0bbdcwkqbl99g3gpbhic6fhb70192jvv5hgzs7zjr70ssfd0jz6s";
              };
              nativeBuildInputs = with super; [ pbr ];
              propagatedBuildInputs = with super; [ ];
              PBR_VERSION = version;
            };
          };

          pythonPackages = py.pkgs.overrideScope (overrides pkgs.fetchurl);

          faucet = pythonPackages.buildPythonPackage rec {
            pname = "faucet";
            version = "1.10.12";
            src = upstream-src;
            format = "setuptools";

            nativeBuildInputs = with pythonPackages; [
              pbr
              setuptools
            ];

            propagatedBuildInputs = with pythonPackages; [
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
              # Prevent setup.py from trying to write to /etc during install
              substituteInPlace setup.py --replace-fail \
                '"install" in sys.argv or "bdist_wheel" in sys.argv' \
                'False'
            '';

            meta = with nixpkgs.lib; {
              description = "Faucet is an OpenFlow controller that implements a layer 2 and layer 3 switch";
              homepage = "https://faucet.nz";
              license = licenses.asl20;
              maintainers = [ ];
              platforms = platforms.linux;
            };
          };
        in
        {
          default = faucet;
          faucet = faucet;
        }
      );

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.faucet;
          gaugeCfg = config.services.gauge;
          inherit (lib)
            mkIf
            mkEnableOption
            mkOption
            types
            ;
        in
        {
          options = {
            services.faucet = {
              enable = mkEnableOption "Faucet OpenFlow controller";

              package = mkOption {
                type = types.package;
                default = self.packages.${pkgs.system}.default;
                description = "Faucet package to use";
              };

              configFile = mkOption {
                type = types.path;
                default = "${
                  self.packages.${pkgs.system}.default
                }/${pkgs.python3.sitePackages}/faucet/../etc/faucet/faucet.yaml";
                description = "Path to faucet.yaml configuration";
              };

              ryuConfig = mkOption {
                type = types.path;
                default = "${
                  self.packages.${pkgs.system}.default
                }/${pkgs.python3.sitePackages}/faucet/../etc/faucet/ryu.conf";
                description = "Path to Ryu/os-ken framework config";
              };

              listenPort = mkOption {
                type = types.port;
                default = 6653;
                description = "OpenFlow TCP listen port";
              };

              prometheusPort = mkOption {
                type = types.port;
                default = 9302;
                description = "Prometheus metrics port";
              };

              logDir = mkOption {
                type = types.path;
                default = "/var/log/faucet";
                description = "Log directory";
              };

              extraArgs = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra arguments passed to faucet";
              };
            };

            services.gauge = {
              enable = mkEnableOption "Gauge OpenFlow statistics controller";

              package = mkOption {
                type = types.package;
                default = self.packages.${pkgs.system}.default;
                description = "Faucet package to use (same package, gauge entry point)";
              };

              configFile = mkOption {
                type = types.path;
                default = "${
                  self.packages.${pkgs.system}.default
                }/${pkgs.python3.sitePackages}/faucet/../etc/faucet/gauge.yaml";
                description = "Path to gauge.yaml configuration";
              };

              ryuConfig = mkOption {
                type = types.path;
                default = "${
                  self.packages.${pkgs.system}.default
                }/${pkgs.python3.sitePackages}/faucet/../etc/faucet/ryu.conf";
                description = "Path to Ryu/os-ken framework config";
              };

              listenPort = mkOption {
                type = types.port;
                default = 6654;
                description = "OpenFlow TCP listen port";
              };

              logDir = mkOption {
                type = types.path;
                default = "/var/log/faucet";
                description = "Log directory";
              };

              extraArgs = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra arguments passed to gauge";
              };
            };
          };

          config = mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];

            users.users.faucet = {
              description = "Faucet SDN daemon user";
              group = "faucet";
              isSystemUser = true;
            };
            users.groups.faucet = { };

            systemd.services.faucet = {
              description = "Faucet OpenFlow switch controller";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              wantedBy = [ "multi-user.target" ];

              environment = {
                FAUCET_CONFIG = cfg.configFile;
                FAUCET_RYU_CONF = cfg.ryuConfig;
                FAUCET_LISTEN_PORT = toString cfg.listenPort;
                FAUCET_PROMETHEUS_PORT = toString cfg.prometheusPort;
                FAUCET_LOG = "${cfg.logDir}/faucet.log";
                FAUCET_EXCEPTION_LOG = "${cfg.logDir}/faucet_exception.log";
              };

              serviceConfig = {
                User = "faucet";
                Group = "faucet";
                ExecStart = "${cfg.package}/bin/faucet --ryu-config-file=${cfg.ryuConfig} --ryu-ofp-tcp-listen-port=${toString cfg.listenPort}";
                ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
                Restart = "always";
                StateDirectory = "faucet";
                LogsDirectory = "faucet";
              };
            };

            systemd.services.gauge = mkIf gaugeCfg.enable {
              description = "Gauge OpenFlow statistics controller";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              wantedBy = [ "multi-user.target" ];

              environment = {
                GAUGE_CONFIG = gaugeCfg.configFile;
                GAUGE_RYU_CONF = gaugeCfg.ryuConfig;
                GAUGE_LISTEN_PORT = toString gaugeCfg.listenPort;
                GAUGE_LOG = "${gaugeCfg.logDir}/gauge.log";
                GAUGE_EXCEPTION_LOG = "${gaugeCfg.logDir}/gauge_exception.log";
              };

              serviceConfig = {
                User = "faucet";
                Group = "faucet";
                ExecStart = "${gaugeCfg.package}/bin/gauge --ryu-config-file=${gaugeCfg.ryuConfig} --ryu-ofp-tcp-listen-port=${toString gaugeCfg.listenPort}";
                Restart = "always";
                StateDirectory = "faucet";
                LogsDirectory = "faucet";
              };
            };
          };
        };

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          setupLocalSource = pkgs.writeShellScriptBin "setup-local-source" ''
            echo "Setting up local source in .direnv/vendor..."
            mkdir -p .direnv/vendor
            if [ -d ".direnv/vendor/upstream" ]; then
              echo "Removing existing source..."
              rm -rf .direnv/vendor/upstream
            fi
            echo "Copying from Nix store..."
            cp -r ${upstream-src} .direnv/vendor/upstream
            chmod -R +w .direnv/vendor/upstream
            echo "Done. Source is in .direnv/vendor/upstream"
            echo "You can now edit and rebuild with: nix build"
          '';

          buildLocal = pkgs.writeShellScriptBin "build-local" ''
            if [ ! -d ".direnv/vendor/upstream" ]; then
              echo "Error: Local source not found. Run 'setup-local-source' first."
              exit 1
            fi
            cd .direnv/vendor/upstream
            echo "Building from local source via pip..."
            pip install -e .
          '';

          agentCheck = pkgs.writeShellScriptBin "agent-check" ''
            set -euo pipefail
            echo "=== Agent Pre-Submission Check ==="
            echo "1. Checking working tree..."
            if [ -n "$(git status --porcelain)" ]; then
              echo "ERROR: Working tree is dirty. Commit all changes first."
              exit 1
            fi
            echo "2. Checking formatting..."
            treefmt --fail-on-change
            echo "3. Building..."
            nix build
            echo "=== All checks passed ==="
          '';

        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              setupLocalSource
              buildLocal
              agentCheck
              git
              nixfmt
              prettier
              treefmt
              python3
            ];
            shellHook = ''
              echo "Faucet SDN wrapper dev shell"
              echo "Commands:"
              echo "  setup-local-source  : Copy source to .direnv/vendor/ for editing"
              echo "  build-local         : Build from local source copy (pip install -e .)"
              echo "  nix build           : Build from pinned flake input"
              echo "  agent-check         : Run pre-submission checks"
            '';
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          formatting =
            pkgs.runCommand "check-formatting"
              {
                nativeBuildInputs = with pkgs; [ nixfmt ];
                src = ./.;
              }
              ''
                cd $src
                nixfmt --check *.nix
                touch $out
              '';
          build = self.packages.${system}.default;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
