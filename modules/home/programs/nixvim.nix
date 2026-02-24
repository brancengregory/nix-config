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

      # File operations under <leader>f
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        options.desc = "Find files";
      }
      {
        mode = "n";
        key = "<leader>fr";
        action = "<cmd>Telescope oldfiles<cr>";
        options.desc = "Recent files";
      }
      {
        mode = "n";
        key = "<leader>fn";
        action = "<cmd>enew<cr>";
        options.desc = "New file";
      }
      {
        mode = "n";
        key = "<leader>fW";
        action = ":w ";
        options.desc = "Write as (name file)";
      }
      {
        mode = "n";
        key = "<leader>fj";
        action = "<cmd>e #<cr>";
        options.desc = "Last file (alternate)";
      }
      {
        mode = "n";
        key = "<leader>fs";
        action = "<cmd>w<cr>";
        options.desc = "Save file";
      }
      {
        mode = "n";
        key = "<leader>fS";
        action = "<cmd>wa<cr>";
        options.desc = "Save all";
      }
      {
        mode = "n";
        key = "<leader>fh";
        action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<cr>";
        options.desc = "Harpoon quick menu";
      }
      {
        mode = "n";
        key = "<leader>fa";
        action = "<cmd>lua require('harpoon'):list():append()<cr>";
        options.desc = "Add to Harpoon";
      }

      # Buffer operations under <leader>b
      {
        mode = "n";
        key = "<leader>bb";
        action = "<cmd>Telescope buffers<cr>";
        options.desc = "List buffers";
      }
      {
        mode = "n";
        key = "<leader>bl";
        action = "<cmd>e #<cr>";
        options.desc = "Last buffer";
      }
      {
        mode = "n";
        key = "<leader>bn";
        action = "<cmd>bnext<cr>";
        options.desc = "Next buffer";
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = "<cmd>bprev<cr>";
        options.desc = "Prev buffer";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = "<cmd>bd<cr>";
        options.desc = "Delete buffer";
      }

      # Legacy Telescope (keep for compatibility)
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

      # Harpoon (reorganized)
      {
        mode = "n";
        key = "<leader>ha";
        action = "<cmd>lua require('harpoon'):list():append()<cr>";
        options.desc = "Add file";
      }
      {
        mode = "n";
        key = "<leader>hh";
        action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<cr>";
        options.desc = "Quick menu";
      }
      {
        mode = "n";
        key = "<leader>h1";
        action = "<cmd>lua require('harpoon'):list():select(1)<cr>";
        options.desc = "File 1";
      }
      {
        mode = "n";
        key = "<leader>h2";
        action = "<cmd>lua require('harpoon'):list():select(2)<cr>";
        options.desc = "File 2";
      }
      {
        mode = "n";
        key = "<leader>h3";
        action = "<cmd>lua require('harpoon'):list():select(3)<cr>";
        options.desc = "File 3";
      }
      {
        mode = "n";
        key = "<leader>h4";
        action = "<cmd>lua require('harpoon'):list():select(4)<cr>";
        options.desc = "File 4";
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

      # Git (now under <leader>g group)
      {
        mode = "n";
        key = "<leader>gs";
        action = "<cmd>Git<cr>";
        options.desc = "Git status";
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<cmd>Git commit<cr>";
        options.desc = "Git commit";
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = "<cmd>Git push<cr>";
        options.desc = "Git push";
      }

      # Comment.nvim mappings (Ctrl+/ for line, Ctrl+Shift+/ for block)
      {
        mode = ["n" "i"];
        key = "<C-/>";
        action = "<cmd>lua require('Comment.api').toggle.linewise.current()<cr>";
        options.desc = "Toggle line comment";
      }
      {
        mode = "v";
        key = "<C-/>";
        action = "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>";
        options.desc = "Toggle line comment (visual)";
      }
      {
        mode = ["n" "i"];
        key = "<C-?>";
        action = "<cmd>lua require('Comment.api').toggle.blockwise.current()<cr>";
        options.desc = "Toggle block comment";
      }
      {
        mode = "v";
        key = "<C-?>";
        action = "<esc><cmd>lua require('Comment.api').toggle.blockwise(vim.fn.visualmode())<cr>";
        options.desc = "Toggle block comment (visual)";
      }

      # R.nvim keybindings (R development)
      {
        mode = "n";
        key = "<leader>rf";
        action = "<cmd>lua require('r.send').source_file()<cr>";
        options.desc = "R: Send file";
      }
      {
        mode = "n";
        key = "<leader>rl";
        action = "<cmd>lua require('r.send').line()<cr>";
        options.desc = "R: Send line";
      }
      {
        mode = "v";
        key = "<leader>rs";
        action = "<cmd>lua require('r.send').selection()<cr>";
        options.desc = "R: Send selection";
      }
      {
        mode = "n";
        key = "<leader>ro";
        action = "<cmd>lua require('r.browser').start()<cr>";
        options.desc = "R: Show objects";
      }
      {
        mode = "n";
        key = "<leader>rr";
        action = "<cmd>lua require('r.run').start_R('R')<cr>";
        options.desc = "R: Start R";
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
            settings = {
              r = {
                lsp = {
                  diagnostics = true;
                  rich_documentation = true;
                };
              };
            };
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

      # Modern completion with blink-cmp
      blink-cmp = {
        enable = true;
        settings = {
          keymap = {
            preset = "default";
          };
          sources = {
            default = ["lsp" "path" "snippets" "buffer"];
          };
          completion = {
            documentation = {
              auto_show = true;
              window = {
                border = "rounded";
              };
            };
            menu = {
              draw = {
                treesitter = ["lsp"];
              };
            };
          };
        };
      };

      # Luasnip for snippets
      luasnip.enable = true;

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
          spec = [
            {
              __unkeyed-1 = "<leader>f";
              group = "File";
              icon = "󰈔";
            }
            {
              __unkeyed-1 = "<leader>b";
              group = "Buffer";
              icon = "󰓩";
            }
            {
              __unkeyed-1 = "<leader>g";
              group = "Git";
              icon = "󰊢";
            }
            {
              __unkeyed-1 = "<leader>h";
              group = "Harpoon";
              icon = "󱡀";
            }
            {
              __unkeyed-1 = "<leader>r";
              group = "R";
              icon = "󰟔";
            }
            {
              __unkeyed-1 = "gc";
              group = "Comment";
              icon = "󰅺";
            }
            {
              __unkeyed-1 = "gb";
              group = "Block Comment";
              icon = "󰅺";
            }
          ];
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

      # Rust tools - rustaceanvim (modern standard)
      rustaceanvim = {
        enable = true;
        settings = {
          server = {
            enable = true;
            default_settings = {
              rust-analyzer = {
                cargo = {
                  allFeatures = true;
                };
                checkOnSave = true;
                check = {
                  command = "clippy";
                };
              };
            };
          };
        };
      };

      # Comment.nvim - Smart commenting
      comment = {
        enable = true;
        settings = {
          mappings = {
            basic = true;
            extra = true;
          };
        };
      };

      # R.nvim - R development environment (v0.99.3)
      # Built from source since not available in nixvim modules
    };

    # Extra plugins built from source
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin {
        name = "r-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "R-nvim";
          repo = "R.nvim";
          rev = "v0.99.3";
          sha256 = "sha256-oQSHHu6filJkAyH94yEvyTVuxA+5MU2dMOEAnsIjJKQ=";
        };
        buildInputs = [ 
          pkgs.which
          pkgs.zip
        ];
      })
    ];

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
