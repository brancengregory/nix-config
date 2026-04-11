# Module Architecture

This configuration uses the **Pure Module Pattern** with 20+ modules organized across 10 categories. Each module defines options that can be explicitly enabled, following the NixOS module system best practices.

## Design Philosophy

Unlike traditional Nix configurations where importing a module immediately activates it, this repository uses **Pure Modules** with explicit `mkEnableOption`:

1. **Import the bundle** to make options available
2. **Explicitly enable** what you want with `enable = true`
3. **Safe defaults** - everything defaults to disabled

### Example - Pure Module Pattern

```nix
# Import the bundle (makes options available)
imports = [
  ../../modules/desktop  # plasma, sddm available but inactive
];

# Explicitly choose what to enable
modules.desktop.plasma.enable = true;
modules.desktop.sddm.enable = true;
modules.desktop.sddm.theme = "sugar-dark";  # Optional configuration

# Other options available but NOT active:
# modules.desktop.hyprland.enable = false;  # Implicit - not enabled
```

## Module Categories

### Desktop Bundle (`modules/desktop/`)
Available options:
- `modules.desktop.plasma.enable` - KDE Plasma 6 desktop environment
- `modules.desktop.plasma.lookAndFeel` - Theme selection
- `modules.desktop.sddm.enable` - SDDM display manager
- `modules.desktop.sddm.theme` - Optional theme (e.g., "sugar-dark")

**User-level** (`modules/home/desktop/`):
- `modules.home.desktop.plasma.enable` - Plasma user settings via plasma-manager
- `modules.home.desktop.hyprland.enable` - Hyprland window manager
- `modules.home.desktop.hyprland.enableNvidiaPatches` - GPU-specific fixes

### Hardware Bundle (`modules/hardware/`)
Available options:
- `modules.hardware.nvidia.enable` - NVIDIA GPU drivers
- `modules.hardware.nvidia.open` - Use open-source kernel modules (Turing+)
- `modules.hardware.nvidia.powerManagement.enable` - VRAM save on sleep (experimental)
- `modules.hardware.bluetooth.enable` - Bluetooth subsystem
- `modules.hardware.bluetooth.powerOnBoot` - Auto-power behavior (default: false)
- `modules.hardware.bluetooth.guiManager` - Enable blueman GUI

### Media Bundle (`modules/media/`)
Available options:
- `modules.media.audio.enable` - PipeWire audio stack
- `modules.media.audio.server` - Choose: "pipewire" | "pulse" | "alsa" | "none"
- `modules.media.audio.lowLatency` - Use Zen kernel (⚠️ changes kernel!)
- `modules.media.audio.proAudio` - JACK support, real-time limits, Bitwig Studio
- `modules.media.audio.user` - User to add to audio group (default: "brancengregory")

### Network Modules (`modules/network/`)
Already using Pure Module pattern:
- `modules.networking.wireguard-mesh.enable` - WireGuard VPN mesh
- `modules.services.caddy-proxy.enable` - Reverse proxy
- `modules.services.netbird-server.enable` - Netbird VPN

### OS Modules (`modules/os/`)
Base system modules (always-on):
- `common.nix` - Universal settings (flakes, experimental flags)
- `nixos.nix` - NixOS-specific system configuration
- `darwin.nix` - macOS-specific system configuration

These are imported directly by `lib.mkHost`, not via bundles.

### Security Modules (`modules/security/`)
Already using Pure Module pattern:
- `modules.security.gpg.enable` - Declarative GPG key import
- `modules.services.openssh.hostKeysDeclarative.enable` - SSH host key management
- `sops` (via sops-nix module) - Secret management

### Services Bundle (`modules/services/`)
Available options (all using Pure Module pattern):
- `modules.services.backup.enable` - Restic backup with configurable repository, paths
- `modules.services.monitoring.enable` - Prometheus/Grafana stack
  - `modules.services.monitoring.exporters.enable` - Lightweight node exporters (all nodes)
  - `modules.services.monitoring.server.enable` - Heavy Prometheus/Grafana server (monitoring host only)
- `modules.services.download-stack.enable` - qBittorrent, SABnzbd
- `modules.services.git-server.enable` - Forgejo Git server
- `modules.services.media.enable` - Jellyfin, *arr apps
- `modules.services.ollama-server.enable` - Ollama LLM server
- `modules.services.opencode-server.enable` - OpenCode server
- `modules.services.storage.enable` - Minio, NFS, mergerfs, SnapRAID

