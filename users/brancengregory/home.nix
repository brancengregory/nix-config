{
  pkgs,
  inputs,
  config,
  isLinux,
  isDarwin,
  ...
}: {
  imports =
    [
      ../../modules/fonts/default.nix
      ../../modules/terminal/zsh.nix
      ../../modules/terminal/starship.nix
      ../../modules/terminal/tmux.nix
      ../../modules/terminal/nvim.nix
      ../../modules/security/default.nix
      ../../modules/programs/git.nix
      ../../modules/programs/r.nix
      inputs.sops-nix.homeManagerModules.sops
    ]
    ++ (
      if isLinux
      then [
        ../../modules/desktop/plasma-home.nix
      ]
      else []
    );

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/brancengregory/.config/sops/age/keys.txt";

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
      sops
      ssh-to-age
    ]
    ++ (
      if pkgs.stdenv.isLinux
      then [
        inputs.plasma-manager.packages.${pkgs.stdenv.hostPlatform.system}.rc2nix
        pkgs.ghostty
      ]
      else []
    )
    ++ [
      # ollama maybe
      # opencode maybe
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
    ++ (
      if pkgs.stdenv.isLinux
      then [
        # Linux specific packages
        pinentry-curses
        sudo
        slack
        discord
        zoom-us
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

  xdg.mimeApps =
    if isLinux
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

  # Selectively enable Stylix targets for Home Manager
  stylix.targets = {
    starship.enable = true;
    ghostty.enable = true;
  };
}
