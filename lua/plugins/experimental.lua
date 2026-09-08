---@module 'plugins.experimental'
--- Plugins currently in test phase

---@type LazyPluginSpec[]
return {
  {
    "dstein64/vim-startuptime",
    -- A startup profiler that loaded itself at startup. Its `plugin/
    -- startuptime.vim` defines exactly one command, so that command is the
    -- trigger -- and the profiler stops being part of what it measures.
    cmd = "StartupTime",
  },

  {
    "dhruvasagar/vim-table-mode",
    -- Loads the plugin only for these commands or filetypes
    cmd = { "TableModeToggle", "Tableize" },
    ft = { "markdown", "rst" },
    init = function()
      -- Vim globals defined here run BEFORE the plugin loads.
      -- Markdown-compatible corners:
      vim.g.table_mode_corner = "|"
    end,
  },
}
