{ pkgs, ... }:

{
  home.username = "brancengregory";
  home.homeDirectory = "/home/brancengregory";

  home.packages = with pkgs; [
    fd
    git
    neovim
    ripgrep
    htop
  ];

  programs.git = {
    enable = true;
    userName = "Brancen Gregory";
    userEmail = "brancengregory@gmail.com";
  };

  home.stateVersion = "25.05";
}
