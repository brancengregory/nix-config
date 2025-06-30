#!/usr/bin/env bash
# Validation script for Copilot agent environment setup
# This script validates that the environment has all necessary tools for development

set -euo pipefail

echo "🔍 Validating GitHub Copilot agent environment setup..."
echo

# Check if we're in the right directory
if [[ ! -f flake.nix ]]; then
    echo "❌ Not in a Nix flake directory (flake.nix not found)"
    exit 1
fi

echo "✅ Found flake.nix - this is a Nix flake project"

# Check if justfile exists
if [[ -f justfile ]]; then
    echo "✅ Found justfile - just commands are available"
else
    echo "⚠️  No justfile found"
fi

# Check if copilot-agent.yml exists
if [[ -f .github/copilot-agent.yml ]]; then
    echo "✅ Found .github/copilot-agent.yml - Copilot agent configuration is present"
else
    echo "❌ Missing .github/copilot-agent.yml configuration"
    exit 1
fi

# Check if GitHub Actions workflow exists
if [[ -f .github/workflows/setup-nix-env.yml ]]; then
    echo "✅ Found .github/workflows/setup-nix-env.yml - GitHub Actions setup workflow is present"
else
    echo "❌ Missing .github/workflows/setup-nix-env.yml workflow"
    exit 1
fi

# Validate YAML syntax of copilot-agent.yml (basic check)
if command -v python3 &> /dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('.github/copilot-agent.yml'))" 2>/dev/null; then
        echo "✅ copilot-agent.yml has valid YAML syntax"
    else
        echo "❌ copilot-agent.yml has invalid YAML syntax"
        exit 1
    fi
    
    # Validate GitHub Actions workflow YAML syntax
    if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/setup-nix-env.yml'))" 2>/dev/null; then
        echo "✅ setup-nix-env.yml has valid YAML syntax"
    else
        echo "❌ setup-nix-env.yml has invalid YAML syntax"
        exit 1
    fi
else
    echo "⚠️  Cannot validate YAML syntax (python3 not available)"
fi

# Check for essential development files
essential_files=(
    "flake.nix"
    "flake.lock" 
    "justfile"
    ".github/copilot-agent.yml"
    ".github/workflows/setup-nix-env.yml"
)

missing_files=()
for file in "${essential_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -eq 0 ]]; then
    echo "✅ All essential files are present"
else
    echo "❌ Missing essential files: ${missing_files[*]}"
    exit 1
fi

# Check if Nix is available (optional since Copilot agent will install it)
if command -v nix &> /dev/null; then
    echo "✅ Nix is available: $(nix --version | head -1)"
    
    # If Nix is available, test key commands
    echo "🧪 Testing key Nix commands..."
    
    if nix flake check --no-build 2>/dev/null; then
        echo "✅ nix flake check passed"
    else
        echo "❌ nix flake check failed"
        exit 1
    fi
    
else
    echo "⚠️  Nix not currently available (will be installed by Copilot agent)"
fi

# Check if just is available (optional since it's in the dev shell)
if command -v just &> /dev/null; then
    echo "✅ just is available: $(just --version)"
else
    echo "⚠️  just not currently available (provided in Nix dev shell)"
fi

echo
echo "🎉 Copilot agent environment validation completed successfully!"
echo "💡 The environment uses GitHub Actions for reliable setup:"
echo "  - DeterminateSystems/nix-installer-action@main for fast, reliable Nix installation"
echo "  - DeterminateSystems/magic-nix-cache-action@main for automatic binary caching"
echo "  - Automatic flakes support and configuration"
echo "  - Works around firewall restrictions"
echo
echo "🚀 Key commands available to the Copilot agent:"
echo "  - nix flake check"
echo "  - just help"
echo "  - just check-darwin"
echo "  - just build-darwin" 
echo "  - just format"
echo "  - just test"
echo
echo "🔧 Setup workflow: gh workflow run setup-nix-env.yml"