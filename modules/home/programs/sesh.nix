{
  pkgs,
  ...
}: {
  # Sesh configuration for tmux session management
  home.packages = with pkgs; [
    sesh
  ];

  home.file.".config/sesh/sesh.toml".text = ''
    [[session]]
    name = "home"
    path = "~"
    startup_command = "l"

    [[session]]
    name = "tmux"
    path = "~"
    startup_command = "nvim -c ':e .tmux.conf'"

    [[session]]
    name = "nvim"
    path = "~/.config/nvim/"
    startup_command = "nvim -c ':Telescope find-files'"

    [[session]]
    name = "tic"
    path = "~/.local/share/com.nesbox.tic/TIC-80/commiemami/"
    startup_command = "nvim"
  '';

  # Add sesh shell alias
  programs.zsh.shellAliases = {
    s = "sesh cn .";
    h = "sesh cn home";
  };
}