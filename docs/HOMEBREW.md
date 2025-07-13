# Homebrew Integration

This nix-darwin configuration includes Homebrew support for managing Mac applications. Here's how to use it:

## Philosophy

- **Prefer nixpkgs**: Use packages from nixpkgs whenever possible (managed in `users/brancengregory/home.nix`)
- **Use Homebrew for GUI apps**: GUI applications and Mac-specific software that aren't available or don't work well in nixpkgs
- **Minimal Homebrew usage**: Only use Homebrew when nixpkgs isn't sufficient

## Configuration Files

- **`modules/os/darwin.nix`**: Contains Homebrew configuration (casks, brews, taps, masApps)
- **`users/brancengregory/home.nix`**: Contains nixpkgs packages (CLI tools, fonts, etc.)

## Adding Applications

### GUI Applications (Recommended for Homebrew)
Edit `modules/os/darwin.nix` and add applications to the `casks` list:

```nix
casks = [
  "visual-studio-code"
  "docker"
  "slack"
  "1password"
];
```

### CLI Tools (Recommended for nixpkgs)
Edit `users/brancengregory/home.nix` and add packages to the `home.packages` list:

```nix
home.packages = with pkgs; [
  git
  neovim
  bat
  # ... other packages
];
```

### When to Use Homebrew for CLI Tools
Only use Homebrew `brews` for CLI tools that:
- Aren't available in nixpkgs
- Don't work properly when installed via nixpkgs
- Require system integration that nixpkgs can't provide

## Mac App Store Apps
For apps from the Mac App Store, add them to `masApps` with their app ID:

```nix
masApps = {
  "Xcode" = 497799835;
  "Pages" = 409201541;
};
```

## Migration from Existing Homebrew

If you already have Homebrew installations:

1. **Inventory existing apps**: Run `brew list` and `brew list --cask`
2. **Add to nix-darwin**: Add the applications you want to keep to the appropriate lists
3. **Apply configuration**: Run `darwin-rebuild switch --flake .#turbine`
4. **Cleanup**: The `cleanup = "zap"` setting will remove unmanaged packages

## Applying Changes

After modifying the configuration:

```bash
darwin-rebuild switch --flake .#turbine
```

This will:
- Install new packages/casks
- Remove packages not in the configuration (due to `cleanup = "zap"`)
- Update existing packages (due to `upgrade = true`)
