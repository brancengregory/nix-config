# Navigation Plugins (Telescope, Harpoon)
{ pkgs, ... }: {
  programs.nixvim.plugins = {
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

    # Harpoon
    harpoon = {
      enable = true;
      package = pkgs.vimPlugins.harpoon2;
    };
  };
}
