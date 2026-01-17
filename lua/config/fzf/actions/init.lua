---@module 'config.fzf.actions'
---@description Centralized fzf-lua custom actions
---
--- Provides two main custom actions:
--- 1. ctrl-a: Create file/folder in current entry's directory
--- 2. shift-enter / ctrl-o: Open file in background buffer
---
--- Integration in fzf config:
--- ```lua
--- local custom_actions = require("config.fzf.actions")
---
--- actions = custom_actions.get()
--- ```

local M = {}

local create_file = require("config.fzf.actions.create_file")
local open_badd = require("config.fzf.actions.open_badd")

---Get all custom actions for fzf-lua
---@return table actions Action callbacks for fzf-lua
function M.get()
  return {
    ["ctrl-a"] = {
      fn = create_file.create_file,
      desc = "create file/folder in current directory",
    },
    ["shift-enter"] = {
      fn = open_badd.open_badd,
      desc = "open file in background buffer",
    },
  }
end

return M
