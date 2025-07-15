{pkgs, ...}: {
  home.packages = with pkgs; [
    hyprland
    waybar
    rofi
    # kitty
    # swaybg
    # grim
    # slurp
  ];

  # Hyprland window manager configuration
  programs.hyprland = {
    enable = true;
    # Nvidia stuff here or in modules
    # enable NvidiaPatches = true;
    xwayland.enable = true;
    extraConfig = ''
      # monitor=,preferred,auto,1
      # exec-once = waybar
    '';
  };
}
