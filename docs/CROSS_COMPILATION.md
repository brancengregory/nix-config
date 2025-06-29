# Cross-Platform Development

This flake supports building and validating nix-darwin configurations from Linux systems.

## Features

### Cross-Compilation
Build nix-darwin configurations on Linux without requiring a macOS system:

```bash
# Build the full darwin configuration from Linux
nix build .#turbine-darwin

# Or use the convenience command
make build-darwin

# The result will be in ./result/
```

### Configuration Validation
Validate nix-darwin configurations without performing a full build:

```bash
# Check if the darwin configuration is valid
nix build .#turbine-check

# Or use the convenience command
make check-darwin

# This is faster than a full build and useful for CI/testing
```

### Development Environment
Use the provided development shell for cross-platform work:

```bash
# Enter the development environment
nix develop
# Or
make dev

# This provides tools like nixos-rebuild, nix-output-monitor, and alejandra
```

### Testing
Test the cross-compilation setup:

```bash
# Run the test script
./test-cross-compilation.sh
# Or
make test
```

## Use Cases

### CI/CD Validation
In continuous integration, you can validate both NixOS and nix-darwin configurations on Linux runners:

```yaml
# Example GitHub Actions workflow
- name: Validate NixOS configuration
  run: nix build .#powerhouse-vm

- name: Validate nix-darwin configuration  
  run: nix build .#turbine-check

- name: Cross-compile darwin configuration
  run: nix build .#turbine-darwin
```

### Development Workflow
When developing on Linux but targeting macOS:

1. **Edit configurations** in your preferred Linux environment
2. **Validate syntax** with `nix build .#turbine-check`
3. **Cross-compile** with `nix build .#turbine-darwin` to catch platform-specific issues
4. **Deploy** the configuration on actual macOS hardware when ready

## Requirements

- Nix with flakes enabled
- Linux system with sufficient disk space for cross-compilation
- Network access to download dependencies

## Troubleshooting

### Build Errors
If cross-compilation fails:
- Check that all dependencies support the target platform
- Some macOS-specific packages may not cross-compile successfully
- Consider using remote builders for problematic packages

### Performance
Cross-compilation can be resource-intensive:
- Use `nix build --max-jobs auto` to utilize all CPU cores
- Consider using a remote darwin builder for better performance
- The validation target (`turbine-check`) is much faster than full builds

## Remote Builders

For better performance, you can set up a remote macOS builder:

```nix
# In your nix configuration
nix.buildMachines = [{
  hostName = "mac-builder.example.com";
  system = "x86_64-darwin";
  maxJobs = 4;
  speedFactor = 2;
  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
  mandatoryFeatures = [ ];
}];
```

This allows Nix to automatically use the remote macOS system for darwin-specific builds.