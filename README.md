# Nix Config

A set of configs for my machines:

- powerhouse (desktop) - NixOS
- capacitor (server) - NixOS
- turbine (laptop) - macOS with nix-darwin

## Features

- **Modular Architecture**: 17+ organized modules across 9 categories for maximum reusability
- **Cross-platform**: Supports both NixOS and macOS with shared configurations
- **Home Manager integration**: User-specific configs with modular component imports
- **Unified GPG/SSH**: Integrated authentication and encryption strategy
- **Homebrew support** (macOS): GUI applications and Mac-specific software
- **Minimal approach**: Prefer nixpkgs over Homebrew when possible
- **Cross-compilation**: Build and validate nix-darwin configs from Linux

## Documentation

📖 **[View the complete documentation site](https://brancengregory.github.io/nix-config/)**

- [GPG/SSH Strategy](docs/GPG-SSH-STRATEGY.md) - Unified authentication and encryption across all systems
- [Security Guidelines](docs/SECURITY.md) - Security best practices and audit results
- [Homebrew Integration](docs/HOMEBREW.md) - Managing GUI apps and Mac-specific software
- [Cross-Platform Development](docs/CROSS_COMPILATION.md) - Building nix-darwin configs from Linux
- [GitHub Copilot Agent](docs/COPILOT_AGENT.md) - Development environment for Copilot coding agent

## Repository Structure

```
├── docs/               # Documentation
├── hosts/              # Host-specific configurations
│   ├── powerhouse/     # NixOS desktop
│   └── turbine/        # macOS laptop
├── modules/            # Modular components (17+ modules)
│   ├── desktop/        # Desktop environments (hyprland)
│   ├── fonts/          # Font configurations
│   ├── hardware/       # Hardware-specific modules (nvidia)
│   ├── network/        # Network configurations (wireguard)
│   ├── os/             # Operating system modules (common, darwin, nixos)
│   ├── programs/       # Application configurations (git)
│   ├── security/       # Security modules (gpg, ssh, gpg-agent)
│   ├── terminal/       # Terminal tools (nvim, starship, tmux, zsh)
│   └── virtualization/ # Virtualization tools (podman, qemu)
├── users/              # User-specific configurations
├── flake.nix           # Main flake configuration
└── justfile            # Development commands
```

### Working with Modules

The modular architecture allows for flexible configuration:

- **Host configurations** (`hosts/*/config.nix`) import OS-specific modules
- **User configurations** (`users/*/home.nix`) import user-specific modules  
- **Shared modules** provide consistent configurations across all systems
- **Cross-platform compatibility** through OS-specific module imports

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

