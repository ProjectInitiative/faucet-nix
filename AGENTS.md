# Agent Working Guide — Faucet SDN Wrapper

## What Is This?

This repo wraps the **Faucet SDN** controller with a Nix flake. It does **not** contain the source — upstream is fetched via flake input.

Provides:

- Reproducible build derivation (`nix build`)
- NixOS module with `services.faucet` and `services.gauge`
- Local iteration workflow (copy source to `.direnv/vendor/`)

## Environment

Loaded via `direnv`. Source code is fetched by Nix, not committed here.

## Workflow

### Sandboxed Build (CI-ready)

```bash
nix build          # Builds from pinned flake input
```

### Local Iteration (for development)

```bash
setup-local-source  # Copy source to .direnv/vendor/upstream for editing
# Edit files in .direnv/vendor/upstream/
build-local         # Build from local copy (pip install -e .)
```

## Available Commands

| Command              | Description                                  |
| -------------------- | -------------------------------------------- |
| `setup-local-source` | Copy upstream source into `.direnv/vendor/`  |
| `build-local`        | Build from the local editable copy           |
| `nix build`          | Build from pinned flake input (reproducible) |

## NixOS Module

The flake exposes `nixosModules.default` with:

- `services.faucet` — Faucet OpenFlow controller
  - `enable`, `package`, `configFile`, `ryuConfig`, `listenPort`, `prometheusPort`, `logDir`, `extraArgs`
- `services.gauge` — Gauge OpenFlow statistics controller
  - `enable`, `package`, `configFile`, `ryuConfig`, `listenPort`, `logDir`, `extraArgs`

Example:

```nix
{
  imports = [ inputs.faucet-nix.nixosModules.default ];
  services.faucet = {
    enable = true;
    configFile = ./my-faucet.yaml;
  };
}
```

## Mandatory Pre-Submission

```bash
nix develop --command agent-check
```

## Why This Pattern?

- Upstream is a Python project that may never ship Nix packaging
- Keeps the repo small (only Nix logic, not the full 100MB+ source)
- Pins exact upstream version via flake lock
- Provides both hermetic builds and fast local iteration
