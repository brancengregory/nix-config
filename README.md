# Nix Config

A set of configs for my machines:

- **powerhouse** (desktop) - NixOS
- **capacitor** (server) - NixOS  
- **turbine** (laptop) - macOS with nix-darwin (Intel)
- **battery** (future) - NixOS

## Features

- **Modular Architecture**: 20+ organized modules across 10 categories for maximum reusability
- **Cross-platform**: Supports both NixOS and macOS with shared configurations
- **Home Manager integration**: User-specific configs with modular component imports
- **Unified GPG/SSH**: Integrated authentication and encryption strategy
- **Homebrew support** (macOS): GUI applications and Mac-specific software
- **Minimal approach**: Prefer nixpkgs over Homebrew when possible
- **Cross-compilation**: Build and validate nix-darwin configs from Linux
- **ISO Installers**: Custom NixOS installer ISOs with pre-configured flakes

## Documentation

- **[Complete Documentation](docs/)** - Full documentation site with detailed guides
- **[Migration Guide](docs/MIGRATION.md)** - Complete Arch Linux to NixOS migration guide with Windows dual-boot
- **[Secret Management](docs/SECRET_MANAGEMENT.md)** - Ultra-secure, declarative secret management with sops and age
- **[GPG/SSH Strategy](docs/GPG-SSH-STRATEGY.md)** - Unified authentication and encryption across all systems
- **[Homebrew Integration](docs/HOMEBREW.md)** - Managing GUI apps and Mac-specific software
- **[Cross-Platform Development](docs/CROSS_COMPILATION.md)** - Building nix-darwin configs from Linux
- **[GitHub Copilot Agent](docs/COPILOT_AGENT.md)** - Development environment for Copilot coding agent
- **[Restic Backup Configuration](docs/RESTIC.md)** - Secure, declarative backups with Restic
- **[Module Architecture](docs/MODULES.md)** - Understanding the modular system
- **[Current Setup Status](SETUP_STATUS.md)** - Current configuration status and checklist

## Repository Structure

```
├── docs/               # Documentation
├── hosts/              # Host-specific configurations
│   ├── capacitor/      # NixOS homelab server
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
├── mise.toml           # Development commands and tasks
└── SETUP_STATUS.md     # Current configuration status
```

### Module Architecture

The configuration is built using a modular approach where each component serves a specific purpose:

#### OS Modules (`modules/os/`)
- `common.nix` - Universal settings for all systems
- `nixos.nix` - NixOS-specific system configurations
- `darwin.nix` - macOS-specific system configurations

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

## Quick Start

### Prerequisites

1. Install Nix with flakes enabled
2. Clone this repository
3. Enter the development environment

### Development Environment

```bash
# Enter development shell
mise dev
# or: nix develop

# View available commands
mise help
```

### Building Configurations

```bash
# Build NixOS configurations
mise build-powerhouse
mise build-capacitor

# Cross-compile nix-darwin config from Linux
mise build-turbine

# Validate nix-darwin config (faster)
mise check-darwin

# Build all configurations
mise build-all

# Build ISO installers
mise build-powerhouse-iso
mise build-capacitor-iso
```

