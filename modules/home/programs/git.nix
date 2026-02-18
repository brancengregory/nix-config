{pkgs, ...}: {
  home.packages = with pkgs; [
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

    # User configuration
    settings = {
      user = {
        name = "Brancen Gregory";
        email = "brancengregory@gmail.com";
      };

      init.defaultBranch = "main";
      credential.helper = "cache";
      commit.gpgSign = true;
      push.autoSetupRemote = true;

      # Delta pager configuration
      core = {
        pager = "delta";
        excludesFile = "~/.gitignore";
      };

      interactive.diffFilter = "delta --color-only";

      delta = {
        navigate = true;
        dark = true;
        side-by-side = true;
      };

      merge.conflictStyle = "zdiff3";

      # Alias from chezmoi
      alias.tree = "log --color --date-order --graph --oneline --decorate --simplify-by-decoration --all";

      # Git LFS configuration
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      # GPG program
      gpg.program = "gpg";
    };

    # Signing configuration
    signing = {
      key = "16C3D5566DA9B10B";
      signByDefault = true;
    };
  };
}
