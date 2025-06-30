{pkgs, ...}: {
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
      alejandra
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
      lazygit
      # lazysql maybe
      neovim
      nerd-fonts.fira-code
      nmap
      # ollama maybe
      # opencode maybe
      procs
      (rWrapper.override {
        packages = with rPackages; [
          dplyr
        ];
      })
      # radian
      ripgrep
      scc
      sesh
      sshs
      tealdeer
      tmux
      wireguard-tools
      zoxide
      zsh
    ]
    ++ (
      if pkgs.stdenv.isLinux
      then [
        # Linux specific packages
        sudo
      ]
      else if pkgs.stdenv.isDarwin
      then [
        # Mac specific packages
        # mas-cli maybe
      ]
      else throw "Unsupported OS for this home-manager configuration"
    );

  fonts.fontconfig.enable = true;

  programs.git = {
    enable = true;
    userName = "Brancen Gregory";
    userEmail = "brancengregory@gmail.com";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # Configure fzf for history search
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };

  programs.starship = {
    enable = true;
    settings = {
      format =
        ""
        + "[](#9A348E)"
        + "$os"
        + "$hostname"
        + "[](bg:#DA627D fg:#9A348E)"
        + "$directory"
        + "[](fg:#DA627D bg:#FCA17D)"
        + "$git_branch"
        + "$git_status"
        + "[](fg:#FCA17D bg:#86BBD8)"
        + "$c"
        + "$elixir"
        + "$elm"
        + "$golang"
        + "$gradle"
        + "$haskell"
        + "$java"
        + "$julia"
        + "$nodejs"
        + "$nim"
        + "$rust"
        + "$scala"
        + "[](fg:#86BBD8 bg:#06969A)"
        + "$docker_context"
        + "[](fg:#06969A bg:#33658A)"
        + "$time"
        + "[ ](fg:#33658A)";

      # Disable the blank line at the start of the prompt
      add_newline = false;

      hostname = {
        ssh_symbol = "🌐";
        ssh_only = false;
        format = "[$hostname ]($style)";
        disabled = false;
        style = "bg:#9A348E";
      };

      # You can also replace your username with a neat symbol like   or disable this
      # and use the os module below
      username = {
        show_always = true;
        style_user = "bg:#9A348E";
        style_root = "bg:#9A348E";
        format = "[$user ]($style)";
        disabled = false;
      };

      # An alternative to the username module which displays a symbol that
      # represents the current operating system
      os = {
        format = "[$symbol]($style)";
        style = "bg:#9A348E";
        disabled = false; # Disabled by default
        symbols = {
          Windows = " ";
          Arch = "🐧";
        };
      };

      directory = {
        style = "bg:#DA627D";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";

        # Here is how you can shorten some long paths by text replacement
        # similar to mapped_locations in Oh My Posh:
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
          # Keep in mind that the order matters. For example:
          # "Important Documents" = " 󰈙 ";
          # will not be replaced, because "Documents" was already substituted before.
          # So either put "Important Documents" before "Documents" or use the substituted version:
          # "Important 󰈙 " = " 󰈙 ";
        };
      };

      c = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      docker_context = {
        symbol = " ";
        style = "bg:#06969A";
        format = "[ $symbol $context ]($style)";
      };

      elixir = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      elm = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      git_branch = {
        symbol = "";
        style = "bg:#FCA17D";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#FCA17D";
        format = "[$all_status$ahead_behind ]($style)";
      };

      golang = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      gradle = {
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      haskell = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      julia = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      nim = {
        symbol = "󰆥 ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      scala = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      time = {
        disabled = false;
        style = "bg:#33658A";
        format = "[ ♥ $time ]($style)";
        time_format = "%I:%M %p";
      };
    };
  };

  programs.zsh = {
    enable = true;

    # Enable native home-manager zsh plugins
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    # Shell aliases
    shellAliases =
      {
        cl = "clear";
        v = "nvim";
        cd = "z";
        "/" = "cd /";
        "~" = "cd ~";
        ".." = "cd ..";
        "..." = "cd ../..";
        reload = "source ~/.zshrc";
        l = "ls";
        ls = "eza -al --git --icons=always";
        cat = "bat";
        tre = "eza --tree --level=3 --icons --git-ignore";
        r = "radian";
        md = "glow";
        g = "lazygit";
      }
      // (
        if pkgs.stdenv.isLinux
        then {
          open = "xdg-open";
          ports = "ss -tuln";
        }
        else {
          # macOS uses native open command
          ports = "netstat -anv | grep -E 'LISTEN|Proto'";
        }
      );

    # History configuration
    history = {
      size = 1000000;
      save = 1000000;
      path = "$HOME/.zshistory";
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };

    # Custom functions and additional configuration
    initContent = ''
      # Autocompletion
      autoload -Uz compinit && compinit

      # Custom function for reading files
      c() {
        if [[ "$1" == *.md ]]; then
          glow "$1"
        else
          bat "$1"
        fi
      }

      # History settings (additional options not covered by home-manager)
      setopt append_history           # allow multiple sessions to append to one history
      setopt bang_hist                # treat ! special during command expansion
      setopt hist_expire_dups_first   # expire duplicates first when trimming history
      setopt hist_find_no_dups        # When searching history, don't repeat
      setopt hist_reduce_blanks       # Remove extra blanks from each command added to history
      setopt hist_verify              # Don't execute immediately upon history expansion
      setopt inc_append_history       # Write to history file immediately, not when shell quits
      setopt share_history            # Share history among all sessions

      # Environment variables
      export SSH_ASKPASS_REQUIRE=never
      export GPG_TTY=$(tty)
      ${
        if pkgs.stdenv.isLinux
        then ''
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
          gpg-connect-agent updatestartuptty /bye

          # Make sure sudo works well in tmux
          if [ -n "$TMUX" ]; then
            stty sane
          fi

          export PROJ_DATA=/usr/share/proj
        ''
        else ''
          # macOS specific environment variables would go here if needed
        ''
      }

      # Conda initialization (if available)
      [ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
      export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
    '';

    # Additional PATH entries
    sessionVariables = {
      PATH = "$PATH:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin";
    };
  };

  home.stateVersion = "25.05";
}
