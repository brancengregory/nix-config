{pkgs, inputs, ...}: {
  imports = [
    ../../modules/fonts/default.nix
    ../../modules/desktop/plasma-home.nix
    ../../modules/terminal/zsh.nix
    ../../modules/terminal/starship.nix
    ../../modules/terminal/tmux.nix
    ../../modules/terminal/nvim.nix
    ../../modules/security/gpg.nix
    ../../modules/security/ssh.nix
    ../../modules/security/gpg-agent.nix
    ../../modules/network/wireguard.nix
    ../../modules/programs/git.nix
  ];

  programs.home-manager.enable = true;

  home.username = "brancengregory";
  home.homeDirectory =
    if pkgs.stdenv.isLinux
    then "/home/brancengregory"
    else if pkgs.stdenv.isDarwin
    then "/Users/brancengregory"
    else throw "Unsupported OS for this home-manager configuration";

  # Prefer nixpkgs packages over Homebrew when possible
  # GUI applications should be managed via Homebrew casks in darwin.nix
  # CLI tools should generally be managed here via nixpkgs
  home.packages = with pkgs;
    [
      age
      alejandra
      bat
      delta
      eza
      fd
      ghostty
      glow
      gnupg
      htop
      hwatch
      jaq
      jnv
      just
      libpq # Move elsewhere?
      lazygit
      # lazysql maybe
      nh
      nmap
      inputs.plasma-manager.packages.${pkgs.system}.rc2nix
      # ollama maybe
      # opencode maybe
      openssh
      procs
      yazi
      duckdb
      postgresql
      sqlite
      arrow-cpp
      (rWrapper.override {
        packages = with rPackages; [
          cli
          devtools
          dplyr
          fs
          ggplot2
          glue
          lubridate
          tibble
          readr
          renv
          rix
          rlang
          scales
          stringr
          targets
          usethis
          readxl
          janitor
          tidymodels
          # Database packages
          DBI
          RPostgres
          RSQLite
          duckdb
          arrow
          # Production and Parallelism
          crew
          mirai
          plumber
          httr2
          shiny
          bslib
          ojodb
        ];
      })
      pkgs.radian
      ripgrep
      scc
      sesh
      sshs
      tealdeer
      google-cloud-sdk
    ]
    ++ (
      if pkgs.stdenv.isLinux
      then [
        # Linux specific packages
        pinentry-curses
        sudo
        google-chrome
        slack
        positron-bin
        rustup
        snapper-gui
        keymapp
      ]
      else if pkgs.stdenv.isDarwin
      then [
        # Mac specific packages
        pinentry-curses
        # mas-cli maybe
      ]
      else throw "Unsupported OS for this home-manager configuration"
    );

  home.stateVersion = "25.05";

  # Streamlined GPG configuration with essential security settings
  programs.gpg = {
    enable = true;

    # Essential GPG configuration - optimized for performance and security
    settings = {
      # Modern algorithms (essential only)
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      cipher-algo = "AES256";
      digest-algo = "SHA512";
      cert-digest-algo = "SHA512";

      # Disable weak algorithms
      disable-cipher-algo = "3DES";
      weak-digest = "SHA1";

      # Essential display and behavior options
      keyid-format = "0xlong";
      with-fingerprint = true;
      use-agent = true;

      # Keyserver settings
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "no-honor-keyserver-url";
    };
  };

  # Streamlined SSH configuration with balanced security
  programs.ssh = {
    enable = true;

    # Security-focused SSH client configuration
    extraConfig = ''
      # Core security settings
      Protocol 2
      PasswordAuthentication no
      ChallengeResponseAuthentication no
      StrictHostKeyChecking ask
      HashKnownHosts yes
      ForwardAgent no
      ForwardX11 no
      ServerAliveInterval 300
      ServerAliveCountMax 2

      # Modern cryptography (essential algorithms only)
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
      KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512
      HostKeyAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512
      PubkeyAcceptedKeyTypes ssh-ed25519,rsa-sha2-256,rsa-sha2-512
    '';

    # Common host configurations
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identitiesOnly = true;
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      # Template for personal servers
      "*.local" = {
        user = "brancengregory";
        identitiesOnly = true;
      };
    };
  };

  # Optimized GPG Agent configuration
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableScDaemon = true;

    # Platform-optimized pinentry with fallback to curses
    pinentryPackage =
      if pkgs.stdenv.isLinux
      then pkgs.pinentry-curses # Terminal-based for consistency
      else pkgs.pinentry-curses; # curses works well on macOS too

    # Optimized cache settings
    defaultCacheTtl = 28800; # 8 hours
    defaultCacheTtlSsh = 28800; # 8 hours
    maxCacheTtl = 86400; # 24 hours
    maxCacheTtlSsh = 86400; # 24 hours

    # Streamlined agent configuration
    extraConfig = ''
      allow-preset-passphrase
      allow-loopback-pinentry

      # Basic passphrase constraints
      min-passphrase-len 12
      min-passphrase-nonalpha 2
    '';
  };
}
