# Nix Config

A set of configs for my machines:

- powerhouse (desktop) - NixOS
- turbine (laptop) - macOS with nix-darwin (Intel)

## Features

- **Modular Architecture**: 20+ organized modules across 10 categories for maximum reusability
- **Cross-platform**: Supports both NixOS and macOS with shared configurations
- **Home Manager integration**: User-specific configs with modular component imports
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
│   └── turbine/        # macOS laptop
├── modules/            # Modular components (20+ modules)
│   ├── desktop/        # Desktop environments (plasma, hyprland)
│   ├── fonts/          # Font configurations
│   ├── hardware/       # Hardware-specific modules (nvidia, bluetooth)
│   ├── media/          # Media modules (audio)
│   ├── network/        # Network configurations (wireguard)
│   ├── os/             # Operating system modules (common, darwin, nixos)
│   ├── programs/       # Application configurations (git)
│   ├── security/       # Security modules (gpg, ssh, gpg-agent)
│   ├── services/       # Service modules (backup/restic)
│   ├── terminal/       # Terminal tools (nvim, starship, tmux, zsh)
│   └── virtualization/ # Virtualization tools (podman, qemu)
├── users/              # User-specific configurations
├── flake.nix           # Main flake configuration
└── justfile            # Development commands
```

### Module Architecture

The configuration is built using a modular approach where each component serves a specific purpose:

#### OS Modules (`modules/os/`)
- `common.nix` - Universal settings for all systems
- `nixos.nix` - NixOS-specific configurations
- `darwin.nix` - macOS-specific configurations

#### User-specific Modules
- `modules/terminal/` - Shell, terminal emulators, and CLI tools
- `modules/security/` - GPG, SSH, and authentication
- `modules/programs/` - Application-specific configurations

#### System Modules
- `modules/hardware/` - Hardware-specific configurations
- `modules/network/` - Network and VPN configurations
- `modules/desktop/` - Desktop environment configurations
- `modules/virtualization/` - Container and VM configurations
- `modules/services/` - Background services and backups

### Configuration Import Strategy

**Host Configurations** (`hosts/*/config.nix`):
```nix
imports = [
  ../../modules/os/common.nix    # Universal settings
  ../../modules/os/nixos.nix     # or darwin.nix for macOS
  ./hardware.nix                 # Host-specific hardware
];
```

**User Configurations** (`users/*/home.nix`):
```nix
imports = [
  ../../modules/terminal/zsh.nix
  ../../modules/security/default.nix
  ../../modules/programs/git.nix
  # Add modules as needed
];
```

## Getting Help

- Check the documentation in the navigation menu
- Run `just help` for available commands
- Review existing configurations in the hosts/ directory
- Explore modules in the modules/ directory for reusable components
- See module import examples in users/brancengregory/home.nix
- See [GitHub Copilot Agent](./COPILOT_AGENT.md) for development environment details

## Adding New Modules

To add a new module:

1. Create the module file in the appropriate `modules/` subdirectory
2. Follow the existing module structure and naming conventions
3. Import the module in the relevant host or user configuration
4. Test the configuration with `just check-darwin` or `just build-linux`