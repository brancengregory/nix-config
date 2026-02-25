# UI Plugins (Lualine, Dashboard, Which-key, Devicons)
{ ... }: {
  programs.nixvim.plugins = {
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
          {
            __unkeyed-1 = "<leader>s";
            group = "Session";
            icon = "󰆓";
          }
          {
            __unkeyed-1 = "<leader>t";
            group = "TODO";
            icon = "󰄱";
          }
          {
            __unkeyed-1 = "<leader>z";
            group = "Zen";
            icon = "󰼠";
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

    # Devicons
    web-devicons.enable = true;
  };
}
