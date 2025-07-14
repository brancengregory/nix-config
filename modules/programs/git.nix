{ pkgs, ... }: {
  home.packages = with pkgs; [
    gh
    git
    lazygit
  ];

  programs.git = {
    enable = true;
    userName = "Brancen Gregory";
    userEmail = "brancengregory@gmail.com";
    signing = {
      key = null; # Let GPG choose the default signing key
      signByDefault = true;
    };
    extraConfig = {
      gpg.program = "gpg2";
    };
  };
}

