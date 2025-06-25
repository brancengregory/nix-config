{ pkgs, ... }:

{
  home.username = "brancengregory";
  home.homeDirectory = "/home/brancengregory";

  home.packages = with pkgs; [
    bat
    eza
    fd
    fzf
    # ghostty maybe
    git
    glow
    htop
    hwatch
    jaq
    jnv
    # lazygit maybe
    # lazysql maybe
    neovim
    nmap
    # ollama maybe
    # opencode maybe
    procs
    # r maybe
    # radian maybe
    ripgrep
    scc
    sesh
    sheldon
    sshs
    starship
    sudo
    tealdeer
    tmux
    ttf-firacode-nerd
    wireguard-tools
    zoxide
    zsh
    zsh-autosuggestions
    zsh-completions
    zsh-fast-syntax-highlighting
  ];

  programs.git = {
    enable = true;
    userName = "Brancen Gregory";
    userEmail = "brancengregory@gmail.com";
  };

  home.stateVersion = "25.05";
}
