# Diagnostics Integration (Trouble)
{...}: {
  programs.nixvim.plugins.trouble = {
    enable = true;
    settings = {
      auto_close = false;
      auto_preview = true;
      auto_refresh = true;
      focus = true;
      follow = true;
      icons = {
        indent = {
          fold_closed = "󰁔";
          fold_open = "󰁋";
          last = "└";
          middle = "├";
          top = "┌";
          ws = "│";
        };
        folder_closed = "󰉋";
        folder_open = "󰝰";
        kinds = {
          Array = "";
          Boolean = "";
          Class = "";
          Constant = "";
          Constructor = "";
          Enum = "";
          EnumMember = "";
          Event = "";
          Field = "";
          File = "";
          Function = "";
          Interface = "";
          Key = "";
          Method = "";
          Module = "";
          Namespace = "";
          Null = "";
          Number = "";
          Object = "";
          Operator = "";
          Package = "";
          Property = "";
          String = "";
          Struct = "";
          TypeParameter = "";
          Variable = "";
        };
        symbols = {
          error = "";
          hint = "";
          information = "";
          other = "󰠠";
          warning = "";
        };
      };
      indent_lines = true;
      modes = {
        diagnostics = {
          groups = ["other" "warning" "error" "information" "hint"];
          mode = "diagnostics";
          title = "Diagnostics";
        };
        symbols = {
          desc = "document symbols";
          focus = false;
          mode = "lsp_document_symbols";
          win = {
            position = "right";
            size = {
              width = 0.3;
            };
          };
        };
      };
      position = "bottom";
      severity = 7;
      warn_no_results = true;
    };
  };
}
