{
  pkgs,
  inputs,
  config,
  lib,
  isLinux,
  isDarwin,
  isDesktop,
  ...
}: {
  imports =
    [
      ../../modules/home/fonts.nix
      ../../modules/home/gpg.nix
      ../../modules/home/ssh.nix
      ../../modules/home/terminal/zsh.nix
      ../../modules/home/terminal/starship.nix
      ../../modules/home/terminal/tmux.nix
      ../../modules/home/programs/nixvim.nix
      ../../modules/home/programs/git.nix
      ../../modules/home/programs/r.nix
      ../../modules/home/programs/ghostty.nix
      ../../modules/home/programs/sesh.nix
      ../../modules/home/programs/opencode.nix
      inputs.sops-nix.homeManagerModules.sops
    ]
    ++ (lib.optionals (isLinux && isDesktop) [
      ../../modules/home/desktop/plasma.nix
    ]);

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile =
      if isLinux
      then "/home/brancengregory/.config/sops/age/keys.txt"
      else "/Users/brancengregory/.config/sops/age/keys.txt";

    secrets = {
      # Database credentials
      pgpass = {
        path = "${config.home.homeDirectory}/.pgpass";
        mode = "0600";
      };

      # R environment variables
      renviron = {};

      # Shell secrets (sourced by zsh)
      zsh_env = {
        path = "${config.xdg.configHome}/zsh/secrets.zsh";
      };
    };
  };

  programs.home-manager.enable = true;

  home.username = "brancengregory";
  home.homeDirectory =
    if pkgs.stdenv.isLinux
    then "/home/brancengregory"
    else if pkgs.stdenv.isDarwin
    then "/Users/brancengregory"
    else throw "Unsupported OS for this home-manager configuration";

  # Base packages for all hosts
  home.packages =
    (
      with pkgs; [
        age
        alejandra
        bat
        delta
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
      ]
    )
    # Linux-specific packages
    ++ (with pkgs;
      lib.optionals isLinux [
        pinentry-curses
        sudo
        rsync
        restic
      ])
    # Desktop-specific packages (Linux only)
    ++ (with pkgs;
      lib.optionals (isLinux && isDesktop) [
        inputs.plasma-manager.packages.${pkgs.stdenv.hostPlatform.system}.rc2nix
        ghostty
        slack
        discord
        zoom-us
        positron-bin
        rstudio
        rustup
        snapper-gui
        keymapp
      ])
    # macOS-specific packages
    ++ (with pkgs;
      lib.optionals isDarwin [
        pinentry-tty
      ]);

  xdg.mimeApps =
    if (isLinux && isDesktop)
    then {
      enable = true;
      defaultApplications = {
        "text/html" = "google-chrome.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-scheme-handler/about" = "google-chrome.desktop";
        "x-scheme-handler/unknown" = "google-chrome.desktop";
      };
    }
    else {};

  home.stateVersion = "25.11";

  # OpenCode AI coding agent with declarative config
  programs.opencode-config.enable = true;
}
