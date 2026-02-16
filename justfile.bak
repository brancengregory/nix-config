# Cross-compilation and validation commands for nix-config
# Usage: just <command>

# Show available commands
help:
    @echo "Available commands:"
    @echo "  check-darwin    - Validate nix-darwin config (fast)"
    @echo "  build-darwin    - Cross-compile full nix-darwin config"
    @echo "  build-linux     - Build NixOS VM"
    @echo "  dev             - Enter development shell"
    @echo "  check           - Check flake syntax"
    @echo "  clean           - Clean build results"
    @echo "  format          - Format Nix files"
    @echo "  test            - Run all validation tests"
    @echo "  docs-init       - Initialize mdBook documentation"
    @echo "  docs-build      - Build documentation site"
    @echo "  docs-serve      - Serve documentation locally"
    @echo "  docs-clean      - Clean documentation build"

# Validate nix-darwin config
check-darwin:
    nix build .#turbine-check

# Cross-compile nix-darwin config from Linux
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

# Format Nix files
format:
    nix develop -c alejandra .

# Run all validation tests
test:
    just check
    just check-darwin

# Initialize mdBook documentation
docs-init:
    nix develop -c mdbook init --theme docs

# Build documentation site
docs-build:
    nix develop -c mdbook build

# Serve documentation locally
docs-serve:
    nix develop -c mdbook serve --open

# Clean documentation build
docs-clean:
    rm -rf docs/book
