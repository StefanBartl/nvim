---@module 'config.filetree'
---@brief Shared filetree.nvim configuration.
---@description
--- Single source of truth for the filetree.nvim options.  Used in two places:
---   1. plugins/neotree.lua  → require("filetree").attach(opts, require("config.filetree"))
---      injects these feature keymaps into neo-tree's window.mappings BEFORE
---      neo-tree.setup(opts), so they appear in the `?` cheatsheet.
---   2. plugins/personal/init.lua (filetree spec) → require("filetree").setup(require("config.filetree"))
---      actually enables the features.
---
--- Keep both call sites pointed at this table so the cheatsheet and the live
--- keymaps never drift apart.

---@type FiletreeConfig
return {
  adapter = "neotree",

  -- Noop neotree's built-in `i` (run_command) so shell_run can use it
  adapter_keymaps = { ["i"] = false },

  features = {
    -- Core
    picker       = { enabled = true },
    layout_guard = { enabled = true },

    -- Ersetzt entfernte neotree-Module ──────────────────────────────────
    -- mark → marks
    marks = {
      enabled           = true,
      keymap            = "m",
      keymap_all        = "]m",
      keymap_unmark_all = "[m",
      keymap_clear      = "<C-m>",
      keymap_show       = "<leader>ms",
    },
    -- navigation → tree_traverse
    tree_traverse = {
      enabled     = true,
      keymap_up   = "-",
      keymap_down = "+",
      sync_cwd    = true,
    },
    -- path → path_copy
    path_copy = {
      enabled     = true,
      keymap_abs  = "[a",
      keymap_rel  = "]a",
      keymap_pick = "<leader>yp",
      keymap_name = "<leader>yn",
    },
    -- info → node_info
    node_info = {
      enabled    = true,
      keymap     = "I",
      show_lines = true,
    },
    -- preview / images / pdfport → preview
    preview = {
      enabled     = true,
      keymap      = "<Tab>",
      keymap_open = "<CR>",
      max_lines   = 40,
      image = { backend = "auto" },
      pdf   = { backend = "pdfport" },
    },
    -- filter → filter
    filter = {
      enabled = true,
      keymap  = "/",
      hl_dim  = "Comment",
    },
    -- search → live_search
    live_search = {
      enabled          = true,
      keymap           = "gs",
      commit_to_filter = true,
    },
    -- save → buffer_save
    buffer_save = {
      enabled         = true,
      keymap_adjacent = "<C-s>",
      keymap_node     = "<M-s>",
      force           = true,
    },
    -- replace → open_replace
    open_replace = {
      enabled = true,
      keymap  = "O",
    },
    -- find_or_grep_menu
    find_or_grep_menu = {
      enabled = true,
      keymap  = "<M-p>",
      prefer  = "auto",
    },

    -- Extras ─────────────────────────────────────────────────────────────
    current_hl = {
      enabled     = true,
      file_hl     = "CursorLine",
      parent_hl   = "Visual",
      debounce_ms = 100,
    },
    copy_file_list = {
      enabled          = true,
      keymap_files_abs = "[f",
      keymap_files_rel = "]f",
      keymap_dirs_abs  = "[F",
      keymap_dirs_rel  = "]F",
    },
    window_size_cycler = {
      enabled = true,
      keymap  = "w",
      sizes   = { 35, 55, 18 },
    },
    open_in_fm = {
      enabled = true,
      keymap  = "<leader>fm",
    },
    shell_run = {
      enabled     = true,
      keymap      = "i",   -- neotree's `i` nooped via adapter_keymaps above
      close_on_ok = true,
    },
  },
}
