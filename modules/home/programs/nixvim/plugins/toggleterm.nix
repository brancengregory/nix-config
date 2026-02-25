# Floating Terminal (toggleterm.nvim)
{ pkgs, ... }: {
  programs.nixvim = {
    plugins.toggleterm = {
      enable = true;
      settings = {
        size = 20;
        open_mapping = "[[<leader>`]]";
        hide_numbers = true;
        shade_terminals = true;
        start_in_insert = true;
        persist_size = true;
        direction = "float";
        close_on_exit = true;
        shell = "${pkgs.zsh}/bin/zsh";
        float_opts = {
          border = "curved";
          width = 80;
          height = 15;
          winblend = 0;
        };
      };
    };
  };
}
