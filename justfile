# Cross-compilation and validation commands for nix-config
# Usage: just <command>

# Show available commands
help:
    @echo "Available commands:"
    @echo "  check-darwin    - Validate nix-darwin configuration (fast)"
    @echo "  build-darwin    - Cross-compile full nix-darwin configuration"
    @echo "  build-linux     - Build NixOS VM"
    @echo "  dev             - Enter development shell"
    @echo "  check           - Check flake syntax"
    @echo "  clean           - Clean build results"
    @echo "  test            - Run cross-compilation tests"
    @echo "  format          - Format Nix files"

# Validate nix-darwin configuration
check-darwin:
    nix build .#turbine-check

# Cross-compile nix-darwin configuration from Linux
build-darwin:
    nix build .#turbine-darwin

# Build NixOS VM
build-linux:
    nix build .#powerhouse-vm

# Enter development shell
dev:
    nix develop

# Check flake syntax
check:
    nix flake check

# Clean build results
clean:
    rm -rf result*

# Run cross-compilation tests
test:
    ./test-cross-compilation.sh

# Format Nix files
format:
    nix develop -c alejandra .