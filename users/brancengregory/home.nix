{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules/fonts/default.nix
    ../../modules/desktop/plasma-home.nix
    ../../modules/terminal/zsh.nix
    ../../modules/terminal/starship.nix
    ../../modules/terminal/tmux.nix
    ../../modules/terminal/nvim.nix
    ../../modules/security/default.nix
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

  home.stateVersion = "25.11";

  # Selectively enable Stylix targets for Home Manager
  stylix.targets = {
    starship.enable = true;
    ghostty.enable = true;
  };
}
