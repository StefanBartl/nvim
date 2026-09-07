---@module 'plugins.experimental'
--- Plugins currently in test phase

---@type LazyPluginSpec[]
return {
  {
    "dstein64/vim-startuptime",
    lazy = false,
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
