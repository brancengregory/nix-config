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
desktop.plasma.enable = true;
desktop.sddm.enable = true;
desktop.sddm.theme = "sugar-dark";  # Optional configuration

# Other options available but NOT active:
# desktop.hyprland.enable = false;  # Implicit - not enabled
```

## Module Categories

### Desktop Bundle (`modules/desktop/`)
Available options:
- `desktop.plasma.enable` - KDE Plasma 6 desktop environment
- `desktop.plasma.lookAndFeel` - Theme selection
- `desktop.sddm.enable` - SDDM display manager
- `desktop.sddm.theme` - Optional theme (e.g., "sugar-dark")

**User-level** (`modules/home/desktop/`):
- `home.desktop.plasma.enable` - Plasma user settings via plasma-manager
- `home.desktop.hyprland.enable` - Hyprland window manager
- `home.desktop.hyprland.enableNvidiaPatches` - GPU-specific fixes

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
- `media.audio.enable` - PipeWire audio stack
- `media.audio.server` - Choose: "pipewire" | "pulse" | "alsa" | "none"
- `media.audio.lowLatency` - Use Zen kernel (⚠️ changes kernel!)
- `media.audio.proAudio` - JACK support, real-time limits, Bitwig Studio
- `media.audio.user` - User to add to audio group (default: "brancengregory")

### Network Modules (`modules/network/`)
Already using Pure Module pattern:
- `networking.wireguard-mesh.enable` - WireGuard VPN mesh
- `services.caddy.enable` - Reverse proxy
- `services.netbird.enable` - Netbird VPN

### OS Modules (`modules/os/`)
Base system modules (always-on):
- `common.nix` - Universal settings (flakes, experimental flags)
- `nixos.nix` - NixOS-specific system configuration
- `darwin.nix` - macOS-specific system configuration

These are imported directly by `lib.mkHost`, not via bundles.

### Security Modules (`modules/security/`)
Already using Pure Module pattern:
- `security.gpg.enable` - Declarative GPG key import
- `security.ssh.hostKeysDeclarative.enable` - SSH host key management
- `sops` (via sops-nix module) - Secret management

### Services Bundle (`modules/services/`)
Available options (all using Pure Module pattern):
- `services.backup.enable` - Restic backup with configurable repository, paths
- `services.monitoring.enable` - Prometheus/Grafana stack
  - `services.monitoring.exporters.enable` - Lightweight node exporters (all nodes)
  - `services.monitoring.server.enable` - Heavy Prometheus/Grafana server (monitoring host only)
- `services.download-stack.enable` - qBittorrent, SABnzbd
- `services.git-server.enable` - Forgejo Git server
- `services.media.enable` - Jellyfin, *arr apps
- `services.ollama-server.enable` - Ollama LLM server
- `services.opencode-server.enable` - OpenCode server
- `services.storage.enable` - Minio, NFS, mergerfs, SnapRAID

### Virtualization Bundle (`modules/virtualization/`)
Available options:
- `virtualization.podman.enable` - Container engine (Docker replacement)
- `virtualization.podman.dockerCompat` - Create 'docker' alias
- `virtualization.podman.dnsEnabled` - Container-to-container DNS
- `virtualization.hypervisor.enable` - Run VMs (libvirtd, virt-manager, QEMU)
- `virtualization.hypervisor.virtManager` - Enable virt-manager GUI
- `virtualization.hypervisor.swtpm` - Software TPM (for Windows 11 VMs)
- `virtualization.hypervisor.spice` - SPICE protocol support
- `virtualization.guest.enable` - QEMU guest agent (for when this machine IS a VM)

**Critical**: Use `hypervisor` when running VMs, `guest` when this is a VM. Never enable hypervisor inside a VM!

### Themes Bundle (`modules/themes/`)
Available options:
- `themes.stylix.enable` - Unified theming system
- `themes.stylix.image` - Wallpaper path
- `themes.stylix.base16Scheme` - Color scheme file
- `themes.stylix.autoEnable` - Auto-enable all targets (default: false)

## Host Configuration Pattern

Modern host configurations use the `lib.mkHost` abstraction:

### Example: Server (capacitor)

```nix
# flake.nix
capacitor = lib.mkHost {
  hostname = "capacitor";
  system = "x86_64-linux";
  user = "brancengregory";
  builder = nixpkgs.lib.nixosSystem;
  homeManagerModule = home-manager.nixosModules.home-manager;
  sopsModule = sops-nix.nixosModules.sops;
  isDesktop = false;  # Headless server
  extraModules = [ inputs.disko.nixosModules.disko ];
};

