# Notification Integration (nvim-notify)
{ ... }: {
  programs.nixvim.plugins.notify = {
    enable = true;
    settings = {
      stages = "fade_in_slide_out";
      timeout = 3000;
      background_colour = "#000000";
      icons = {
        error = "";
        warn = "";
        info = "";
        debug = "";
        trace = "✎";
      };
      render = "default";
      top_down = true;
    };
  };
}
