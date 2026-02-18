{ lib, ... }:
{
  imports = [
    ./plasma.nix
    ./sddm.nix
    # ./hyprland.nix  # System-level Hyprland session config if needed
    # ./gnome.nix     # Easy to add later
  ];
}
