# Navigation Plugins (Telescope, Harpoon, Neo-tree)
{ pkgs, ... }: {
  programs.nixvim.plugins = {
    # Telescope
    telescope = {
      enable = true;
      extensions = {
        fzf-native.enable = true;
      };
      settings.defaults = {
        vimgrep_arguments = [
          "${pkgs.ripgrep}/bin/rg"
          "--color=never"
          "--no-heading"
          "--with-filename"
          "--line-number"
          "--column"
          "--smart-case"
          "--hidden"
        ];
      };
    };

    # Harpoon
    harpoon = {
      enable = true;
      package = pkgs.vimPlugins.harpoon2;
    };

    # Neo-tree - Modern file browser
    neo-tree = {
      enable = true;
      settings = {
        enable_diagnostics = true;
        enable_git_status = true;
        enable_modified_markers = true;
        enable_refresh_on_write = true;
        filesystem = {
          filtered_items = {
            hide_dotfiles = false;
            hide_gitignored = false;
          };
          follow_current_file = {
            enabled = true;
            leave_dirs_open = true;
          };
          use_libuv_file_watcher = true;
        };
        window = {
          position = "left";
          width = 30;
        };
      };
    };
  };
}
