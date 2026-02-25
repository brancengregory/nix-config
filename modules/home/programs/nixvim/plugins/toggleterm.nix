# Floating Terminal (toggleterm.nvim)
# Uses $SHELL from environment to inherit parent shell with Atuin integration
{ ... }: {
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
        # shell is omitted - uses vim.o.shell which inherits $SHELL from environment
        # This ensures toggleterm uses the same shell as the parent tmux session
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
