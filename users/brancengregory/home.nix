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
      gnupg
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
      openssh
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
        pinentry-gtk2
        sudo
      ]
      else if pkgs.stdenv.isDarwin
      then [
        # Mac specific packages
        pinentry_mac
        # mas-cli maybe
      ]
      else throw "Unsupported OS for this home-manager configuration"
    );

  fonts.fontconfig.enable = true;

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

  # Comprehensive GPG configuration
  programs.gpg = {
    enable = true;

    # GPG configuration settings
    settings = {
      # Use modern algorithms and stronger defaults
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cipher-algo = "AES256";
      digest-algo = "SHA512";
      cert-digest-algo = "SHA512";
      compress-algo = "ZLIB";
      disable-cipher-algo = "3DES";
      weak-digest = "SHA1";
      s2k-mode = "3";
      s2k-digest-algo = "SHA512";
      s2k-count = "65011712";

      # Display options
      fixed-list-mode = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;

      # Behavior
      require-cross-certification = true;
      no-symkey-cache = true;
      use-agent = true;
      throw-keyids = true;

      # Keyserver settings (using keys.openpgp.org as default)
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "no-honor-keyserver-url include-revoked";
    };
  };

  # SSH configuration with GPG agent integration
  programs.ssh = {
    enable = true;

    # Global SSH client configuration
    extraConfig = ''
      # Security settings
      Protocol 2
      HashKnownHosts yes
      VisualHostKey yes
      PasswordAuthentication no
      ChallengeResponseAuthentication no
      StrictHostKeyChecking ask
      VerifyHostKeyDNS yes
      ForwardAgent no
      ForwardX11 no
      ForwardX11Trusted no
      ServerAliveInterval 300
      ServerAliveCountMax 2
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
      HostKeyAlgorithms ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-256,rsa-sha2-512
      PubkeyAcceptedKeyTypes ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-256,rsa-sha2-512
    '';

    # Common host configurations
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        # Use GPG SSH key for GitHub
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identitiesOnly = true;
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      # Template for personal servers
      "*.local" = {
        user = "brancengregory";
        identitiesOnly = true;
      };
    };
  };

  # GPG Agent configuration for SSH and GPG operations
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableScDaemon = true;

    # Platform-specific pinentry programs with tmux compatibility
    pinentry.package =
      if pkgs.stdenv.isLinux
      then pkgs.pinentry-gtk2  # GTK pinentry works well with tmux on Linux
      else if pkgs.stdenv.isDarwin
      then pkgs.pinentry_mac   # macOS native pinentry
      else throw "Unsupported OS for GPG agent configuration";

    # Agent settings
    defaultCacheTtl = 28800; # 8 hours
    defaultCacheTtlSsh = 28800; # 8 hours
    maxCacheTtl = 86400; # 24 hours
    maxCacheTtlSsh = 86400; # 24 hours

    # Extra configuration for tmux compatibility
    extraConfig = ''
      allow-preset-passphrase
      no-allow-external-cache
      enforce-passphrase-constraints
      min-passphrase-len 12
      min-passphrase-nonalpha 2
      check-passphrase-pattern
      
      # Tmux compatibility improvements
      # Allow loopback pinentry for better tmux integration
      allow-loopback-pinentry
      
      # Debug options (can be removed in production)
      # debug-level guru
      # log-file /tmp/gpg-agent.log
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Tmux configuration optimized for GPG/SSH integration
  programs.tmux = {
    enable = true;
    mouse = true;
    clock24 = true;
    
    # Key bindings
    keyMode = "vi";
    prefix = "C-a";
    
    # Terminal and environment settings
    terminal = "screen-256color";
    
    extraConfig = ''
      # Enable true color support
      set-option -sa terminal-overrides ",xterm*:Tc"
      
      # GPG/SSH integration improvements
      set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION SSH_AUTH_SOCK WINDOWID XAUTHORITY GPG_TTY"
      
      # Hook to update GPG_TTY when switching panes/windows
      set-hook -g pane-focus-in 'run-shell "[ -n \"$TMUX\" ] && export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
      
      # Ensure shell integration works properly
      set-option -g default-shell ${pkgs.zsh}/bin/zsh
      
      # Better pane splitting
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      
      # Reload configuration
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
      
      # Status bar
      set-option -g status-position top
      set-option -g status-style "fg=#7C7D83,bg=#242631"
      set-option -g status-left-length 50
      set-option -g status-right-length 50
      
      # Window status
      set-window-option -g window-status-current-style "fg=#E2E4E5,bg=#414550"
      
      # Pane borders
      set-option -g pane-border-style "fg=#7C7D83"
      set-option -g pane-active-border-style "fg=#E2E4E5"
    '';
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
        
        # GPG/SSH troubleshooting aliases
        gpg-restart = "gpgconf --kill gpg-agent && gpgconf --launch gpg-agent";
        gpg-status = "gpg-connect-agent 'keyinfo --list' /bye";
        ssh-keys = "ssh-add -l";
        gpg-refresh = "refresh_gpg";
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

      # Environment variables for unified GPG/SSH strategy
      export SSH_ASKPASS_REQUIRE=never
      
      # Dynamic GPG_TTY handling for tmux compatibility
      update_gpg_tty() {
        export GPG_TTY=$(tty)
        if [ -n "$GPG_AGENT_INFO" ] || pgrep -x gpg-agent >/dev/null 2>&1; then
          gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
        fi
      }
      
      # Set initial GPG_TTY and update it
      update_gpg_tty
      
      # Update GPG_TTY when entering new shells (important for tmux)
      if [ -n "$TMUX" ]; then
        # In tmux, update GPG_TTY whenever we start a new shell
        update_gpg_tty
      fi

      ${
        if pkgs.stdenv.isLinux
        then ''
          # Linux: Use GPG agent for SSH authentication
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"

          # Tmux-specific improvements
          if [ -n "$TMUX" ]; then
            # Ensure SSH agent socket is available in tmux
            if [ ! -S "$SSH_AUTH_SOCK" ]; then
              export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
            fi
            
            # Make sure sudo and other commands work well in tmux
            stty sane
            
            # Create a function to refresh GPG agent in current tmux pane
            refresh_gpg() {
              update_gpg_tty
              echo "GPG agent refreshed for current tmux pane"
            }
          fi

          export PROJ_DATA=/usr/share/proj
        ''
        else ''
          # macOS: Use GPG agent for SSH authentication
          export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"

          # Ensure GPG agent is running
          gpgconf --launch gpg-agent
          
          # Tmux-specific improvements for macOS
          if [ -n "$TMUX" ]; then
            # Verify SSH socket is accessible in tmux
            if [ ! -S "$SSH_AUTH_SOCK" ]; then
              export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
            fi
            
            # Create a function to refresh GPG agent in current tmux pane
            refresh_gpg() {
              update_gpg_tty
              gpgconf --launch gpg-agent
              echo "GPG agent refreshed for current tmux pane"
            }
          fi
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
