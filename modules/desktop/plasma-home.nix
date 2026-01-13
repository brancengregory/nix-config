{
  pkgs,
  lib,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  programs.plasma = {
    enable = true;

    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      theme = "breeze-dark";
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

    kwin.virtualDesktops = {
      number = 1;
    };

    powerdevil = {
      AC = {
        dimDisplay.idleTimeout = 300; # 5 minutes
        turnOffDisplay.idleTimeout = 2700; # 45 minutes
      };
    };

    # Set the panel and widgets using high-level plasma-manager API
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
                use24hFormat = "12h"; # Based on common plasma-manager patterns
              };
            };
          }
        ];
      }
    ];

    # Keep only things that don't have high-level options yet
    configFile = {
      baloofilerc.General.dbVersion = 2;
      baloofilerc.General."exclude filters version" = 9;
      kactivitymanagerdrc.activities.d9f05ec3-85fe-4fbc-937e-eebdad2df53d = "Default";
      kactivitymanagerdrc.main.currentActivity = "d9f05ec3-85fe-4fbc-937e-eebdad2df53d";
      kded5rc.Module-device_automounter.autoload = false;
      # Manually disable translucency to ensure opaque menu
      kwinrc.Plugins.translucencyEnabled = false;
    };
  };
}