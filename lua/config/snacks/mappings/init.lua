---@module 'config.snacks.mappings.init'
--- Keymap definitions for folke/snacks.nvim.
--- Exposes keys() returning the array format expected by lazy.nvim plugin specs.

local M = {}

---@return table[]
function M.get_all_keys()
  ---@type table[]
  local keys = {}

  local standard = require("config.snacks.mappings.standard").keys()
  if type(standard) == "table" then
    vim.list_extend(keys, standard)
  end

  local ext = require("config.snacks.mappings.extended").keys()
  if type(ext) == "table" then
    vim.list_extend(keys, ext)
  end

  return keys
end

return M
