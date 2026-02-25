# Nixvim Keymaps - Deduplicated and Organized
# Note: Window navigation (Ctrl+h/j/k/l) is handled by tmux-navigator plugin
{ ... }: {
  programs.nixvim.keymaps = [
    # Core mappings
    {
      mode = "n";
      key = "<leader>pv";
      action = "<cmd>Ex<cr>";
    }
    {
      mode = "n";
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<cr>";
    }

    # File operations under <leader>f
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<cr>";
      options.desc = "Find files";
    }
    {
      mode = "n";
      key = "<leader>fr";
      action = "<cmd>Telescope oldfiles<cr>";
      options.desc = "Recent files";
    }
    {
      mode = "n";
      key = "<leader>fn";
      action = "<cmd>enew<cr>";
      options.desc = "New file";
    }
    {
      mode = "n";
      key = "<leader>fW";
      action = ":w ";
      options.desc = "Write as (name file)";
    }
    {
      mode = "n";
      key = "<leader>fj";
      action = "<cmd>e #<cr>";
      options.desc = "Last file (alternate)";
    }
    {
      mode = "n";
      key = "<leader>fs";
      action = "<cmd>w<cr>";
      options.desc = "Save file";
    }
    {
      mode = "n";
      key = "<leader>fS";
      action = "<cmd>wa<cr>";
      options.desc = "Save all";
    }
    {
      mode = "n";
      key = "<leader>fh";
      action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<cr>";
      options.desc = "Harpoon quick menu";
    }
    {
      mode = "n";
      key = "<leader>fa";
      action = "<cmd>lua require('harpoon'):list():append()<cr>";
      options.desc = "Add to Harpoon";
    }

    # Buffer operations under <leader>b
    {
      mode = "n";
      key = "<leader>bb";
      action = "<cmd>Telescope buffers<cr>";
      options.desc = "List buffers";
    }
    {
      mode = "n";
      key = "<leader>bl";
      action = "<cmd>e #<cr>";
      options.desc = "Last buffer";
    }
    {
      mode = "n";
      key = "<leader>bn";
      action = "<cmd>bnext<cr>";
      options.desc = "Next buffer";
    }
    {
      mode = "n";
      key = "<leader>bp";
      action = "<cmd>bprev<cr>";
      options.desc = "Prev buffer";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bd<cr>";
      options.desc = "Delete buffer";
    }

    # Legacy Telescope - DEDUPLICATED (removed duplicates: <leader>pf, <leader>pb)
    {
      mode = "n";
      key = "<C-p>";
      action = "<cmd>Telescope git_files<cr>";
    }
    {
      mode = "n";
      key = "<leader>ps";
      action = "<cmd>Telescope live_grep<cr>";
    }
    {
      mode = "n";
      key = "<leader>ph";
      action = "<cmd>Telescope help_tags<cr>";
    }

    # Harpoon
    {
      mode = "n";
      key = "<leader>ha";
      action = "<cmd>lua require('harpoon'):list():append()<cr>";
      options.desc = "Add file";
    }
    {
      mode = "n";
      key = "<leader>hh";
      action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<cr>";
      options.desc = "Quick menu";
    }
    {
      mode = "n";
      key = "<leader>h1";
      action = "<cmd>lua require('harpoon'):list():select(1)<cr>";
      options.desc = "File 1";
    }
    {
      mode = "n";
      key = "<leader>h2";
      action = "<cmd>lua require('harpoon'):list():select(2)<cr>";
      options.desc = "File 2";
    }
    {
      mode = "n";
      key = "<leader>h3";
      action = "<cmd>lua require('harpoon'):list():select(3)<cr>";
      options.desc = "File 3";
    }
    {
      mode = "n";
      key = "<leader>h4";
      action = "<cmd>lua require('harpoon'):list():select(4)<cr>";
      options.desc = "File 4";
    }

    # LSP
    {
      mode = "n";
      key = "gd";
      action = "<cmd>lua vim.lsp.buf.definition()<cr>";
    }
    {
      mode = "n";
      key = "gr";
      action = "<cmd>lua vim.lsp.buf.references()<cr>";
    }
    {
      mode = "n";
      key = "gI";
      action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
    }
    {
      mode = "n";
      key = "<leader>D";
      action = "<cmd>lua vim.lsp.buf.type_definition()<cr>";
    }
    {
      mode = "n";
      key = "<leader>rn";
      action = "<cmd>lua vim.lsp.buf.rename()<cr>";
    }
    {
      mode = "n";
      key = "<leader>ca";
      action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
    }
    {
      mode = "n";
      key = "K";
      action = "<cmd>lua vim.lsp.buf.hover()<cr>";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
    }

    # Git (now under <leader>g group)
    {
      mode = "n";
      key = "<leader>gs";
      action = "<cmd>Git<cr>";
      options.desc = "Git status";
    }
    {
      mode = "n";
      key = "<leader>gc";
      action = "<cmd>Git commit<cr>";
      options.desc = "Git commit";
    }
    {
      mode = "n";
      key = "<leader>gp";
      action = "<cmd>Git push<cr>";
      options.desc = "Git push";
    }

    # Comment.nvim mappings (Ctrl+/ for line, Ctrl+Shift+/ for block)
    {
      mode = ["n" "i"];
      key = "<C-/>";
      action = "<cmd>lua require('Comment.api').toggle.linewise.current()<cr>";
      options.desc = "Toggle line comment";
    }
    {
      mode = "v";
      key = "<C-/>";
      action = "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>";
      options.desc = "Toggle line comment (visual)";
    }
    {
      mode = ["n" "i"];
      key = "<C-?>";
      action = "<cmd>lua require('Comment.api').toggle.blockwise.current()<cr>";
      options.desc = "Toggle block comment";
    }
    {
      mode = "v";
      key = "<C-?>";
      action = "<esc><cmd>lua require('Comment.api').toggle.blockwise(vim.fn.visualmode())<cr>";
      options.desc = "Toggle block comment (visual)";
    }

    # Gitsigns navigation
    {
      mode = "n";
      key = "]g";
      action = "<cmd>lua require('gitsigns').next_hunk()<cr>";
      options.desc = "Next git hunk";
    }
    {
      mode = "n";
      key = "[g";
      action = "<cmd>lua require('gitsigns').prev_hunk()<cr>";
      options.desc = "Previous git hunk";
    }

    # Trouble diagnostics
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<cr>";
      options.desc = "Diagnostics (Trouble)";
    }
    {
      mode = "n";
      key = "<leader>xd";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
      options.desc = "Buffer diagnostics";
    }

    # Neo-tree file browser
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<cr>";
      options.desc = "Toggle file tree";
    }
    {
      mode = "n";
      key = "<leader>o";
      action = "<cmd>Neotree focus<cr>";
      options.desc = "Focus file tree";
    }

    # R.nvim keybindings (R development)
    {
      mode = "n";
      key = "<leader>rf";
      action = "<cmd>lua require('r.send').source_file()<cr>";
      options.desc = "R: Send file";
    }
    {
      mode = "n";
      key = "<leader>rl";
      action = "<cmd>lua require('r.send').line()<cr>";
      options.desc = "R: Send line";
    }
    {
      mode = "v";
      key = "<leader>rs";
      action = "<cmd>lua require('r.send').selection()<cr>";
      options.desc = "R: Send selection";
    }
    {
      mode = "n";
      key = "<leader>ro";
      action = "<cmd>lua require('r.browser').start()<cr>";
      options.desc = "R: Show objects";
    }
    {
      mode = "n";
      key = "<leader>rr";
      action = "<cmd>lua require('r.run').start_R('R')<cr>";
      options.desc = "R: Start R";
    }

    # Bufferline navigation (Tab / Shift+Tab)
    {
      mode = "n";
      key = "<Tab>";
      action = "<cmd>BufferLineCycleNext<cr>";
      options.desc = "Next buffer";
    }
    {
      mode = "n";
      key = "<S-Tab>";
      action = "<cmd>BufferLineCyclePrev<cr>";
      options.desc = "Previous buffer";
    }
    {
      mode = "n";
      key = "<leader>bp";
      action = "<cmd>BufferLinePick<cr>";
      options.desc = "Pick buffer";
    }
    {
      mode = "n";
      key = "<leader>bc";
      action = "<cmd>bdelete<cr>";
      options.desc = "Close buffer";
    }

    # Session management (auto-session)
    {
      mode = "n";
      key = "<leader>ss";
      action = "<cmd>SessionSearch<cr>";
      options.desc = "Search sessions";
    }
    {
      mode = "n";
      key = "<leader>sd";
      action = "<cmd>SessionDelete<cr>";
      options.desc = "Delete session";
    }

    # Zen mode
    {
      mode = "n";
      key = "<leader>z";
      action = "<cmd>ZenMode<cr>";
      options.desc = "Toggle zen mode";
    }

    # Todo comments
    {
      mode = "n";
      key = "<leader>td";
      action = "<cmd>TodoTelescope<cr>";
      options.desc = "Find todos";
    }
    {
      mode = "n";
      key = "<leader>tq";
      action = "<cmd>TodoTelescope cwd=.<cr>";
      options.desc = "Find todos in current file";
    }
  ];
}
