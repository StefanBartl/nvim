---@module 'mappings.lsp_signature'
--- Provides Insert- and Normal-mode mapping for LSP signature help / hover preview.
--- Toggle: <C-b>
--- - Normalmodus: Popup öffnet, Fokus direkt auf Floating-Window für Scroll/Copy
--- - Insertmodus: Popup öffnet, Fokus bleibt im Hauptbuffer, Insertmodus aktiv
--- - Popup persistent, Toggle zum Schließen

local M = {}

local schedule = vim.schedule
local request_and_show = require("custom.lsp_signature.request_and_show")
-- local request_and_show = require("custom.lsp_signature.request_and_show_manual")


function M.setup()
  -- Fallback-Keymap-Funktion
  local map = vim.g.__map_helper or function(modes, lhs, rhs, opts)
    vim.keymap.set(modes, lhs, rhs, opts)
  end

  -- <C-b> Toggle in Insert- und Normalmodus
  map({"i", "n"}, "<C-b>", function()
    -- Optional: Notification für Debugging
    -- vim.notify("LSP Signature Toggle", vim.log.levels.INFO)

    schedule(function()
      -- ruft das neue request_and_show auf
      request_and_show()
    end)
  end, {desc = "[LSP] Show signature or hover (floating toggle)", silent = true, noremap = true})
end

return M
