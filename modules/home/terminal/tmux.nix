{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    mouse = true;
    clock24 = false;
    escapeTime = 10;

    # Key bindings
    keyMode = "vi";
    prefix = "C-b";

    # Terminal and environment settings
    terminal = "tmux-256color";

    # Plugins managed by home-manager (replaces tpm)
    plugins = with pkgs.tmuxPlugins; [
			{
        plugin = resurrect;
				extraConfig = ''
				  set -g @resurrect-strategy-nvim 'session'
					set -g @resurrect-capture-pane-contents 'on'
				'';
			}
			sensible
    ];

    extraConfig = ''
      # Enable true color support
      set-option -sa terminal-overrides ",xterm-256color:Tc"

      # No confirmation needed to kill session
      bind-key x kill-pane

      # Switch to another session when one is killed
      set-option -g detach-on-destroy off

			# Pane borders
			set -g pane-border-style fg=gray
			set -g pane-active-border-style fg=brightcyan
			set -g pane-boarder-format " #{pane_index} "

      # Reload configuration
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"

      # Shell integration
      set-option -g default-shell ${pkgs.zsh}/bin/zsh

      # GPG/SSH integration - streamlined environment passing
      set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION SSH_AUTH_SOCK WINDOWID XAUTHORITY GPG_TTY"

      # Optimized GPG_TTY update - only when needed, not on every pane switch
      set-hook -g session-created 'run-shell "export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
      set-hook -g client-attached 'run-shell "export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
    '';
  };
}
