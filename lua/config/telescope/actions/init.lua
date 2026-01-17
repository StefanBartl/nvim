---@module 'config.telescope.actions'
---@description Centralized Telescope custom actions
---
--- Provides two main custom actions:
--- 1. <C-a>: Create file/folder in current entry's directory
--- 2. <S-CR> / <C-o>: Open file in background buffer
---
--- Integration in telescope config:
--- ```lua
--- local custom_actions = require("config.telescope.actions")
---
--- defaults = {
---   mappings = custom_actions.get_mappings()
--- }
--- ```

local M = {}

local create_file = require("config.telescope.actions.create_file")
local open_badd = require("config.telescope.actions.open_badd")

---Get all custom action mappings merged
---@return table mappings Combined mappings for insert and normal mode
function M.get_mappings()
  local create_maps = create_file.get_mappings()
  local badd_maps = open_badd.get_mappings()

  return vim.tbl_deep_extend("force", create_maps, badd_maps)
end

---Attach mappings function (for attach_mappings approach)
---@param prompt_bufnr integer
---@param map function
---@return boolean
function M.attach_mappings(prompt_bufnr, map)
  -- File creation
  map("i", "<C-a>", function()
    create_file.create_file(prompt_bufnr)
  end)
  map("n", "<C-a>", function()
    create_file.create_file(prompt_bufnr)
  end)

  -- Background buffer open
  map("i", "<S-CR>", function()
    open_badd.open_badd(prompt_bufnr)
  end)
  map("n", "<S-CR>", function()
    open_badd.open_badd(prompt_bufnr)
  end)
  return true
end

return M
