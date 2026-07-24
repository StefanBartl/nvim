---@module 'plugins.experimental'
--- Plugins curently in test phase

---@type LazyPluginSpec[]
return {
  {
    "dstein64/vim-startuptime",
    lazy = false,
  },

  {
    "dhruvasagar/vim-table-mode",
    -- Lädt das Plugin nur bei diesen Befehlen oder Dateitypen
    cmd = { "TableModeToggle", "Tableize" },
    ft = { "markdown", "rst" },
    init = function()
      -- Hier kannst du Vim-Variablen definieren, BEVOR das Plugin geladen wird.
      -- Beispiel: Markdown-kompatible Ecken aktivieren (falls nötig)
      vim.g.table_mode_corner = "|"
    end,
  },
}
