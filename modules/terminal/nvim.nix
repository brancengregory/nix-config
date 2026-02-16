{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    neovim
    gnumake
    gcc
    cmake
    pkg-config
    unzip
    luarocks
    # Common dependencies for nvim plugins
    ripgrep
    fd
  ];

  # Instead of symlinking the whole directory (which makes it read-only),
  # we symlink the core components. This allows lazy.nvim to create and
  # update lazy-lock.json in the ~/.config/nvim directory.
  xdg.configFile."nvim/init.lua".source = "${inputs.nvim-config}/init.lua";
  xdg.configFile."nvim/lua" = {
    source = "${inputs.nvim-config}/lua";
    recursive = true;
  };

  # Set Neovim as the default editor
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
