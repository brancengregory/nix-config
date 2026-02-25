# Session Management (auto-session.nvim)
{ ... }: {
  programs.nixvim.plugins.auto-session = {
    enable = true;
    settings = {
      log_level = "error";
      auto_session_enabled = true;
      auto_save_enabled = true;
      auto_restore_enabled = true;
      auto_session_suppress_dirs = [
        "/"
        "/tmp"
        "/var/tmp"
        "~/Downloads"
        "/nix/store"
      ];
      auto_session_use_git_branch = true;
      auto_session_root_dir = "~/.local/share/nvim/sessions/";
      bypass_save_filetypes = ["neo-tree" "trouble" "qf"];
      cwd_change_handling = true;
    };
  };
}
