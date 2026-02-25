# Tmux-Navigator Integration for seamless nvim/tmux navigation
{ ... }: {
  programs.nixvim.plugins.tmux-navigator = {
    enable = true;
    # This enables seamless Ctrl+h/j/k/l navigation between nvim windows and tmux panes
    # The plugin automatically detects tmux boundaries
  };
}
