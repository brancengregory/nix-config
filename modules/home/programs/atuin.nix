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
      filter_mode = "global";
      workspaces = true;  # Context-aware by directory (shows local commands first)
    };
  };
}
