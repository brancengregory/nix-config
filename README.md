# Nix Config

A set of configs for my machines:

- powerhouse (desktop) - NixOS
- turbine (laptop) - macOS with nix-darwin

## Features

- **Cross-platform**: Supports both NixOS and macOS
- **Home Manager integration**: User-specific configs
- **Unified GPG/SSH**: Integrated authentication and encryption strategy
- **Homebrew support** (macOS): GUI applications and Mac-specific software
- **Minimal approach**: Prefer nixpkgs over Homebrew when possible
- **Cross-compilation**: Build and validate nix-darwin configs from Linux

## Documentation

- [GPG/SSH Strategy](docs/GPG-SSH-STRATEGY.md) - Unified authentication and encryption across all systems
- [Homebrew Integration](docs/HOMEBREW.md) - Managing GUI apps and Mac-specific software
- [Cross-Platform Development](docs/CROSS_COMPILATION.md) - Building nix-darwin configs from Linux
- [GitHub Copilot Agent](docs/COPILOT_AGENT.md) - Development environment for Copilot coding agent

