---@module 'lsp.core.diagnostics'
---@class DiagnosticsPolicy
local M = {}

---Unified diagnostic visuals: only virtual_lines for current line, no virtual_text.
---@return nil
function M.setup()
  vim.diagnostic.config({
    underline = true,
    update_in_insert = false,
    severity_sort = true,

    -- Nur virtuelle Zeilen unter der aktuellen Cursor-Zeile
    virtual_lines = { only_current_line = true },

    -- Inline-Virtual-Text ausschalten, um Doppelungen zu vermeiden
    virtual_text = false,

    -- Gutter-Signs bleiben an (kann man auch deaktivieren, wenn man’s ruhiger will)
    signs = true,

    -- Schöne Floats für K/Hover
    float = {
      focusable = true,
      style = "minimal",
      border = "rounded",
      source = "if_many",
    },
  })

  -- Optional: Gutter-Symbole vereinheitlichen
  local Signs = { Error = "■", Warn = "■", Info = "□", Hint = "·" }
  for k, v in pairs(Signs) do
    local hl = "DiagnosticSign" .. k
    vim.fn.sign_define(hl, { text = v, texthl = hl, numhl = "" })
  end
end

return M
