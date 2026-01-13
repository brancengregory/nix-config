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
      procs
      yazi
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
        ];
      })
      inputs.radian-flake.packages.${pkgs.system}.default
      ripgrep
      scc
      sesh
      sshs
      tealdeer
    ]
    ++ (
      if pkgs.stdenv.isLinux
      then [
        # Linux specific packages
        sudo
        google-chrome
        slack
        positron-bin
        rustup
      ]
      else if pkgs.stdenv.isDarwin
      then [
        # Mac specific packages
        # mas-cli maybe
      ]
      else throw "Unsupported OS for this home-manager configuration"
    );

  home.stateVersion = "25.05";
}
