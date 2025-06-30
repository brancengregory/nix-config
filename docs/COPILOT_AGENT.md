# GitHub Copilot Coding Agent Environment

This repository is configured with a GitHub Copilot coding agent environment that provides seamless access to all essential Nix development tools and commands.

## Features

The Copilot agent environment automatically provides:

- **Nix with flakes support** - Reliable installation using DeterminateSystems/nix-installer-action
- **Development shell** - Access to all tools via `nix develop`
- **Command runner** - `just` for convenient development commands
- **Code formatting** - `alejandra` Nix formatter
- **Cross-compilation** - Build and validate configs across platforms
- **Testing framework** - Automated validation and testing
- **Binary caching** - Fast builds with magic-nix-cache-action

## Available Commands

### Core Nix Commands
```bash
nix flake check          # Check flake syntax and evaluate all outputs
nix develop             # Enter development shell with all tools
nix build .#<package>   # Build specific packages or configurations
```

### Just Command Shortcuts
```bash
just help               # Show all available development commands
just check              # Check flake syntax (alias for nix flake check)
just check-darwin       # Validate nix-darwin config (fast validation)
just build-darwin       # Cross-compile full nix-darwin config from Linux
just build-linux        # Build NixOS VM for testing
just format             # Format Nix files using alejandra
just test               # Run cross-compilation tests
just clean              # Clean build results and artifacts
```

## Environment Setup

The environment uses GitHub Copilot's official setup workflow approach:

1. **Copilot Setup Steps** - `.github/workflows/copilot-setup-steps.yml` follows GitHub's official documentation and uses:
   - `DeterminateSystems/nix-installer-action@main` for reliable, fast Nix installation
   - `DeterminateSystems/magic-nix-cache-action@main` for automatic binary caching
   - Proper flakes configuration and validation

2. **Development Shell** - The agent enters the Nix development shell defined in `flake.nix`
3. **Tool Access** - All development tools become available (just, alejandra, etc.)

### Benefits of GitHub Copilot Setup Approach

- **Official** - Follows GitHub's official documentation for Copilot setup steps
- **Simple** - Single workflow file instead of multiple configuration files
- **Reliable** - Uses proven, well-tested installation methods
- **Speed** - Fast installation (~4s on Linux, ~20s on macOS)
- **Caching** - Binary cache integration for faster builds
- **Maintenance** - Minimal configuration to maintain
- **Compatibility** - Works around firewall restrictions

## Configuration Files

### Primary Configuration
- `.github/workflows/copilot-setup-steps.yml` - GitHub Copilot setup workflow following official documentation

### Supporting Files
- `flake.nix` - Nix flake with development shell definition
- `justfile` - Development command shortcuts

The setup provides:
- **Automatic Nix installation** - Uses DeterminateSystems actions for reliable setup
- **Development shell access** - All tools available via `nix develop`
- **Flake validation** - Ensures configuration syntax is correct

## Validation

The copilot-setup-steps.yml workflow automatically validates the environment by:

- ✅ Installing Nix with flakes support
- ✅ Checking flake syntax with `nix flake check`
- ✅ Entering development shell to verify tools are available

You can manually run the workflow to test the setup:

```bash
gh workflow run copilot-setup-steps.yml
```

## Troubleshooting

### Common Issues

**"nix: command not found"**
- The copilot-setup-steps.yml workflow automatically installs Nix
- Or manually install: `curl -L https://nixos.org/nix/install | sh`
- Source environment: `source ~/.nix-profile/etc/profile.d/nix.sh`

**"experimental features not enabled"**
- The copilot-setup-steps.yml workflow handles this automatically
- Manual fix: `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`

**"just: command not found"**
- Enter dev shell first: `nix develop`
- Or run commands via: `nix develop -c just <command>`

**Flake evaluation errors**
- Check syntax: `nix flake check --no-build`
- Update inputs: `nix flake update`

**GitHub Actions setup issues**
- Check workflow logs for detailed error messages
- Ensure `DeterminateSystems/nix-installer-action@main` is used
- Verify GitHub token permissions for private repositories
- Magic Nix Cache provides automatic caching for faster builds

**Build failures**
- Clean previous builds: `just clean`
- Check available packages: `nix flake show`

## Development Workflow

The typical development workflow with the Copilot agent:

1. **Validate configuration**: `nix flake check`
2. **Make changes** to Nix files
3. **Format code**: `just format`
4. **Test changes**: `just test` or specific validation commands
5. **Build configurations**: `just build-darwin` or `just build-linux`

## Cross-Platform Support

The environment supports cross-platform development:

- **Linux**: Full support for NixOS configurations and cross-compilation to macOS
- **macOS**: Native nix-darwin support with Linux VM building capabilities
- **Validation**: Quick config validation without full builds using `just check-darwin`

## Integration with Repository

The Copilot agent environment is fully integrated with this repository's structure:

- **Flake-based**: Uses the `devShells` defined in `flake.nix`
- **Just integration**: All `justfile` commands are available
- **Cross-compilation**: Supports the existing cross-platform workflow
- **Testing**: Integrates with existing test scripts

This provides the Copilot agent with full access to all development capabilities of this Nix configuration repository.