-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@class ChadrcConfig

local M = {}

M.ui = {
  statusline = {
    theme = "vscode",
  },
}

local _get_darken = false
function _G.toggle_background_transparent()
  if (not _get_darken) then
    vim.cmd("hi Normal guibg=#151515")
    _get_darken = true
  else
    vim.cmd("hi Normal guibg=NONE")
    _get_darken = false
  end
end

return M
