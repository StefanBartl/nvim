---@module 'config.neotree.window.highlight'

---@class Cfg.NeoTree.Window.HL
---@field isolate_hl? boolean

local M = {}

-- Setze Neo-tree Highlights so, dass sie andere Fenster nicht beeinflussen
local function isolate_hl()
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { link = "Normal" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { link = "NormalNC" })
  vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { link = "EndOfBuffer" })
end

---@param opts Cfg.NeoTree.Window.HL
---@return nil
function M.setup(opts)
  opts = opts or {}

  if not opts.isolate_hl == false then
    isolate_hl()
  end
end

return M