# hosts/capacitor/config.nix
{ config, pkgs, ... }: {
  imports = [
    ../../modules/services  # All services available
    ../../modules/virtualization  # Podman available
    # No desktop, hardware, or media bundles - this is a server!
  ];
  
  # Enable only what the server needs
  services.backup.enable = true;
  services.monitoring = {
    enable = true;
    exporters.enable = true;
    server.enable = true;  # This is the monitoring host
  };
  
  virtualization.podman.enable = true;
  virtualization.hypervisor.enable = false;  # Don't run VMs on server
  
  system.stateVersion = "25.11";
}
```

### Example: Desktop (powerhouse)

```nix
# flake.nix
powerhouse = lib.mkHost {
  hostname = "powerhouse";
  system = "x86_64-linux";
  user = "brancengregory";
  builder = nixpkgs.lib.nixosSystem;
  homeManagerModule = home-manager.nixosModules.home-manager;
  sopsModule = sops-nix.nixosModules.sops;
  isDesktop = true;
  extraModules = [ 
    inputs.disko.nixosModules.disko
    inputs.plasma-manager.homeModules.plasma-manager
  ];
};

# hosts/powerhouse/config.nix
{ config, pkgs, ... }: {
  imports = [
    ../../modules/desktop     # Plasma, SDDM available
    ../../modules/hardware    # NVIDIA, Bluetooth available
    ../../modules/media       # Audio available
    ../../modules/services    # Backup, monitoring available
    ../../modules/virtualization  # Podman, QEMU available
    ../../modules/themes      # Stylix available
  ];
  
  # Desktop Environment
desktop.plasma.enable = true;
  desktop.sddm.enable = true;
  themes.stylix.enable = true;
  
  # Hardware
  modules.hardware.nvidia.enable = true;
  modules.hardware.bluetooth.enable = true;
  
  # Audio (Pro audio setup)
  media.audio.enable = true;
  media.audio.lowLatency = true;
  media.audio.proAudio = true;
  
  # Services
  services.backup.enable = true;
  services.monitoring = {
    enable = true;
    exporters.enable = true;  # Just the lightweight exporter
    server.enable = false;    # Don't run heavy server on desktop
  };
  
  # Virtualization (Run VMs, not a VM)
  virtualization.podman.enable = true;
  virtualization.hypervisor = {
    enable = true;
    virtManager = true;
    swtpm = true;  # For Windows 11 VMs
  };
  
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
  home.desktop.plasma = lib.mkIf isDesktop {
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
  cfg = config.category.myModule;
in {
  options.category.myModule = {
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
- `desktop.plasma.enable`
- `desktop.plasma.lookAndFeel`
- `desktop.sddm.enable`
- `desktop.sddm.theme`

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
- `media.audio.enable`
- `media.audio.server`
- `media.audio.lowLatency`
- `media.audio.proAudio`
- `media.audio.user`

### Services
- `services.backup.enable`
- `services.monitoring.enable`
- `services.monitoring.exporters.enable`
- `services.monitoring.exporters.port`
- `services.monitoring.exporters.collectors`
- `services.monitoring.server.enable`
- `services.monitoring.server.prometheusPort`
- `services.monitoring.server.grafanaPort`
- `services.monitoring.server.grafanaBind`
- `services.download-stack.enable`
- `services.git-server.enable`
- `services.media.enable`
- `services.ollama-server.enable`
- `services.opencode-server.enable`
- `services.storage.enable`

### Virtualization
- `virtualization.podman.enable`
- `virtualization.podman.dockerCompat`
- `virtualization.podman.dnsEnabled`
- `virtualization.podman.extraPackages`
- `virtualization.hypervisor.enable`
- `virtualization.hypervisor.virtManager`
- `virtualization.hypervisor.swtpm`
- `virtualization.hypervisor.spice`
- `virtualization.guest.enable`
- `virtualization.guest.spice`

### Themes
- `themes.stylix.enable`
- `themes.stylix.image`
- `themes.stylix.base16Scheme`
- `themes.stylix.autoEnable`

### Home Desktop
- `home.desktop.plasma.enable`
- `home.desktop.plasma.lookAndFeel`
- `home.desktop.plasma.virtualDesktops`
- `home.desktop.hyprland.enable`
- `home.desktop.hyprland.enableNvidiaPatches`
