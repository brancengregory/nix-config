{
  pkgs,
  inputs,
  config,
  lib,
  isDesktop,
  ...
}: {
  imports = [
    ../../modules/home/fonts.nix
    ../../modules/home/gpg.nix
    ../../modules/home/ssh.nix
    ../../modules/home/terminal/zsh.nix
    ../../modules/home/terminal/starship.nix
    ../../modules/home/terminal/tmux.nix
    ../../modules/home/programs/atuin.nix
    ../../modules/home/programs/nixvim
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/r.nix
    ../../modules/home/programs/direnv.nix
    ../../modules/home/programs/ghostty.nix
    ../../modules/home/programs/sesh.nix
    ../../modules/home/programs/opencode.nix
    inputs.sops-nix.homeManagerModules.sops
    # NOTE: plasma-manager is now imported at system level via desktop.plasma module
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      ssh_authorized_key = {
        path = "${config.home.homeDirectory}/.ssh/authorized_keys";
        mode = "0600";
      };

      # Database credentials
      pgpass = {
        path = "${config.home.homeDirectory}/.pgpass";
        mode = "0600";
      };

      # R environment variables
      renviron = {
        path = "${config.home.homeDirectory}/.Renviron";
      };

      # Shell secrets (sourced by zsh)
      zsh_env = {
        path = "${config.xdg.configHome}/zsh/secrets.zsh";
      };
    };
  };

  programs.home-manager.enable = true;

  home.username = "brancengregory";
  home.homeDirectory = "/home/brancengregory";

  # Base packages for all hosts
  home.packages =
    (with pkgs; [
      age
      alejandra
      bat
      delta
      devenv
      eza
      fd
      glow
      gnupg
      htop
      hwatch
      jaq
      jnv
      just
      ollama
      libpq
      lazygit
      nh
      nmap
      sops
      ssh-to-age
      openssh
      procs
      yazi
      duckdb
      postgresql
      sqlite
      arrow-cpp
      ripgrep
      scc
      sesh
      sshs
      tealdeer
      google-cloud-sdk

      # Linux-specific packages (always included since we only use NixOS)
      pinentry-curses
      sudo
      rsync
      restic
    ])
    # Desktop-specific packages
    ++ lib.optionals isDesktop (with pkgs; [
      ghostty
      slack
      discord
      zoom-us
      positron-bin
      rstudio
      rustup
      snapper-gui
      keymapp
      wl-clipboard
    ]);

  xdg.mimeApps = lib.mkIf isDesktop {
    enable = true;
    defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
    };
  };

  home.stateVersion = "25.11";

  # OpenCode AI coding agent with declarative config
  programs.opencode-config.enable = true;
}
