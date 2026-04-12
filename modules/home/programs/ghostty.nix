{...}: {
  # Ghostty configuration
  # Based on chezmoi: private_dot_config/ghostty/config
  home.file.".config/ghostty/config".text = ''
    font-family = "Fira Code Nerd Font"
    theme = "Snazzy"
    window-padding-x = 8
    window-decoration = true
    maximize = true
    clipboard-read = allow
    clipboard-write = allow
    clipboard-trim-trailing-spaces = true
    keybind = shift+enter=text:\n
    term = tmux-256color
    shell-integration = none
    initial-command = $SHELL -i -c h
  '';
}
