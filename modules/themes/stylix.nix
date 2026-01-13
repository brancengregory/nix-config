{
  pkgs,
  inputs,
  ...
}: {
  stylix = {
    enable = true;
    # Disable autoEnable to prevent it from touching KDE/Plasma 
    # which we've seen causes black screens in Plasma 6.
    autoEnable = false;
    enableReleaseChecks = false;

    # Using a high-quality NixOS wallpaper
    image = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-dracula.png";
      sha256 = "07ly21bhs6cgfl7pv4xlqzdqm44h22frwfhdqyd4gkn2jla1waab";
    };

    # Using Tokyo Night
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

    cursor = {
      package = pkgs.kdePackages.breeze;
      name = "Breeze_Snow";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sizes = {
        applications = 12;
        terminal = 14;
        desktop = 10;
        popups = 10;
      };
    };

    # Set transparency for certain apps
    opacity = {
      applications = 1.0;
      terminal = 0.95;
      desktop = 1.0;
      popups = 1.0;
    };

    polarity = "dark";

    # Selectively enable targets that are safe and desired
    targets = {
      console.enable = true;
      gnome.enable = false;
      gtk.enable = true;
    };
  };
}