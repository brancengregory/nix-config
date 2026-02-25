# Git Integration (Gitsigns)
{ ... }: {
  programs.nixvim.plugins.gitsigns = {
    enable = true;
    settings = {
      signs = {
        add = { text = "+"; };
        change = { text = "~"; };
        delete = { text = "_"; };
        topdelete = { text = "‾"; };
        changedelete = { text = "~"; };
      };
      current_line_blame = false;
      current_line_blame_opts = {
        virt_text = true;
        virt_text_pos = "eol";
        delay = 500;
      };
      on_attach.__raw = ''
        function(bufnr)
          local gs = package.loaded.gitsigns
          
          -- Navigation
          vim.keymap.set('n', ']g', function()
            if vim.wo.diff then return ']g' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, {expr=true, buffer=bufnr})
          
          vim.keymap.set('n', '[g', function()
            if vim.wo.diff then return '[g' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, {expr=true, buffer=bufnr})
          
          -- Actions
          vim.keymap.set({"n", "v"}, "<leader>hs", ":Gitsigns stage_hunk<CR>", {buffer=bufnr})
          vim.keymap.set({"n", "v"}, "<leader>hr", ":Gitsigns reset_hunk<CR>", {buffer=bufnr})
          vim.keymap.set("n", "<leader>hS", gs.stage_buffer, {buffer=bufnr})
          vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, {buffer=bufnr})
          vim.keymap.set("n", "<leader>hR", gs.reset_buffer, {buffer=bufnr})
          vim.keymap.set("n", "<leader>hp", gs.preview_hunk, {buffer=bufnr})
          vim.keymap.set("n", "<leader>hb", function() gs.blame_line{full=true} end, {buffer=bufnr})
          vim.keymap.set("n", "<leader>hd", gs.diffthis, {buffer=bufnr})
        end
      '';
    };
  };
}
