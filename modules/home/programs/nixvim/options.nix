# Nixvim Options and Settings
{ ... }: {
  programs.nixvim = {
    # Settings (from lua/config/settings.lua)
    globals = {
      mapleader = " ";
    };

    opts = {
      number = true;
      relativenumber = true;
      expandtab = true;
      shiftwidth = 2;
      softtabstop = 2;
      tabstop = 2;
      smartindent = true;
      wrap = false;
      swapfile = false;
      backup = false;
      undofile = true;
      hlsearch = false;
      incsearch = true;
      termguicolors = true;
      scrolloff = 8;
      signcolumn = "yes";
      updatetime = 50;
      timeoutlen = 300;
      clipboard = "unnamedplus";
    };
  };
}
