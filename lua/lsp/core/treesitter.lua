---@module 'lsp.core.treesitter'
---@class TreesitterPolicy

local M = {}

---@return nil
function M.setup()
  local ok, ts = pcall(require, "nvim-treesitter.config")
  if not ok then
    return
  end
  ts.setup({
    highlight = { enable = true },
    indent = { enable = true },
  })
end

return M
