# Completion and Snippets Configuration
{ ... }: {
  programs.nixvim.plugins = {
    # Modern completion with blink-cmp
    blink-cmp = {
      enable = true;
      settings = {
        keymap = {
          preset = "super-tab";
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
  };
}
