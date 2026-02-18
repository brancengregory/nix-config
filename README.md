# Nix Config

A set of configs for my machines using the **Pure Module Pattern**:

- **powerhouse** (desktop) - NixOS with Plasma, NVIDIA, Pro Audio
- **capacitor** (server) - NixOS headless server with monitoring stack
- **turbine** (laptop) - macOS with nix-darwin (Intel)
- **battery** (future) - NixOS

## Features

- **Pure Module Architecture**: 20+ modules using `mkEnableOption` - import to make available, enable to activate
- **Bundle-Based Organization**: Clean imports via `modules/desktop`, `modules/hardware`, `modules/services`
- **Declarative API**: Hosts declare capabilities via `desktop.plasma.enable = true`, not file imports
- **Cross-platform**: Supports both NixOS and macOS with shared configurations
- **Home Manager integration**: User-specific configs with modular component imports
- **Unified GPG/SSH**: Integrated authentication and encryption strategy
- **Homebrew support** (macOS): GUI applications and Mac-specific software
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
├── lib/                # Shared library functions (mkHost abstraction)
├── modules/            # Modular components (20+ Pure Modules)
│   ├── desktop/        # Desktop environments bundle (plasma, sddm)
│   ├── hardware/       # Hardware bundle (nvidia, bluetooth)
│   ├── media/          # Media bundle (audio)
│   ├── services/       # Services bundle (backup, monitoring, etc.)
│   └── virtualization/ # Virtualization bundle (podman, qemu)
├── users/              # User-specific configurations
├── flake.nix           # Main flake configuration with mkHost
└── mise.toml           # Development commands and tasks
```

### The Pure Module Pattern

This repository uses **Pure Modules** with explicit enable options. Unlike traditional Nix configs where importing = activating, here you:

1. **Import the bundle** to make options available
2. **Explicitly enable** what you want

**Example - Old Pattern (import = activate):**
```nix
# Problem: Just importing activates the feature
imports = [
  ../../modules/desktop/plasma.nix  # Always enables Plasma
];
```

**Example - New Pattern (Pure Module):**
```nix
# Import makes options available
imports = [
  ../../modules/desktop  # Bundle: plasma, sddm available
];

# Explicitly choose what to enable
desktop.plasma.enable = true;
desktop.sddm.enable = true;

# Other options available but inactive:
# desktop.sddm.enable = false;  # Implicit - not enabled
```

### Declarative API Examples

**Desktop/Workstation (powerhouse):**
```nix
# Desktop Environment
desktop.plasma.enable = true;
desktop.sddm.enable = true;
themes.stylix.enable = true;

# Hardware
modules.hardware.nvidia.enable = true;
modules.hardware.bluetooth.enable = true;
media.audio.enable = true;
media.audio.lowLatency = true;

# Services
services.backup.enable = true;
services.monitoring.enable = true;
services.monitoring.exporters.enable = true;

# Virtualization
virtualization.podman.enable = true;
virtualization.hypervisor.enable = true;  # Run VMs
```

**Server (capacitor):**
```nix
# No desktop environment - headless server
# services.backup.enable = true;  # Already enabled via service config
services.monitoring.enable = true;
services.monitoring.server.enable = true;  # Full Prometheus/Grafana

# Virtualization for containers only
virtualization.podman.enable = true;
virtualization.hypervisor.enable = false;  # Don't run VMs on server
```

### Available Module Bundles

**Desktop Bundle** (`modules/desktop/`):
- `desktop.plasma.enable` - KDE Plasma 6 desktop
- `desktop.sddm.enable` - SDDM display manager
- `desktop.sddm.theme` - Optional theme

**Hardware Bundle** (`modules/hardware/`):
- `modules.hardware.nvidia.enable` - NVIDIA GPU drivers
- `modules.hardware.nvidia.open` - Use open-source kernel modules
- `modules.hardware.bluetooth.enable` - Bluetooth subsystem
- `modules.hardware.bluetooth.powerOnBoot` - Auto-power behavior

**Media Bundle** (`modules/media/`):
- `media.audio.enable` - PipeWire audio stack
- `media.audio.lowLatency` - Zen kernel for pro audio (⚠️ changes kernel)
- `media.audio.proAudio` - JACK support, Bitwig Studio

**Services Bundle** (`modules/services/`):
- `services.backup.enable` - Restic backup
- `services.monitoring.enable` - Prometheus/Grafana stack
- `services.monitoring.exporters.enable` - Lightweight node exporters
- `services.monitoring.server.enable` - Heavy monitoring server
- Plus: download, git, media, ollama, opencode, storage

**Virtualization Bundle** (`modules/virtualization/`):
- `virtualization.podman.enable` - Container engine
- `virtualization.podman.dockerCompat` - Docker alias
- `virtualization.hypervisor.enable` - Run VMs (libvirtd, virt-manager)
- `virtualization.guest.enable` - QEMU guest agent (when this IS a VM)

### Adding a New Host

The `lib.mkHost` function provides the abstraction:

```nix
# flake.nix
my-new-host = lib.mkHost {
  hostname = "my-new-host";
  system = "x86_64-linux";
  user = "brancengregory";
  builder = nixpkgs.lib.nixosSystem;
  homeManagerModule = home-manager.nixosModules.home-manager;
  sopsModule = sops-nix.nixosModules.sops;
  isDesktop = true;  # or false for server
  extraModules = [
    # Additional modules specific to this host
  ];
};
```

Then in `hosts/my-new-host/config.nix`:
```nix
{
  imports = [
    ../../modules/desktop
    ../../modules/hardware
    ../../modules/services
  ];
  
  # Declare capabilities
  desktop.plasma.enable = true;
  modules.hardware.nvidia.enable = true;
  services.backup.enable = true;
  
  system.stateVersion = "25.11";
}
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

## Design Philosophy

1. **Pure Modules**: All modules use `mkEnableOption` with `default = false`
2. **Explicit over Implicit**: No accidental activation via imports
3. **Safe Defaults**: Hardware defaults to disabled (prevents kernel panics)
4. **Clear Separation**: Server, Desktop, and Laptop have distinct capabilities
5. **Bundle Organization**: Related modules grouped for clean imports
6. **Declarative Intent**: Host configs read like a capability manifest

---

**Status**: ✅ Refactor Complete - All system modules use Pure Module pattern
