{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.themes.stylix;
in {
  options.themes.stylix = {
    enable = mkEnableOption "Stylix unified theming system";

    image = mkOption {
      type = types.path;
      description = "Wallpaper image path or derivation";
      default = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-dracula.png";
        sha256 = "07ly21bhs6cgfl7pv4xlqzdqm44h22frwfhdqyd4gkn2jla1waab";
      };
    };

    base16Scheme = mkOption {
      type = types.path;
      description = "Base16 color scheme file";
      default = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
    };

    autoEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically enable Stylix targets (can cause issues with Plasma)";
    };
  };

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      inherit (cfg) image base16Scheme autoEnable;
      enableReleaseChecks = false;

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

      opacity = {
        applications = 1.0;
        terminal = 0.95;
        desktop = 1.0;
        popups = 1.0;
      };

      polarity = "dark";
    };
  };
}
