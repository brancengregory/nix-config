{pkgs, ...}: {
  # Sesh configuration for tmux session management
  home.packages = with pkgs; [
    sesh
  ];

  home.file.".config/sesh/sesh.toml".text = ''
    [[session]]
    name = "home"
    path = "~"

    [[session]]
    name = "nix"
    path = "~/code/brancengregory/nix-config/"
  '';

  # Add sesh shell alias
  programs.zsh.shellAliases = {
    s = "sesh cn .";
    h = "sesh cn home";
  };
}
