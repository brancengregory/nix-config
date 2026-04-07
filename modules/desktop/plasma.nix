{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.desktop.plasma;
in {
  options.desktop.plasma = {
    enable = mkEnableOption "KDE Plasma 6 desktop environment with plasma-manager";

    lookAndFeel = mkOption {
      type = types.str;
      default = "org.kde.breezedark.desktop";
      description = "Plasma look and feel theme";
    };

    virtualDesktops = mkOption {
      type = types.int;
      default = 1;
      description = "Number of virtual desktops";
    };

    scale = mkOption {
      type = types.float;
      default = 1.0;
      description = "Display scaling factor for HiDPI screens";
    };
  };

  config = mkIf cfg.enable {
    # Enable the KDE Plasma 6 Desktop Environment
    services.desktopManager.plasma6.enable = true;

    # Enable KDE Connect (handles firewall automatically)
    programs.kdeconnect.enable = true;

    # Install Firefox and basic KDE tools
    environment.systemPackages = with pkgs; [
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.gwenview
      kdePackages.spectacle
      darktable
      obs-studio
      libreoffice-qt6-fresh
      firefox
    ];

    # Configure plasma-manager for all users via sharedModules
    home-manager.sharedModules = [
      inputs.plasma-manager.homeModules.plasma-manager
      {
        programs.plasma = {
          enable = true;

          workspace = {
            inherit (cfg) lookAndFeel;
            theme = "default";
            colorScheme = "BreezeDark";
            iconTheme = "breeze-dark";
            cursor = {
              theme = "Breeze_Snow";
              size = 24;
            };
          };

          input.keyboard = {
            repeatDelay = 250;
            repeatRate = 50;
          };

          kwin = {
            virtualDesktops.number = cfg.virtualDesktops;
            effects = {
              blur.enable = false;
              translucency.enable = false;
            };
          };

          powerdevil = {
            AC = {
              dimDisplay.idleTimeout = 300; # 5 minutes
              turnOffDisplay.idleTimeout = 2700; # 45 minutes
            };
          };

          panels = [
            {
              location = "bottom";
              height = 44;
              floating = false;
              opacity = "opaque";
              widgets = [
                "org.kde.plasma.kickoff"
                "org.kde.plasma.pager"
                {
                  name = "org.kde.plasma.icontasks";
                  config = {
                    General = {
                      launchers = [
                        "applications:systemsettings.desktop"
                        "applications:org.kde.dolphin.desktop"
                        "applications:google-chrome.desktop"
                        "applications:com.mitchellh.ghostty.desktop"
                      ];
                    };
                  };
                }
                "org.kde.plasma.marginsseparator"
                "org.kde.plasma.systemtray"
                {
                  name = "org.kde.plasma.digitalclock";
                  config = {
                    Appearance = {
                      showDate = true;
                      use24hFormat = "12h";
                    };
                  };
                }
              ];
            }
          ];

          configFile = {
            baloofilerc.General.dbVersion = 2;
            baloofilerc.General."exclude filters version" = 9;
            kactivitymanagerdrc.activities.d9f05ec3-85fe-4fbc-937e-eebdad2df53d = "Default";
            kactivitymanagerdrc.main.currentActivity = "d9f05ec3-85fe-4fbc-937e-eebdad2df53d";
            kded5rc.Module-device_automounter.autoload = false;
            kwinrc.Plugins = {
              blurEnabled = false;
              translucencyEnabled = false;
              backgroundcontrastEnabled = false;
            };
            kdeglobals.KScreen.ScaleFactor = cfg.scale;
            kwinrc.Xwayland.Scale = cfg.scale;
          };
        };
      }
    ];
  };
}
