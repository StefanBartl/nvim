---@type conform.setupOpts
local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    cs = { "csharpier" }, -- für C#-Dateien mit Endung .cs
    -- html = { "prettier" },
    -- css  = { "prettier" },
  },

  -- optional: automatisch beim Speichern formatieren
  format_on_save = {
    timeout_ms = 1000,
    lsp_fallback = true,
  },
}

return options

