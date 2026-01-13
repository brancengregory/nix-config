{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    neovim
  ];

  # Link the custom nvim configuration from the flake input
  home.file."./.config/nvim" = {
    source = inputs.nvim-config;
    recursive = true;
  };

  # Optional: Set Neovim as the default editor
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}