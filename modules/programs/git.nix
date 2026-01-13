{pkgs, ...}: {
  home.packages = with pkgs; [
    # gh is managed by programs.gh below
    git
    lazygit
  ];

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
  };

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
