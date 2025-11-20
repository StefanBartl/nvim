---@module 'lsp.core.diagnostics'

---@class DiagnosticsPolicy
local M = {}

--- Unified diagnostic visuals:
--- - virtual_lines nur für die aktuelle Zeile
--- - virtual_text aus
--- - moderne Sign-Konfiguration (Neovim 0.10+), Fallback für ältere Versionen
---@return nil
function M.setup()
  local use_modern_signs = vim.fn.has("nvim-0.10") == 1

  -- Common diagnostic config
  vim.diagnostic.config({
    underline = true,
    update_in_insert = false,
    severity_sort = true,

    -- -virtual_lines = { only_current_line = true },
    virtual_text = true,

    -- Modern sign configuration (no deprecated sign_define)
    signs = use_modern_signs
        and {
          -- You can use Nerd Font icons or simple ASCII
          text = {
            ERROR = "■",
            WARN = "■",
            INFO = "□",
            HINT = "·",
          },
          -- Optional: highlight groups; omit to use defaults
          -- numhl = {
          --   ERROR = "DiagnosticSignError",
          --   WARN  = "DiagnosticSignWarn",
          --   INFO  = "DiagnosticSignInfo",
          --   HINT  = "DiagnosticSignHint",
          -- },
        }
      or true, -- keep signs enabled on older Neovim; icons set below via sign_define

    float = {
      focusable = true,
      style = "minimal",
      border = "rounded",
      source = "if_many",
    },
  })

  -- Backward compat: only define legacy signs if Neovim < 0.10
  if not use_modern_signs then
    ---@type table<string,string>
    local Signs = { Error = "■", Warn = "■", Info = "□", Hint = "·" }
    for k, v in pairs(Signs) do
      local hl = "DiagnosticSign" .. k
      -- Using sign_define only on old Neovim avoids the deprecation warning on 0.10+
      vim.fn.sign_define(hl, { text = v, texthl = hl, numhl = "" })
    end
  end
end

return M
