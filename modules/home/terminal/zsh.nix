{
  pkgs,
  isLinux,
  isDarwin,
  ...
}: {
  home.packages = with pkgs; [
    fzf
    zoxide
    zsh
  ];

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

  programs.zsh = {
    enable = true;

    # Enable native home-manager zsh plugins (replaces sheldon)
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    # Additional plugins managed natively
    plugins = [
      {
        name = "zsh-fzf-history-search";
        src = pkgs.fetchFromGitHub {
          owner = "joshskidmore";
          repo = "zsh-fzf-history-search";
          rev = "35df458f7d9478fa88c74af762dcd296cdfd485d";
          sha256 = "0lnm5j3kzwsfmlwmzyaf08j27kp4h403vnwxxfh5q99xaiyacig9";
        };
      }
    ];

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
        diff = "delta";
        tre = "eza --tree --level=3 --icons --git-ignore";
        r = "radian";
        s = "sesh cn .";
        h = "sesh cn home";
        md = "glow";
        g = "lazygit";
        ai = "opencode";

        # GPG/SSH troubleshooting aliases
        gpg-restart = "gpgconf --kill gpg-agent && gpgconf --launch gpg-agent";
        gpg-status = "gpg-connect-agent 'keyinfo --list' /bye";
        ssh-keys = "ssh-add -l";
        gpg-refresh = "refresh_gpg";
      }
      // (
        if isLinux
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
      share = true;
    };

    # Custom functions and additional configuration
    initContent = ''
      # Source secrets if they exist
      if [ -f "$HOME/.config/zsh/secrets.zsh" ]; then
        source "$HOME/.config/zsh/secrets.zsh"
      fi

      # Platform-specific paths
      ${
        if isLinux
        then ''
          path+=('/home/brancengregory/.cargo/bin' '/home/brancengregory/go/bin')
        ''
        else ''
          path+=('/Users/brancengregory/.cargo/bin' '/Users/brancengregory/go/bin')
        ''
      }

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

      # Handle corrupt history file
      if ! fc -l 1 >/dev/null 2>&1 && [ -f ~/.zshistory ] && [ -s ~/.zshistory ]; then
        mv ~/.zshistory ~/.zshistory.bad.$(date +%s)
        touch ~/.zshistory
      fi

      # Yazi wrapper function
      function f() {
      	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
      	yazi "$@" --cwd-file="$tmp"
      	IFS= read -r -d "" cwd < "$tmp"
      	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
      	rm -f -- "$tmp"
      }

      # History settings (additional options not covered by home-manager)
      setopt append_history           # allow multiple sessions to append to one history
      setopt bang_hist                # treat ! special during command expansion
      setopt hist_expire_dups_first   # expire duplicates first when trimming history
      setopt hist_find_no_dups        # When searching history, don't repeat
      setopt hist_reduce_blanks       # Remove extra blanks from each command added to history
      setopt hist_verify              # Don't execute immediately upon history expansion
      setopt inc_append_history       # Write to history file immediately, not when shell quits
      # share_history is handled by home-manager option above

      # Add history search keys
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down


      # Unified GPG/SSH environment setup
      export SSH_ASKPASS_REQUIRE=never

      # Optimized GPG_TTY handling
      if [ -t 1 ]; then
        export GPG_TTY=$(tty)
        # Only update GPG agent if it's running (lazy initialization)
        if pgrep -x gpg-agent >/dev/null 2>&1; then
          gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
        fi
      fi

      # Platform-specific configuration
      ${
        if isLinux
        then ''
          # Linux: Use GPG agent for SSH authentication
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"

          # Tmux-specific improvements
          if [ -n "$TMUX" ]; then
            stty sane
          fi

          export PROJ_DATA=/usr/share/proj
        ''
        else ''
          # macOS: Use GPG agent for SSH authentication
          export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
          # Ensure GPG agent is running (lazy start)
          gpgconf --launch gpg-agent 2>/dev/null || true
        ''
      }

      # Tmux integration with performance optimization
      if [ -n "$TMUX" ]; then
        # Simplified refresh function for manual use
        refresh_gpg() {
          export GPG_TTY=$(tty)
          if pgrep -x gpg-agent >/dev/null 2>&1; then
            gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
            echo "GPG agent refreshed for current tmux pane"
          else
            echo "GPG agent not running"
          fi
        }

        # Ensure terminal is properly configured in tmux
        [ -t 1 ] && stty sane 2>/dev/null || true
      fi

      # Conda initialization (if available)
      [ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
      export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

      # Platform-specific Homebrew settings
      ${
        if isDarwin
        then ''
          export HOMEBREW_NO_INSTALL_CLEANUP=1
        ''
        else ""
      }
    '';

    # Additional PATH entries
    sessionVariables = {
      PATH = "$PATH:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin";
    };
  };
}