### Virtualization Bundle (`modules/virtualization/`)
Available options:
- `modules.virtualization.podman.enable` - Container engine (Docker replacement)
- `modules.virtualization.podman.dockerCompat` - Create 'docker' alias
- `modules.virtualization.podman.dnsEnabled` - Container-to-container DNS
- `modules.virtualization.hypervisor.enable` - Run VMs (libvirtd, virt-manager, QEMU)
- `modules.virtualization.hypervisor.virtManager` - Enable virt-manager GUI
- `modules.virtualization.hypervisor.swtpm` - Software TPM (for Windows 11 VMs)
- `modules.virtualization.hypervisor.spice` - SPICE protocol support
- `modules.virtualization.guest.enable` - QEMU guest agent (for when this machine IS a VM)

**Critical**: Use `hypervisor` when running VMs, `guest` when this is a VM. Never enable hypervisor inside a VM!

### Themes Bundle (`modules/themes/`)
Available options:
- `modules.themes.stylix.enable` - Unified theming system
- `modules.themes.stylix.image` - Wallpaper path
- `modules.themes.stylix.base16Scheme` - Color scheme file
- `modules.themes.stylix.autoEnable` - Auto-enable all targets (default: false)

## Host Configuration Pattern

Modern host configurations use the `lib.mkHost` abstraction:

### Example: Server (orbital)

```nix
# flake.nix
orbital = lib.mkHost {
  hostname = "orbital";
  system = "x86_64-linux";
  user = "brancengregory";
  builder = nixpkgs.lib.nixosSystem;
  homeManagerModule = home-manager.nixosModules.home-manager;
  sopsModule = sops-nix.nixosModules.sops;
  isDesktop = false;  # Headless server
  extraModules = [ inputs.disko.nixosModules.disko ];
};

# hosts/orbital/config.nix
{ config, pkgs, ... }: {
  imports = [
    ../../modules/services  # All services available
    ../../modules/virtualization  # Podman available
    # No desktop, hardware, or media bundles - this is a server!
  ];

  # Enable only what the server needs
  modules.services.backup.enable = true;
  modules.services.monitoring = {
    enable = true;
    exporters.enable = true;
    server.enable = true;  # This is the monitoring host
  };

  modules.virtualization.podman.enable = true;
  modules.virtualization.hypervisor.enable = false;  # Don't run VMs on server

  system.stateVersion = "25.11";
}
```

### Example: Desktop (voyager)

```nix
# flake.nix
voyager = lib.mkHost {
  hostname = "voyager";
  system = "x86_64-linux";
  user = "brancengregory";
  builder = nixpkgs.lib.nixosSystem;
  homeManagerModule = home-manager.nixosModules.home-manager;
  sopsModule = sops-nix.nixosModules.sops;
  isDesktop = true;
  extraModules = [
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series
  ];
};

# hosts/voyager/config.nix
{ config, pkgs, ... }: {
  imports = [
    ./hardware.nix  # Framework 16 hardware config
    ./disks.nix     # Disk configuration

    ../../modules/desktop     # Plasma, SDDM available
    ../../modules/hardware    # Bluetooth available
    ../../modules/media       # Audio, gaming available
    ../../modules/services    # Monitoring available
    ../../modules/virtualization  # Podman, QEMU available
    ../../modules/themes      # Stylix available
  ];

  # Desktop Environment
  modules.desktop.plasma.enable = true;
  modules.desktop.sddm.enable = true;
  modules.themes.stylix.enable = true;

  # Hardware
  modules.hardware.bluetooth.enable = true;

  # Gaming (AMD iGPU)
  modules.desktop.gaming = {
    enable = true;
    gpuVendor = "amd";
  };

  # Services
  modules.services.monitoring = {
    enable = true;
    exporters.enable = true;  # Just the lightweight exporter
    server.enable = false;    # Don't run heavy server on desktop
  };

  # Virtualization (Run VMs, not a VM)
  modules.virtualization.podman.enable = true;
  modules.virtualization.hypervisor.enable = true;

  system.stateVersion = "25.11";
}
```

## User Configuration Pattern

User configurations (`users/*/home.nix`) are imported automatically by `lib.mkHost`. They should use the standard home-manager module pattern:

```nix
{ config, pkgs, lib, isLinux, isDesktop, ... }: {
  imports = [
    ../../modules/home/desktop/plasma.nix  # If using plasma
  ];
  
  # Desktop-specific settings
  modules.home.desktop.plasma = lib.mkIf isDesktop {
    enable = true;
    virtualDesktops = 4;
  };
  
  # Program configurations
  programs.git.enable = true;
  programs.zsh.enable = true;
}
```

