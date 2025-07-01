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
    # Note: Many packages have been migrated to nixpkgs in hosts/turbine/packages.nix
    # Keep here only packages that:
    # 1. Don't work well in nixpkgs on macOS
    # 2. Have better macOS-specific integrations via homebrew
    # 3. Are unstable or experimental in nixpkgs
    casks = [
      # Development tools
      "visual-studio-code" # Better macOS integration than nixpkgs version
      "arduino-ide" # Hardware-specific tool, better via homebrew
      "android-platform-tools" # Android development, better via homebrew
      "github" # GitHub Desktop has macOS-specific features
      "podman-desktop" # Container management GUI, better via homebrew
      "postman" # API testing, proprietary, better via homebrew
      "dbeaver-community" # Database tool, Java-based, better via homebrew
      "db-browser-for-sqlite" # Specialized tool, better via homebrew
      "ngrok" # Commercial tool, better via homebrew
      "xquartz" # X11 for macOS, required via homebrew

      # Browsers
      # firefox moved to nixpkgs - stable and cross-platform
      "firefox@developer-edition" # Special version, keep in homebrew
      "google-chrome" # Proprietary, better via homebrew
      "brave-browser" # Chromium-based, better macOS integration via homebrew
      "tor-browser" # Security-focused, better to use official builds

      # Communication
      "slack" # Proprietary, better macOS integration via homebrew
      "discord" # Communication platform, keeping in homebrew for macOS compatibility
      "telegram" # Messaging, keeping in homebrew for macOS compatibility
      "messenger" # Meta proprietary app, homebrew only
      "microsoft-teams" # Microsoft proprietary, better via homebrew
      "signal" # Secure messaging, keeping in homebrew for macOS compatibility
      "twitch" # Gaming platform, better via homebrew

      # Text editors and IDEs
      "zed" # Modern editor with frequent updates, better via homebrew
      "ghostty" # New terminal, keep in homebrew for stability
      "kitty" # Terminal emulator, may work better via homebrew on macOS
      "iterm2" # macOS-specific terminal, homebrew only

      # Productivity and utilities
      "notion" # Proprietary productivity app, homebrew only
      "obsidian" # Note-taking, proprietary, better via homebrew
      "toggl-track" # Time tracking, proprietary, homebrew only
      "zotero" # Research tool, may have better integration via homebrew
      "activitywatch" # Activity tracking, specialized tool
      "tunnelblick" # VPN client for macOS, homebrew only
      "balenaetcher" # Hardware flashing tool, specialized

      # Media and entertainment
      "vlc" # Media player, not available on macOS via nixpkgs
      "obs" # Streaming/recording, keeping in homebrew for macOS compatibility
      "webtorrent" # BitTorrent client, specialized
      "steam" # Gaming platform, proprietary, better via homebrew
      "minecraft" # Gaming, proprietary, homebrew only
      "epic-games" # Gaming platform, proprietary, homebrew only
      "openemu" # macOS-specific emulator, homebrew only

      # Science and research
      "qgis" # GIS software, complex dependencies, better via homebrew
      "positron" # IDE, specialized, keep in homebrew
      "rstudio" # R IDE, better macOS integration via homebrew
      "miniconda" # Python distribution, better via homebrew for macOS
      "julia" # Programming language, may be better via homebrew
      "google-earth-pro" # Proprietary Google app, homebrew only
      "kiwix" # Offline wikipedia, specialized tool

      # Creative tools
      "blender" # 3D creation suite, keeping in homebrew for macOS compatibility
      "bitwig-studio" # Commercial DAW, proprietary, homebrew only
      "godot" # Game engine, keeping in homebrew for macOS compatibility
      "tic80" # Fantasy console, specialized tool

      # System tools and utilities
      "syncthing" # File sync, keeping in homebrew for macOS compatibility
      "virtualbox" # Virtualization, requires kernel extensions, better via homebrew
      "parsec" # Remote desktop, proprietary, homebrew only
      "libreoffice" # Office suite, not available on macOS via nixpkgs
      "pgadmin4" # PostgreSQL admin, web-based, may be better via homebrew
      "mactex" # LaTeX for macOS, large specialized distribution
      "google-cloud-sdk" # Google Cloud tools, better via homebrew

      # Fonts
      "font-fira-code-nerd-font"
      "font-roboto-mono"
      "font-lato"
      "font-fanwood-text"
      "font-league-spartan"

      # Java runtime environments
      "temurin@8" # Specific Java version, better via homebrew
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
