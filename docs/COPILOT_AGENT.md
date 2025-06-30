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

The environment uses GitHub Actions for reliable setup:

1. **GitHub Actions Workflow** - `.github/workflows/setup-nix-env.yml` uses:
   - `DeterminateSystems/nix-installer-action@main` for reliable, fast Nix installation
   - `DeterminateSystems/magic-nix-cache-action@main` for automatic binary caching
   - Proper flakes configuration and validation

2. **Simplified Agent Config** - `.github/copilot-agent.yml` references the workflow
3. **Development Shell** - The agent enters the Nix development shell defined in `flake.nix`
4. **Tool Access** - All development tools become available (just, alejandra, etc.)

### Benefits of GitHub Actions Approach

- **Reliability** - Uses proven, well-tested installation methods
- **Speed** - Fast installation (~4s on Linux, ~20s on macOS)
- **Caching** - Binary cache integration for faster builds
- **Maintenance** - No custom installation scripts to maintain
- **Compatibility** - Works around firewall restrictions

## Configuration Files

### Primary Configuration
- `.github/copilot-agent.yml` - Copilot agent environment configuration
- `.github/workflows/setup-nix-env.yml` - GitHub Actions workflow for Nix setup

### Supporting Files
- `.github/validate-copilot-env.sh` - Environment validation script
- `flake.nix` - Nix flake with development shell definition
- `justfile` - Development command shortcuts

The environment configuration includes:
- **Available commands** - All development commands with descriptions
- **Setup validation** - Automatic checks to ensure everything works
- **Documentation** - Help and troubleshooting information

## Validation

You can validate the environment setup using:

```bash
.github/validate-copilot-env.sh
```

This script checks:
- ✅ Essential files are present (`flake.nix`, `justfile`, etc.)
- ✅ Configuration file syntax is valid
- ✅ GitHub Actions workflow is properly configured
- ✅ Nix commands work correctly (if Nix is available)

## Troubleshooting

### Common Issues

**"nix: command not found"**
- Run the setup workflow: `gh workflow run setup-nix-env.yml`
- Or manually install: `curl -L https://nixos.org/nix/install | sh`
- Source environment: `source ~/.nix-profile/etc/profile.d/nix.sh`

**"experimental features not enabled"**
- The GitHub Actions workflow handles this automatically
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