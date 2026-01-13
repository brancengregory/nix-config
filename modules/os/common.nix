{pkgs, ...}: {
  # --- Nix Features ---
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # --- System-wide Applications ---
  environment.systemPackages = with pkgs; [
    google-chrome
  ];

  # --- Default Browser ---
  environment.variables = {
    BROWSER = "google-chrome";
  };
}
