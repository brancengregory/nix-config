{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    mouse = true;
    clock24 = true;
    escapeTime = 10;

    # Key bindings
    keyMode = "vi";
    prefix = "C-b";

    # Terminal and environment settings
    terminal = "tmux-256color";

    # Plugins managed by home-manager (replaces tpm)
    plugins = with pkgs.tmuxPlugins; [
      sensible
    ];

    extraConfig = ''
      # Enable true color support
      set-option -sa terminal-overrides ",xterm-256color:Tc"

      # No confirmation needed to kill session
      bind-key x kill-pane

      # Switch to another session when one is killed
      set-option -g detach-on-destroy off

      # GPG/SSH integration - streamlined environment passing
      set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION SSH_AUTH_SOCK WINDOWID XAUTHORITY GPG_TTY"

      # Optimized GPG_TTY update - only when needed, not on every pane switch
      set-hook -g session-created 'run-shell "export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
      set-hook -g client-attached 'run-shell "export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'

      # Shell integration
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
      set-option -g pane-border-format " #{pane_index} "
    '';
  };
}
