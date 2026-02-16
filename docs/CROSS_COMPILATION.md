# Cross-Platform Development

This flake supports building and validating nix-darwin configurations from Linux systems.

## Features

### Cross-Compilation
Build nix-darwin configurations on Linux without requiring a macOS system:

```bash
# Build the full darwin configuration from Linux
nix build .#turbine-darwin

# Or use the convenience command
mise build-turbine

# The result will be in ./result/
```

### Configuration Validation
Validate nix-darwin configurations without performing a full build:

```bash
# Check if the darwin configuration is valid
nix build .#turbine-check

# Or use the convenience command
mise check-darwin

# This is faster than a full build and useful for CI/testing
```

**Note**: Some darwin packages with system-specific dependencies may fail during cross-compilation. The validation target helps catch syntax and basic configuration errors without requiring full package builds.

### Development Environment
Use the provided development shell for cross-platform work:

```bash
# Enter the development environment
nix develop
# Or
mise dev

# This provides tools like nixos-rebuild, nix-output-monitor, alejandra, and mise
```

## Linux Builder Setup

For optimal performance when building nix-darwin configurations from Linux, you should set up nix-darwin's linux-builder feature. This enables remote building and improves cross-compilation performance.

### What is nix-darwin's linux-builder?

The linux-builder is a virtual machine that runs on macOS and allows you to build Linux packages remotely. However, in our case, we're doing the reverse - building macOS packages from Linux. The linux-builder configuration in nix-darwin can be adapted for this purpose.

### Setting up Remote Building

1. **Configure a macOS builder** (if you have access to a macOS machine):

Add to your `/etc/nix/nix.conf` on the Linux system:

```
builders = ssh://username@macos-host x86_64-darwin /path/to/remote/nix 2 1 kvm,nixos-test,big-parallel,benchmark
builders-use-substitutes = true
```

2. **Alternative: Use GitHub Actions macOS runners** for CI/CD:

```yaml
name: Build Darwin Config
on: [push, pull_request]

jobs:
  build-darwin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v27
      - name: Validate darwin config
        run: mise check-darwin
      
  build-darwin-native:
    runs-on: macos-latest  
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v27
      - name: Build darwin config natively
        run: mise build-turbine
```

3. **Local cross-compilation** (current setup):

For development and testing, you can use the cross-compilation support directly:

```bash
# Quick validation (recommended for most cases)
mise check-darwin

# Full cross-compilation (may be slower without remote builder)
mise build-turbine
```

### Performance Tips

- **Use `mise check-darwin`** for quick validation during development
- **Set up remote builders** for production deployments
- **Use binary caches** to avoid rebuilding common packages:

```bash
# Add to your nix configuration
nix.settings.substituters = [
  "https://cache.nixos.org/"
  "https://nix-community.cachix.org"
];
```

### Troubleshooting

If you encounter issues with cross-compilation:

1. **Check available builders**:
   ```bash
   nix show-config | grep builders
   ```

2. **Verify cross-compilation support**:
   ```bash
   nix-instantiate --eval -E 'builtins.currentSystem'
   ```

3. **Use verbose output for debugging**:
   ```bash
   nix build .#turbine-darwin --verbose
   ```

## Use Cases

### CI/CD Validation
In continuous integration, you can validate both NixOS and nix-darwin configurations on Linux runners:

```yaml
# Example GitHub Actions workflow
- name: Validate NixOS configuration
  run: mise build-powerhouse

- name: Validate nix-darwin configuration  
  run: mise check-darwin

- name: Cross-compile darwin configuration
  run: mise build-turbine
```

### Development Workflow
When developing on Linux but targeting macOS:

1. **Edit configurations** in your preferred Linux environment
2. **Validate syntax** with `mise check-darwin`
3. **Cross-compile** with `mise build-turbine` to catch platform-specific issues
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
