{isDarwin, ...}: {
  # Ghostty configuration with cross-platform templates
  # Based on chezmoi: private_dot_config/ghostty/config
  home.file.".config/ghostty/config".text =
    if isDarwin
    then ''
      font-size = 16
      font-family = "Fira Code Nerd Font"
      theme = "Snazzy"
      window-padding-x = 8
      window-decoration = true
      clipboard-read = allow
      clipboard-write = allow
      clipboard-trim-trailing-spaces = true
      keybind = shift+enter=text:\n
      term = xterm-256color
    ''
    else ''
      font-family = "Fira Code Nerd Font"
      theme = "Snazzy"
      window-padding-x = 8
      window-decoration = true
      clipboard-read = allow
      clipboard-write = allow
      clipboard-trim-trailing-spaces = true
      keybind = shift+enter=text:\n
      term = xterm-256color
    '';
}
