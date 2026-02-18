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
      "anomalyco/tap/opencode" # OpenCode AI coding agent (flake doesn't support x86_64-darwin)
    ];

    # GUI applications (casks) - FINAL PRUNED LIST
    # R, RStudio, Positron managed by nixpkgs (rWrapper)
    casks = [
      # Development tools
      "visual-studio-code"
      "dbeaver-community"
      "podman-desktop"
      
      # Communication (all requested)
      "slack"
      "discord"
      "telegram"
      "messenger"
      "microsoft-teams"
      "signal"
      "twitch"
      "zoom"
      
      # Productivity/Media
      "zotero"
      "activitywatch"
      "vlc"
      "obs"
      
      # Gaming
      "steam"
      "minecraft"
      "epic-games"
      
      # System
      "syncthing"
      "libreoffice"
      
      # Browsers (Chrome only as requested)
      "google-chrome"
      
      # Fonts
      "font-fira-code-nerd-font"
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

  # Ensure nix-daemon is running
  nix.package = pkgs.nix;

  # Define the user account for nix-darwin
  users.users.brancengregory = {
    home = "/Users/brancengregory";
  };
}
