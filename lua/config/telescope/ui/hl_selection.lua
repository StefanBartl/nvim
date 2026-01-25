---@module 'config.telescope.ui.hl_selection'
--- Sets custom highlight for Telescope selection

local notify = require("lib.notify").create("[config.telescope.ui.hl_selection]")

local M = {}

--- Set TelescopeSelection highlight
--- @return boolean success
function M.setup()
  local ok, err = pcall(vim.api.nvim_set_hl, 0, "TelescopeSelection", {
    fg = "#ffffff",
    bg = "#1abc9c",
    bold = true,
    ctermfg = 15,
    ctermbg = 24,
  })

  if not ok then
    notify.warn(string.format("Failed to set TelescopeSelection highlight: %s", err))
    return false
  end
  return true
end

return M
