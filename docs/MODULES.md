# Module Architecture

This configuration uses a modular architecture with 20+ modules organized across 11 categories. Each module encapsulates specific functionality and can be imported as needed by host and user configurations.

## Module Categories

### Desktop Modules (`modules/desktop/`)
- **plasma.nix** - KDE Plasma desktop environment
- **plasma-home.nix** - Plasma user-specific settings (via plasma-manager)
- **hyprland.nix** - Hyprland window manager configuration
- **sddm.nix** - SDDM display manager configuration

### Font Modules (`modules/fonts/`)  
- **default.nix** - System font configurations and font packages

### Hardware Modules (`modules/hardware/`)
- **nvidia.nix** - NVIDIA GPU drivers and configuration
- **bluetooth.nix** - Bluetooth service and configuration

### Media Modules (`modules/media/`)
- **audio.nix** - PipeWire/Pipewire audio configuration

### Network Modules (`modules/network/`)
- **wireguard.nix** - WireGuard VPN configuration

### OS Modules (`modules/os/`)
- **common.nix** - Universal settings for all systems (Nix features, experimental flags)
- **nixos.nix** - NixOS-specific system configurations
- **darwin.nix** - macOS-specific system configurations

### Program Modules (`modules/programs/`)
- **git.nix** - Git configuration and aliases

### Security Modules (`modules/security/`)
- **default.nix** - Unified GPG, SSH, and GPG Agent configuration

### Service Modules (`modules/services/`)
- **backup.nix** - Restic backup service configuration
- **monitoring.nix** - System monitoring services

### Terminal Modules (`modules/terminal/`)
- **nvim.nix** - Neovim editor configuration
- **starship.nix** - Starship prompt configuration  
- **tmux.nix** - Terminal multiplexer configuration
- **zsh.nix** - Z shell configuration and plugins

### Virtualization Modules (`modules/virtualization/`)
- **podman.nix** - Podman container runtime
- **qemu.nix** - QEMU virtualization platform

## Module Usage Patterns

### Host Configuration Pattern

Host configurations (`hosts/*/config.nix`) typically import:
- OS-specific modules (`modules/os/common.nix` + `modules/os/nixos.nix` or `modules/os/darwin.nix`)
- Hardware-specific modules as needed
- Host-specific hardware configuration

Example:
```nix
{pkgs, ...}: {
  imports = [
    ../../modules/os/common.nix    # Universal settings
    ../../modules/os/nixos.nix     # NixOS-specific settings
    ./hardware.nix                 # Host hardware config
  ];
  
  networking.hostName = "powerhouse";
  system.stateVersion = "25.11";
}
```

### User Configuration Pattern  

User configurations (`users/*/home.nix`) import user-specific modules:

```nix
{pkgs, ...}: {
  imports = [
    ../../modules/fonts/default.nix
    ../../modules/terminal/zsh.nix
    ../../modules/terminal/starship.nix
    ../../modules/terminal/tmux.nix
    ../../modules/terminal/nvim.nix
    ../../modules/security/default.nix
    ../../modules/network/wireguard.nix
    ../../modules/programs/git.nix
  ];
  
  # User-specific configuration
  home.username = "username";
  # ... rest of configuration
}
```

## Cross-Platform Compatibility

Modules are designed to work across NixOS and macOS:

- **OS modules** provide platform-specific configurations
- **User modules** use conditional logic for platform differences
- **Hardware modules** are imported only when relevant

Example of cross-platform user configuration:
```nix
home.homeDirectory = 
  if pkgs.stdenv.isLinux 
  then "/home/username"
  else if pkgs.stdenv.isDarwin
  then "/Users/username" 
  else throw "Unsupported OS";
```

## Adding New Modules

### 1. Choose the Right Category
Place your module in the appropriate directory:
- System-level configs → `modules/os/`
- User programs → `modules/programs/`
- Terminal tools → `modules/terminal/`
- Security configs → `modules/security/`
- etc.

### 2. Follow Module Structure
```nix
{pkgs, ...}: {
  # Module configuration here
  # Use conditional logic for cross-platform support if needed
}
```

### 3. Import in Configurations
Add the module import to relevant host or user configurations:
```nix
imports = [
  ../../modules/category/your-module.nix
  # ... other imports
];
```

### 4. Test the Configuration
```bash
# Validate syntax
nix flake check

# Test darwin config
mise check-darwin

# Test NixOS config  
mise build-powerhouse
```

## Module Dependencies

Modules can depend on other modules by importing them:
```nix
{pkgs, ...}: {
  imports = [
    ./base-module.nix
  ];
  
  # Additional configuration
}
```

Keep dependencies minimal and well-documented to maintain modularity.