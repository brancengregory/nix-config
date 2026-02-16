# Contributing

This page outlines how to contribute to the Nix configuration and documentation.

## Development Environment

1. Install Nix with flakes enabled
2. Clone the repository
3. Enter the development environment:

```bash
mise dev
# or: nix develop
```

## Making Changes

### Configuration Changes

1. Make your changes to the appropriate files in `hosts/`, `modules/`, or `users/`
2. Test your changes:
   ```bash
   mise check-darwin  # for nix-darwin configs
   mise build-powerhouse  # for NixOS configs
   ```
3. Format your code:
   ```bash
   mise format
   ```

### Documentation Changes

1. Edit the markdown files in the `docs/` directory
2. Build and preview the documentation:
   ```bash
   mise docs-build
   mise docs-serve
   ```
3. The documentation site will be automatically deployed when changes are merged to main

## Available Commands

Run `mise help` to see all available development commands.