# Nix Config

A set of configs for my machines using the **Pure Module Pattern**:

- **orbital** (server) - NixOS homelab server
- **voyager** (laptop) - Framework 16 with AMD Ryzen AI 300

## Features

- **Pure Module Architecture**: 20+ modules using `mkEnableOption` - import to make available, enable to activate
- **Bundle-Based Organization**: Clean imports via `modules/desktop`, `modules/hardware`, `modules/services`
- **Declarative API**: Hosts declare capabilities via `modules.desktop.plasma.enable = true`, not file imports
- **Home Manager integration**: User-specific configs with modular component imports
- **Unified GPG/SSH**: Integrated authentication and encryption strategy with Nitrokey hardware tokens
- **SOPS-nix**: Declarative secret management with age encryption
- **nix-anywhere**: Remote deployment to bare metal

## Documentation

- **[Deployment Guide](docs/DEPLOYMENT.md)** - How to deploy NixOS with nix-anywhere
- **[Complete Documentation](docs/)** - Full documentation site with detailed guides
- **[Secret Management](docs/SECRET_MANAGEMENT.md)** - Declarative secret management with sops and age
- **[GPG/SSH Strategy](docs/GPG-SSH-STRATEGY.md)** - Unified authentication and encryption with hardware tokens
- **[Module Architecture](docs/MODULES.md)** - Understanding the modular system

## Repository Structure

```
├── docs/               # Documentation
├── hosts/              # Host-specific configurations
│   ├── orbital/        # NixOS homelab server
│   └── voyager/        # Framework 16 laptop
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
modules.desktop.plasma.enable = true;
modules.desktop.sddm.enable = true;

# Other options available but inactive:
# desktop.sddm.enable = false;  # Implicit - not enabled
```

### Declarative API Examples

**Desktop/Workstation (powerhouse):**
```nix
# Desktop Environment
modules.desktop.plasma.enable = true;
modules.desktop.sddm.enable = true;
modules.themes.stylix.enable = true;

# Hardware
modules.hardware.nvidia.enable = true;
modules.hardware.bluetooth.enable = true;
modules.media.audio.enable = true;
modules.media.audio.lowLatency = true;

# Services
modules.services.backup.enable = true;
modules.services.monitoring.enable = true;
modules.services.monitoring.exporters.enable = true;

# Virtualization
modules.virtualization.podman.enable = true;
modules.virtualization.hypervisor.enable = true;  # Run VMs
```

**Server (capacitor):**
```nix
# No desktop environment - headless server
# modules.services.backup.enable = true;  # Already enabled via service config
modules.services.monitoring.enable = true;
modules.services.monitoring.server.enable = true;  # Full Prometheus/Grafana

# Virtualization for containers only
modules.virtualization.podman.enable = true;
modules.virtualization.hypervisor.enable = false;  # Don't run VMs on server
```

### Available Module Bundles

**Desktop Bundle** (`modules/desktop/`):
- `modules.desktop.plasma.enable` - KDE Plasma 6 desktop
- `modules.desktop.sddm.enable` - SDDM display manager
- `modules.desktop.sddm.theme` - Optional theme

**Hardware Bundle** (`modules/hardware/`):
- `modules.hardware.nvidia.enable` - NVIDIA GPU drivers
- `modules.hardware.nvidia.open` - Use open-source kernel modules
- `modules.hardware.bluetooth.enable` - Bluetooth subsystem
- `modules.hardware.bluetooth.powerOnBoot` - Auto-power behavior

**Media Bundle** (`modules/media/`):
- `modules.media.audio.enable` - PipeWire audio stack
- `modules.media.audio.lowLatency` - Zen kernel for pro audio (⚠️ changes kernel)
- `modules.media.audio.proAudio` - JACK support, Bitwig Studio

**Services Bundle** (`modules/services/`):
- `modules.services.backup.enable` - Restic backup
- `modules.services.monitoring.enable` - Prometheus/Grafana stack
- `modules.services.monitoring.exporters.enable` - Lightweight node exporters
- `modules.services.monitoring.server.enable` - Heavy monitoring server
- Plus: download, git, media, ollama, opencode, storage

**Virtualization Bundle** (`modules/virtualization/`):
- `modules.virtualization.podman.enable` - Container engine
- `modules.virtualization.podman.dockerCompat` - Docker alias
- `modules.virtualization.hypervisor.enable` - Run VMs (libvirtd, virt-manager)
- `modules.virtualization.guest.enable` - QEMU guest agent (when this IS a VM)

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
  modules.desktop.plasma.enable = true;
  modules.hardware.nvidia.enable = true;
  modules.services.backup.enable = true;

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
mise build-orbital
mise build-voyager

# Validate configs
mise check

# Build all configurations
mise build-all

# Deploy (via nix-anywhere)
nixos-anywhere --flake .#<hostname> root@<target-ip>
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
