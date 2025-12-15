---@module 'config.telescope.ui.hl_selection'
--- Sets custom highlight for Telescope selection

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
    vim.notify(
      string.format("Failed to set TelescopeSelection highlight: %s", err),
      vim.log.levels.WARN
    )
    return false
  end
  return true
end

return M
