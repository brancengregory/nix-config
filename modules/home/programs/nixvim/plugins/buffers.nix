# Buffer Tab Line (bufferline.nvim)
{ ... }: {
  programs.nixvim.plugins.bufferline = {
    enable = true;
    settings = {
      options = {
        mode = "buffers";
        numbers = "none";
        close_command = "bdelete! %d";
        right_mouse_command = null;
        left_mouse_command = "buffer %d";
        middle_mouse_command = null;
        indicator = {
          icon = "▎";
          style = "icon";
        };
        buffer_close_icon = "";  # No close button
        modified_icon = "●";
        close_icon = "";
        left_trunc_marker = "";
        right_trunc_marker = "";
        max_name_length = 18;
        max_prefix_length = 15;
        truncate_names = true;
        tab_size = 18;
        diagnostics = "nvim_lsp";
        diagnostics_update_on_event = true;
        diagnostics_indicator.__raw = ''
          function(count, level)
            local icon = level:match("error") and " " or level:match("warning") and " " or " "
            return " " .. icon .. count
          end
        '';
        offsets = [
          {
            filetype = "neo-tree";
            text = "File Explorer";
            text_align = "center";
            separator = true;
          }
        ];
        color_icons = true;
        show_buffer_icons = true;
        show_buffer_close_icons = false;  # No x button on tabs
        show_close_icon = true;
        show_tab_indicators = true;
        show_duplicate_prefix = true;
        duplicates_across_groups = true;
        persist_buffer_sort = true;
        move_wraps_at_ends = true;
        separator_style = "slant";
        enforce_regular_tabs = false;
        always_show_bufferline = true;
        hover = {
          enabled = true;
          delay = 200;
          reveal = ["close"];
        };
        sort_by = "insert_after_current";
      };
    };
  };
}
