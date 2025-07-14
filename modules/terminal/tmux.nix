{pkgs, ...}: {
  home.packages = with pkgs; [
    tmux
  ];

  programs.tmux = {
    enable = true;
    extraConfig = ''
      # Streamlined environment variable passing
      set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION SSH_AUTH_SOCK WINDOWID XAUTHORITY GPG_TTY"

      # Efficient GPG_TTY updates - only when creating sessions or attaching clients
      set-hook -g session-created 'run-shell "export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
      set-hook -g client-attached 'run-shell "export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
    '';
  };
}
