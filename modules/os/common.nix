{pkgs, ...}: {
  # --- Nix Features ---
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
