# Focus Mode (zen-mode) and Todo Comments
{ ... }: {
  programs.nixvim.plugins = {
    # Zen mode - distraction free editing
    zen-mode = {
      enable = true;
      settings = {
        window = {
          backdrop = 0.95;
          width = 120;
          height = 1;
          options = {
            signcolumn = "no";
            number = false;
            relativenumber = false;
            cursorline = false;
            cursorcolumn = false;
            foldcolumn = "0";
            list = false;
          };
        };
        plugins = {
          options = {
            enabled = true;
            ruler = false;
            showcmd = false;
            laststatus = 0;
          };
          twilight = {
            enabled = true;
          };
          gitsigns = {
            enabled = false;
          };
          tmux = {
            enabled = true;
          };
          todo = {
            enabled = false;
          };
        };
        on_open.__raw = ''
          function()
            vim.cmd("set laststatus=0")
          end
        '';
        on_close.__raw = ''
          function()
            vim.cmd("set laststatus=2")
          end
        '';
      };
    };

    # Todo comments - highlight TODO/FIXME/HACK/etc
    todo-comments = {
      enable = true;
      settings = {
        signs = true;
        sign_priority = 8;
        keywords = {
          FIX = {
            icon = " ";
            color = "error";
            alt = ["FIXME" "BUG" "FIXIT" "ISSUE"];
          };
          TODO = {
            icon = " ";
            color = "info";
          };
          HACK = {
            icon = " ";
            color = "warning";
          };
          WARN = {
            icon = " ";
            color = "warning";
            alt = ["WARNING" "XXX"];
          };
          PERF = {
            icon = "󰓅 ";
            alt = ["OPTIM" "PERFORMANCE" "OPTIMIZE"];
          };
          NOTE = {
            icon = "󰍨 ";
            color = "hint";
            alt = ["INFO"];
          };
          TEST = {
            icon = "󰙨 ";
            color = "test";
            alt = ["TESTING" "PASSED" "FAILED"];
          };
        };
        gui_style = {
          fg = "NONE";
          bg = "BOLD";
        };
        merge_keywords = true;
        highlight = {
          multiline = true;
          multiline_pattern = "^.";
          multiline_context = 10;
          before = "";
          keyword = "wide";
          after = "fg";
          pattern = ''[[.*<(KEYWORDS)\s*:]]'';
          comments_only = true;
          max_line_len = 400;
          exclude = [];
        };
        colors = {
          error = ["DiagnosticError" "ErrorMsg" "#DC2626"];
          warning = ["DiagnosticWarn" "WarningMsg" "#FBBF24"];
          info = ["DiagnosticInfo" "#2563EB"];
          hint = ["DiagnosticHint" "#10B981"];
          default = ["Identifier" "#7C3AED"];
          test = ["Identifier" "#FF00FF"];
        };
        search = {
          command = "rg";
          args = [
            "--color=never"
            "--no-heading"
            "--with-filename"
            "--line-number"
            "--column"
          ];
          pattern = ''[[\b(KEYWORDS):]]'';
        };
      };
    };

    # Twilight - dim inactive code (zen-mode companion)
    twilight = {
      enable = true;
      settings = {
        dimming = {
          alpha = 0.25;
          color = ["Normal"];
          inactive = true;
        };
        context = 10;
        treesitter = true;
        expand = ["function" "method" "table" "if_statement" "for_statement" "while_statement" "try_statement"];
        exclude = [];
      };
    };
  };
}
