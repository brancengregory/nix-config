{
  pkgs,
  inputs,
  config,
  isLinux,
  isDarwin,
  ...
}: {
  imports = [
    ../../modules/home/fonts.nix
    ../../modules/home/gpg.nix
    ../../modules/home/ssh.nix
    ../../modules/home/terminal/zsh.nix
    ../../modules/home/terminal/starship.nix
    ../../modules/home/terminal/tmux.nix
    ../../modules/home/terminal/nvim.nix
    ../../modules/home/programs/git.nix
    inputs.sops-nix.homeManagerModules.sops
  ];

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
  home.homeDirectory = "/home/brancengregory";

  # Server-specific packages (minimal, CLI-only)
  home.packages = with pkgs; [
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
    # Server-specific tools
    pinentry-curses
    sudo
    rsync
    restic
  ];

  home.stateVersion = "25.11";

  # Selectively enable Stylix targets for Home Manager
  stylix.targets = {
    starship.enable = true;
  };
}
