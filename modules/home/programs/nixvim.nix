{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    # Settings (from lua/config/settings.lua)
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

    # Keymaps (from lua/config/keymaps.lua)
    keymaps = [
      # Core mappings
      {
        mode = "n";
        key = "<leader>pv";
        action = "<cmd>Ex<cr>";
      }
      {
        mode = "n";
        key = "<leader>u";
        action = "<cmd>UndotreeToggle<cr>";
      }

      # Telescope
      {
        mode = "n";
        key = "<leader>pf";
        action = "<cmd>Telescope find_files<cr>";
      }
      {
        mode = "n";
        key = "<C-p>";
        action = "<cmd>Telescope git_files<cr>";
      }
      {
        mode = "n";
        key = "<leader>ps";
        action = "<cmd>Telescope live_grep<cr>";
      }
      {
        mode = "n";
        key = "<leader>pb";
        action = "<cmd>Telescope buffers<cr>";
      }
      {
        mode = "n";
        key = "<leader>ph";
        action = "<cmd>Telescope help_tags<cr>";
      }

      # Harpoon
      {
        mode = "n";
        key = "<leader>a";
        action = "<cmd>lua require('harpoon'):list():append()<cr>";
      }
      {
        mode = "n";
        key = "<C-e>";
        action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<cr>";
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<cmd>lua require('harpoon'):list():select(1)<cr>";
      }
      {
        mode = "n";
        key = "<C-t>";
        action = "<cmd>lua require('harpoon'):list():select(2)<cr>";
      }
      {
        mode = "n";
        key = "<C-n>";
        action = "<cmd>lua require('harpoon'):list():select(3)<cr>";
      }
      {
        mode = "n";
        key = "<C-s>";
        action = "<cmd>lua require('harpoon'):list():select(4)<cr>";
      }

      # LSP
      {
        mode = "n";
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<cr>";
      }
      {
        mode = "n";
        key = "gr";
        action = "<cmd>lua vim.lsp.buf.references()<cr>";
      }
      {
        mode = "n";
        key = "gI";
        action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
      }
      {
        mode = "n";
        key = "<leader>D";
        action = "<cmd>lua vim.lsp.buf.type_definition()<cr>";
      }
      {
        mode = "n";
        key = "<leader>rn";
        action = "<cmd>lua vim.lsp.buf.rename()<cr>";
      }
      {
        mode = "n";
        key = "<leader>ca";
        action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
      }
      {
        mode = "n";
        key = "K";
        action = "<cmd>lua vim.lsp.buf.hover()<cr>";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
      }

      # Git
      {
        mode = "n";
        key = "<leader>gs";
        action = "<cmd>Git<cr>";
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<cmd>Git commit<cr>";
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = "<cmd>Git push<cr>";
      }
    ];

    # Plugins (all 20 from lazy-lock.json)
    plugins = {
      # LSP
      lsp = {
        enable = true;
        servers = {
          # Language servers
          lua_ls.enable = true;
          r_language_server = {
            enable = true;
            package = pkgs.rPackages.languageserver;
          };
          # rust-analyzer disabled - using rustaceanvim instead
          pyright.enable = true;
          bashls.enable = true;
          nixd.enable = true;
          jsonls.enable = true;
          yamlls.enable = true;
        };
        keymaps = {
          diagnostic = {
            "<leader>e" = "open_float";
            "[d" = "goto_prev";
            "]d" = "goto_next";
          };
          lspBuf = {
            "gd" = "definition";
            "gr" = "references";
            "gI" = "implementation";
            "<leader>D" = "type_definition";
            "<leader>rn" = "rename";
            "<leader>ca" = "code_action";
          };
        };
      };

      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          ensure_installed = [
            "lua"
            "r"
            "rust"
            "python"
            "bash"
            "json"
            "yaml"
            "markdown"
            "nix"
            "rasi"
          ];
        };
      };

      # Telescope
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
        };
      };

      # Completions
      cmp = {
        enable = true;
        settings = {
          sources = [
            {name = "nvim_lsp";}
            {name = "luasnip";}
            {name = "buffer";}
            {name = "path";}
          ];
          mapping = {
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_next_item() elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump() else fallback() end end, { 'i', 's' })";
            "<S-Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_prev_item() elseif luasnip.jumpable(-1) then luasnip.jump(-1) else fallback() end end, { 'i', 's' })";
          };
        };
      };

      # Luasnip
      luasnip.enable = true;
      cmp_luasnip.enable = true;

      # Lualine
      lualine = {
        enable = true;
        settings = {
          options = {
            theme = "auto";
            component_separators = {
              left = "";
              right = "";
            };
            section_separators = {
              left = "";
              right = "";
            };
          };
        };
      };

      # Which-key
      which-key = {
        enable = true;
        settings = {
          preset = "modern";
        };
      };

      # Dashboard
      dashboard = {
        enable = true;
        settings = {
          theme = "hyper";
          config = {
            week_header = {
              enable = true;
            };
            shortcut = [
              {
                desc = "󰊳 Update";
                group = "@property";
                action = "LazyUpdate";
                key = "u";
              }
              {
                desc = "󰈔 Files";
                group = "Label";
                action = "Telescope find_files";
                key = "f";
              }
              {
                desc = " Dotfiles";
                group = "DiagnosticHint";
                action = "Telescope find_files cwd=~/.config/nvim";
                key = "d";
              }
            ];
          };
        };
      };

      # Harpoon (custom configuration needed)
      harpoon = {
        enable = true;
        package = pkgs.vimPlugins.harpoon2;
      };

      # Devicons
      web-devicons.enable = true;

      # Rust tools - using rustaceanvim instead of abandoned rust-tools
      rustaceanvim = {
        enable = true;
        settings = {
          server = {
            enable = true;
          };
        };
      };
    };

    # Colorscheme - use default neovim colorscheme
    # Can be overridden by user config or stylix
    colorscheme = "default";

    # Extra Lua configuration for complex setups
    extraConfigLua = ''
      -- Harpoon 2 setup
      local harpoon = require("harpoon")
      harpoon:setup()

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
