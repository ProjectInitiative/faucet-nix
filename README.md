# faucet-nix

Nix wrapper for [Faucet SDN](https://github.com/faucetsdn/faucet) — the production OpenFlow controller.

## Usage

Add to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    faucet-nix = {
      url = "github:your-org/faucet-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### NixOS Module

```nix
{
  imports = [ inputs.faucet-nix.nixosModules.default ];

  services.faucet = {
    enable = true;
    configFile = ./faucet.yaml;
  };
}
```

### Options

#### `services.faucet`

| Option           | Type           | Default           | Description                         |
| ---------------- | -------------- | ----------------- | ----------------------------------- |
| `enable`         | bool           | `false`           | Enable Faucet OpenFlow controller   |
| `package`        | package        | `faucet`          | Faucet package to use               |
| `configFile`     | path           | _bundled example_ | Path to `faucet.yaml`               |
| `ryuConfig`      | path           | _bundled example_ | Path to Ryu/os-ken framework config |
| `listenPort`     | port           | `6653`            | OpenFlow TCP listen port            |
| `prometheusPort` | port           | `9302`            | Prometheus metrics port             |
| `logDir`         | path           | `/var/log/faucet` | Log directory                       |
| `extraArgs`      | list of string | `[]`              | Extra arguments                     |

#### `services.gauge`

| Option       | Type           | Default           | Description                              |
| ------------ | -------------- | ----------------- | ---------------------------------------- |
| `enable`     | bool           | `false`           | Enable Gauge statistics controller       |
| `package`    | package        | `faucet`          | Faucet package (same, gauge entry point) |
| `configFile` | path           | _bundled example_ | Path to `gauge.yaml`                     |
| `ryuConfig`  | path           | _bundled example_ | Path to Ryu/os-ken framework config      |
| `listenPort` | port           | `6654`            | OpenFlow TCP listen port                 |
| `logDir`     | path           | `/var/log/faucet` | Log directory                            |
| `extraArgs`  | list of string | `[]`              | Extra arguments                          |

### Custom Configuration

The bundled defaults include example configs. For production, point to your own:

```nix
{
  services.faucet = {
    enable = true;
    configFile = ./config/faucet.yaml;
    ryuConfig = ./config/ryu.conf;
  };
  services.gauge = {
    enable = true;
    configFile = ./config/gauge.yaml;
  };
}
```

### Development

```bash
nix develop           # enter dev shell
setup-local-source    # copy upstream source for editing
build-local           # build from local copy
nix build             # build from pinned flake input
```

## License

Apache 2.0 — matches upstream Faucet SDN.
