# LSP Configuration
{ pkgs, ... }: {
  programs.nixvim.plugins.lsp = {
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
}
