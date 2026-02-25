# Lazygit Integration (lazygit.nvim)
{ pkgs, ... }: {
  programs.nixvim = {
    plugins.lazygit = {
      enable = true;
      package = pkgs.vimPlugins.lazygit-nvim;
      settings = {
        floating_window_winblend = 0;
        floating_window_scaling_factor = 0.9;
        floating_window_border_chars = ["╭" "─" "╮" "│" "╯" "─" "╰" "│"];
        floating_window_use_plenary = 0;
        use_neovim_remote = 1;
        use_custom_config_file_path = 0;
        config_file_path = [];
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>LazyGit<cr>";
        options.desc = "Open lazygit";
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<cmd>LazyGitConfig<cr>";
        options.desc = "Open lazygit config";
      }
      {
        mode = "n";
        key = "<leader>gf";
        action = "<cmd>LazyGitFilter<cr>";
        options.desc = "Open lazygit file history";
      }
      {
        mode = "n";
        key = "<leader>gF";
        action = "<cmd>LazyGitFilterCurrentFile<cr>";
        options.desc = "Open lazygit current file history";
      }
    ];
  };
}
