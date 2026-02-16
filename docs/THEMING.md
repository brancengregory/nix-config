# Unified Theming with Stylix

This repository uses **Stylix** to provide a unified, system-wide aesthetic across both NixOS (`powerhouse`) and macOS (`turbine`).

## Overview

Stylix allows us to define a single source of truth for our system's visual identity, including:

- **Color Scheme**: Tokyo Night Dark
- **Wallpaper**: NixOS Dracula (master artwork)
- **Fonts**: Fira Code Nerd Font (Monospace), DejaVu (Sans/Serif)
- **Cursor**: Breeze Snow (24px)
- **Opacity**: 95% terminal transparency

## Architecture

The styling configuration is centralized in `modules/themes/stylix.nix`. 

### Selective Targeting

To avoid conflicts with the KDE Plasma 6 desktop environment (which is managed authoritatively via `plasma-manager`), Stylix is configured with `autoEnable = false`.

We selectively enable Stylix for specific, safe targets:

- **System Level**: Console and GTK.
- **User Level**: Starship and Ghostty (configured in `users/brancengregory/home.nix`).

## Configuration

### Global Settings (`modules/themes/stylix.nix`)

```nix
stylix = {
  enable = true;
  autoEnable = false; # Prevents interference with Plasma 6
  base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
  
  image = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-dracula.png";
    sha256 = "...";
  };

  fonts.monospace = {
    package = pkgs.nerd-fonts.fira-code;
    name = "FiraCode Nerd Font Mono";
  };
  
  # ... cursor and opacity settings
};
```

### User Overrides (`users/brancengregory/home.nix`)

In the Home Manager profile, we explicitly enable Stylix for terminal tools:

```nix
stylix.targets = {
  starship.enable = true;
  ghostty.enable = true;
};
```

## Changing the Theme

To change the entire system's look, you only need to modify `modules/themes/stylix.nix`. For example, to switch to Gruvbox:

1. Update `base16Scheme` to point to a gruvbox YAML file.
2. Update the `image` URL and hash to a matching wallpaper.
3. Run `mise build-powerhouse` or `mise build-capacitor` (or run `nixos-rebuild switch` on the target system) to apply changes.

## Troubleshooting

### Version Mismatches
If you see warnings about Stylix and NixOS/Home Manager version mismatches, they are suppressed using `stylix.enableReleaseChecks = false` in `home-manager.sharedModules`.

### UI Artifacts
If a specific application looks broken with Stylix colors, you can disable theming for just that app in the `targets` block of either the system or user configuration.
