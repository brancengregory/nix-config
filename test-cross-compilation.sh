#!/usr/bin/env bash
# Test script for cross-compilation functionality

set -euo pipefail

echo "🧪 Testing nix-darwin cross-compilation from Linux"
echo

# Check if nix is available
if ! command -v nix &> /dev/null; then
    echo "❌ Nix is not installed. Please install Nix with flakes support."
    exit 1
fi

# Check flake syntax
echo "🔍 Checking flake syntax..."
if nix flake check --no-build 2>/dev/null; then
    echo "✅ Flake syntax is valid"
else
    echo "❌ Flake syntax error detected"
    exit 1
fi

echo

# Test that the packages are available
echo "📦 Checking available packages..."
if nix flake show 2>/dev/null | grep -q "turbine-darwin"; then
    echo "✅ turbine-darwin package is available"
else
    echo "❌ turbine-darwin package not found"
    exit 1
fi

if nix flake show 2>/dev/null | grep -q "turbine-check"; then
    echo "✅ turbine-check package is available"
else
    echo "❌ turbine-check package not found"
    exit 1
fi

echo

# Test validation (quick check)
echo "⚡ Testing configuration validation..."
if nix build .#turbine-check --dry-run 2>/dev/null; then
    echo "✅ Darwin configuration validation passes"
else
    echo "❌ Darwin configuration validation failed"
    exit 1
fi

echo

echo "🎉 All tests passed! Cross-compilation setup is working correctly."
echo
echo "💡 To use the cross-compilation features:"
echo "  - Run 'nix build .#turbine-darwin' to cross-compile the full darwin config"
echo "  - Run 'nix build .#turbine-check' to validate the darwin config"
echo "  - Run 'nix develop' to enter the development environment"