## Adding New Modules

### 1. Create the Module

```nix
# modules/category/my-module.nix
{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.modules.category.myModule;
in {
  options.modules.category.myModule = {
    enable = mkEnableOption "my module description";
    
    someOption = mkOption {
      type = types.str;
      default = "default-value";
      description = "Description of this option";
    };
  };
  
  config = mkIf cfg.enable {
    # Configuration only applied when enabled
    services.myService.enable = true;
    services.myService.setting = cfg.someOption;
  };
}
```

### 2. Add to Bundle (if applicable)

```nix
# modules/category/default.nix
{ lib, ... }: {
  imports = [
    ./my-module.nix
    ./existing-module.nix
  ];
}
```

### 3. Import Bundle in Host Config

```nix
# hosts/my-host/config.nix
{
  imports = [
    ../../modules/category  # Import the bundle
  ];
  
  # Enable the specific module
  category.myModule.enable = true;
  category.myModule.someOption = "custom-value";
}
```

### 4. Test

```bash
# Validate syntax
nix flake check

# Test specific host
mise build-my-host
```

## Module Dependencies

Modules can reference other modules' options:

```nix
{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.myService;
in {
  options.services.myService = {
    enable = mkEnableOption "my service";
  };
  
  config = mkIf cfg.enable {
    # Reference another module's option
    services.dependency.enable = mkDefault true;
    
    # Or check if another module is enabled
    environment.systemPackages = mkIf config.services.backup.enable [ 
      pkgs.restic 
    ];
  };
}
```

## Best Practices

1. **Always use `mkEnableOption`** with `default = false`
2. **Namespace options** to avoid conflicts (e.g., `modules.hardware.nvidia` not just `nvidia`)
3. **Guard with `mkIf cfg.enable`** - don't apply config when disabled
4. **Use bundles** - group related modules in `default.nix`
5. **Explicit over implicit** - no "magic" activation via imports
6. **Document options** - provide clear descriptions and examples

## Complete Option Reference

### Desktop
- `modules.desktop.plasma.enable`
- `modules.desktop.plasma.lookAndFeel`
- `modules.desktop.sddm.enable`
- `modules.desktop.sddm.theme`

### Hardware
- `modules.hardware.nvidia.enable`
- `modules.hardware.nvidia.open`
- `modules.hardware.nvidia.powerManagement.enable`
- `modules.hardware.nvidia.powerManagement.finegrained`
- `modules.hardware.nvidia.nvidiaSettings`
- `modules.hardware.bluetooth.enable`
- `modules.hardware.bluetooth.powerOnBoot`
- `modules.hardware.bluetooth.guiManager`

### Media
- `modules.media.audio.enable`
- `modules.media.audio.server`
- `modules.media.audio.lowLatency`
- `modules.media.audio.proAudio`
- `modules.media.audio.user`

### Services
- `modules.services.backup.enable`
- `modules.services.monitoring.enable`
- `modules.services.monitoring.exporters.enable`
- `modules.services.monitoring.exporters.port`
- `modules.services.monitoring.exporters.collectors`
- `modules.services.monitoring.server.enable`
- `modules.services.monitoring.server.prometheusPort`
- `modules.services.monitoring.server.grafanaPort`
- `modules.services.monitoring.server.grafanaBind`
- `modules.services.download-stack.enable`
- `modules.services.git-server.enable`
- `modules.services.media.enable`
- `modules.services.ollama-server.enable`
- `modules.services.opencode-server.enable`
- `modules.services.storage.enable`

### Virtualization
- `modules.virtualization.podman.enable`
- `modules.virtualization.podman.dockerCompat`
- `modules.virtualization.podman.dnsEnabled`
- `modules.virtualization.podman.extraPackages`
- `modules.virtualization.hypervisor.enable`
- `modules.virtualization.hypervisor.virtManager`
- `modules.virtualization.hypervisor.swtpm`
- `modules.virtualization.hypervisor.spice`
- `modules.virtualization.guest.enable`
- `modules.virtualization.guest.spice`

### Themes
- `modules.themes.stylix.enable`
- `modules.themes.stylix.image`
- `modules.themes.stylix.base16Scheme`
- `modules.themes.stylix.autoEnable`

### Home Desktop
- `modules.home.desktop.plasma.enable`
- `modules.home.desktop.plasma.lookAndFeel`
- `modules.home.desktop.plasma.virtualDesktops`
- `modules.home.desktop.hyprland.enable`
- `modules.home.desktop.hyprland.enableNvidiaPatches`
