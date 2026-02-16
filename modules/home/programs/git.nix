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
    settings = {
      user = {
        name = "Brancen Gregory";
        email = "brancengregory@gmail.com";
      };
      gpg.program = "gpg2";
    };
    signing = {
      key = null; # Let GPG choose the default signing key
      signByDefault = true;
    };
  };
}
