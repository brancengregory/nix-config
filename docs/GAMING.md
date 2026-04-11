# Gaming

Gaming configuration module for NixOS desktop systems. Provides a complete gaming setup including Steam, emulators, and performance optimizations.

## Overview

The gaming module provides:

- **Steam** with full 32-bit support and firewall rules
- **Gamemode** for automatic performance optimization during gameplay
- **Controller support** (Steam Hardware, 32-bit graphics libraries)
- **Emulators** (RetroArch with multiple cores)
- **Optional launchers** (Prism Launcher, Lutris, Heroic Games Launcher)
- **Performance tools** (MangoHud, Gamescope)

## Configuration

### Basic Setup

Gaming is **enabled by default** on desktop systems. The module is imported automatically when using the desktop configuration.

```nix
# Gaming is enabled by default on desktop systems
# No configuration required for basic setup
```

### GPU-Specific Optimizations

Enable vendor-specific optimizations for your GPU:

```nix
desktop.gaming.gpuVendor = "amd";    # For AMD GPUs
desktop.gaming.gpuVendor = "nvidia"; # For NVIDIA GPUs
```

These settings configure Gamemode with GPU-specific performance tweaks.

## Options

### Core Components (Always Enabled)

These components are always included when gaming is enabled:

| Component | Description |
|-----------|-------------|
| `programs.steam` | Steam client with 32-bit support |
| `programs.gamemode` | Performance optimization daemon |
| `retroarch` | Multi-system emulator frontend |
| `hardware.steam-hardware` | Steam controller support |
| `hardware.graphics.enable32Bit` | 32-bit graphics libraries |

### Default Optional Components

These are enabled by default but can be disabled:

```nix
desktop.gaming = {
  prismLauncher.enable = false;  # Disable Prism Launcher (Minecraft)
  mangohud.enable = false;       # Disable MangoHud overlay
  gamescope.enable = false;      # Disable Gamescope compositor
  protonupQt.enable = false;     # Disable ProtonUp-Qt
};
```

### Additional Optional Components

These are disabled by default and can be enabled:

```nix
desktop.gaming = {
  lutris.enable = true;    # Enable Lutris game launcher
  heroic.enable = true;    # Enable Heroic Games Launcher (GOG/Epic)
  dolphin.enable = true;   # Enable Dolphin emulator (GameCube/Wii)
  pcsx2.enable = true;     # Enable PCSX2 emulator (PS2)
};
```

### Disabling Gaming Entirely

To completely disable gaming features:

```nix
desktop.gaming.enable = false;
```

## RetroArch Cores

The following emulator cores are pre-configured:

| Core | System |
|------|--------|
| snes9x | Super Nintendo |
| mgba | Game Boy / Game Boy Advance |
| genesis-plus-gx | Sega Genesis / Mega Drive |
| nestopia | Nintendo Entertainment System |
| desmume | Nintendo DS |

## File Locations

The module creates standard gaming directories:

- `~/media/games/` - General gaming directory
- `~/media/games/roms/` - ROM files for emulators
- `~/media/games/minecraft/` - Minecraft instances (Prism Launcher)
- `~/.local/share/Steam/` - Steam installation (default location)

## Firewall Configuration

The following ports are automatically opened when gaming is enabled:

- **Steam Remote Play**: UDP 27031-27036
- **Steam Dedicated Server**: UDP 27015-27050, TCP 27015-27050
- **Steam Local Network Transfers**: UDP 27040

## Complete Example

```nix
{ config, pkgs, ... }:

{
  desktop.gaming = {
    enable = true;
    gpuVendor = "amd";  # Enable AMD-specific optimizations
    
    # Optional components (defaults)
    prismLauncher.enable = true;
    mangohud.enable = true;
    gamescope.enable = true;
    protonupQt.enable = true;
    
    # Additional launchers
    lutris.enable = true;
    heroic.enable = true;
  };
}
```

## Troubleshooting

### Gamemode not activating

Gamemode only activates when a game requests it. Most Steam games with Linux native support or Proton should automatically trigger it. Check if gamemode is working:

```bash
gamemoded -t
```

### Controller not detected

Ensure `hardware.steam-hardware.enable` is set (it is by default). Connect the controller before launching the game.

### 32-bit game crashes

The 32-bit graphics libraries are enabled automatically. If you still have issues, check that `hardware.graphics.enable32Bit = true` is set.
