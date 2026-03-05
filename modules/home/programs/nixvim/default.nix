# Main Nixvim Configuration Entry Point
# Imports all modularized nixvim configurations
{inputs, ...}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./options.nix
    ./keymaps.nix
    ./plugins/lsp.nix
    ./plugins/completion.nix
    ./plugins/navigation.nix
    ./plugins/treesitter.nix
    ./plugins/ui.nix
    ./plugins/development.nix
    ./plugins/git.nix
    ./plugins/diagnostics.nix
    ./plugins/notifications.nix
    ./plugins/buffers.nix
    ./plugins/session.nix
    ./plugins/focus.nix
    ./plugins/lazygit.nix
    ./plugins/tmux-navigator.nix
    ./plugins/toggleterm.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    # Colorscheme - use default neovim colorscheme
    # Can be overridden by user config or stylix
    colorscheme = "default";

    # Extra Lua configuration for complex setups
    extraConfigLua = ''
      -- Harpoon 2 setup
      local harpoon = require("harpoon")
      harpoon:setup()

      -- R.nvim setup for R development (v0.99.3)
      -- Completion works via built-in LSP, no manual hook needed
      require("r").setup({
        R_app = "radian",
        quarto_chunk_hl = {
          highlight = true,
          yaml_hl = true,
          virtual_title = true,
          bg = "",
          events = "",
        },
        R_args = {"--no-save", "--no-restore"},
        min_editor_width = 80,
        pdfviewer = "zathura",
      })

      -- Dashboard header
      require("dashboard").setup({
        theme = "hyper",
        config = {
          header = {
            "                                                     ",
            "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗  ",
            "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║  ",
            "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║  ",
            "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║  ",
            "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║  ",
            "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝  ",
            "                                                     ",
          },
        },
      })
    '';
  };
}
