# Nix Config

A set of configs for my machines:

- powerhouse (desktop) - NixOS
- capacitor (server) - NixOS
- turbine (laptop) - macOS with nix-darwin

## Features

- **Cross-platform**: Supports both NixOS and macOS
- **Home Manager integration**: User-specific configs
- **Unified GPG/SSH**: Integrated authentication and encryption strategy
- **Homebrew support** (macOS): GUI applications and Mac-specific software
- **Minimal approach**: Prefer nixpkgs over Homebrew when possible
- **Cross-compilation**: Build and validate nix-darwin configs from Linux

## Quick Start

### Prerequisites

1. Install Nix with flakes enabled
2. Clone this repository
3. Enter the development environment

### Development Environment

```bash
# Enter development shell
nix develop

# View available commands
just help
```

### Building Configurations

```bash
# Build NixOS VM
just build-linux

# Cross-compile nix-darwin config from Linux
just build-darwin

# Validate nix-darwin config (faster)
just check-darwin
```

## Repository Structure

```
├── docs/               # Documentation
├── hosts/              # Host-specific configurations
│   ├── powerhouse/     # NixOS desktop
│   ├── capacitor/      # NixOS server
│   └── turbine/        # macOS laptop
├── modules/            # Shared modules
├── users/              # User-specific configurations
├── flake.nix           # Main flake configuration
└── justfile            # Development commands
```

## Getting Help

- Check the documentation in the navigation menu
- Run `just help` for available commands
- Review existing configurations in the hosts/ directory
- See [GitHub Copilot Agent](./COPILOT_AGENT.md) for development environment details