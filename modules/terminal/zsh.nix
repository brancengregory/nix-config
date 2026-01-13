{pkgs, ...}: {
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

        # History repair
        fix-zsh-history = "mv ~/.zshistory ~/.zshistory_bad && strings ~/.zshistory_bad > ~/.zshistory && fc -R ~/.zshistory && echo 'History repaired.'";
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
}
