{pkgs, ...}: {
  nix.enable = true;

  # Enable Linux builder for cross-compilation and Linux package building
  nix.linux-builder.enable = true;

  system = {
    # Set the primary user for user-specific system settings
    primaryUser = "brancengregory";

    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        ApplePressAndHoldEnabled = true;
        AppleScrollerPagingBehavior = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        AppleShowScrollBars = "WhenScrolling";
        # InitialKeyRepeat = ; # Add value
        # KeyRepeat = ; # Add value
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSDisableAutomaticTermination = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        _HIHideMenuBar = true;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.swipescrolldirection" = false;
        # "com.apple.trackpad.scaling" = ; # Add value
      };
      controlcenter = {
        AirDrop = false;
        BatteryShowPercentage = true;
        Bluetooth = true;
        Display = true;
        FocusModes = true;
        NowPlaying = true;
        Sound = true;
      };
      dock = {
        appswitcher-all-displays = true;
        autohide = true;
        persistent-others = [
          "~/Downloads"
        ];
        show-recents = false;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        NewWindowTarget = "Home";
        ShowHardDrivesOnDesktop = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };
      loginwindow = {
        GuestEnabled = false;
      };
      menuExtraClock = {
        ShowAMPM = true;
        ShowDate = 1;
      };
      screencapture = {
        location = "~/Downloads";
      };
    };
  };

  # Homebrew configuration - let nix-darwin manage Homebrew
  homebrew = {
    enable = true;

    # Automatically cleanup unreferenced formulae and casks
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    # Homebrew taps (additional repositories)
    taps = [
      "homebrew/services"
    ];

    # CLI packages from Homebrew (use sparingly, prefer nixpkgs)
    brews = [
      # Add CLI tools that aren't available or don't work well in nixpkgs
      "mas" # Mac App Store CLI
    ];

    # GUI applications (casks) - this is Homebrew's strength
    casks = [
      # Development tools
      "visual-studio-code"
      "arduino-ide"
      "android-platform-tools"
      "github"
      "podman-desktop"
      "postman"
      "dbeaver-community"
      "db-browser-for-sqlite"
      "ngrok"
      "xquartz"

      # Browsers
      "firefox"
      "firefox@developer-edition"
      "google-chrome"
      "brave-browser"
      "tor-browser"

      # Communication
      "slack"
      "discord"
      "telegram"
      "messenger"
      "microsoft-teams"
      "signal"
      "twitch"

      # Text editors and IDEs
      "zed"
      "ghostty"
      "kitty"
      "iterm2"

      # Productivity and utilities
      "notion"
      "obsidian"
      "toggl-track"
      "zotero"
      "activitywatch"
      "tunnelblick"
      "balenaetcher"

      # Media and entertainment
      "vlc"
      "obs"
      "webtorrent"
      "steam"
      "minecraft"
      "epic-games"
      "openemu"

      # Science and research
      "qgis"
      "positron"
      "r"
      "rstudio"
      "miniconda"
      "julia"
      "google-earth-pro"
      "kiwix" # Offline wikipedia

      # Creative tools
      "blender"
      "bitwig-studio"
      "godot"
      "tic80"

      # System tools and utilities
      "syncthing"
      "virtualbox"
      "parsec"
      "libreoffice"
      "pgadmin4"
      "mactex"
      "google-cloud-sdk"

      # Fonts
      "font-fira-code-nerd-font"
      "font-roboto-mono"
      "font-lato"
      "font-fanwood-text"
      "font-league-spartan"

      # Java runtime environments
      "temurin@8"
    ];

    # Mac App Store apps (requires mas CLI)
    masApps = {
      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Magnet" = 441258766;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Toggl Track" = 1291898086;
      "WireGuard" = 1451685025;
    };
  };

  environment.shellAliases = {
    ports = "netstat -anv | grep -E 'LISTEN|Proto'";
  };

  # Ensure nix-daemon is running
  nix.package = pkgs.nix;

  # Define the user account for nix-darwin
  users.users.brancengregory = {
    home = "/Users/brancengregory";
  };
}
