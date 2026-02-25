# Treesitter Configuration
{ ... }: {
  programs.nixvim.plugins.treesitter = {
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
}
