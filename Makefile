# Cross-compilation and validation commands for nix-config
# Usage: just <command> or make <command>

.PHONY: help check build-darwin check-darwin build-linux dev clean

help: ## Show this help
	@echo "Available commands:"
	@echo "  check-darwin    - Validate nix-darwin configuration (fast)"
	@echo "  build-darwin    - Cross-compile full nix-darwin configuration"
	@echo "  build-linux     - Build NixOS VM"
	@echo "  dev             - Enter development shell"
	@echo "  check           - Check flake syntax"
	@echo "  clean           - Clean build results"
	@echo "  test            - Run cross-compilation tests"

check-darwin: ## Validate nix-darwin configuration
	nix build .#turbine-check

build-darwin: ## Cross-compile nix-darwin configuration from Linux
	nix build .#turbine-darwin

build-linux: ## Build NixOS VM
	nix build .#powerhouse-vm

dev: ## Enter development shell
	nix develop

check: ## Check flake syntax
	nix flake check

clean: ## Clean build results
	rm -rf result*

test: ## Run cross-compilation tests
	./test-cross-compilation.sh

format: ## Format Nix files
	nix develop -c alejandra .