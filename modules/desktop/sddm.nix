{pkgs, ...}: {
  # Enable SDDM display manager
  services.displayManager.sddm = {
    enable = true;
    # You can choose a theme here, e.g., "sugar-dark" or "maldives"
    # theme = "sugar-dark";
    # Set the default session to Hyprland
    # This assumes Hyprland is correctly set up as a session.
    # Home Manager's programs.hyprland.enable usually handles session registration.
    wayland.enable = true; # Crucial for Wayland compositors like Hyprland
    # You might need to explicitly set the session if auto-detection fails, e.g.:
    # defaultSession = "hyprland"; # Or the name of your Hyprland desktop entry
  };
}
