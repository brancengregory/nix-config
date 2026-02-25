# Atuin - Modern Shell History with SQLite Backend
# Provides fuzzy, context-aware history search across all terminal sessions
{ config, ... }: {
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    
    settings = {
      # Local-only mode (no cloud sync)
      sync_address = "";
      
      # Inspection mode: insert command but don't run until second Enter press
      enter_accept = false;
      
      # UI preferences
      style = "compact";
      inline_height = 10;
      show_preview = true;
      
      # Search behavior
      search_mode = "fuzzy";
      
      # Start in workspace mode (git project directory context)
      # Shares history between tmux panes and nvim toggleterm in same project
      filter_mode = "workspace";
      
      # Context-aware filtering (enables workspace mode in git repos)
      workspaces = true;
      
      # Custom filter mode cycle order: workspace → global → directory → session → host
      # Optimized for seamless sharing between nvim toggleterm and tmux shells
      search = {
        filters = [ "workspace" "global" "directory" "session" "host" ];
      };
    };
  };
}
