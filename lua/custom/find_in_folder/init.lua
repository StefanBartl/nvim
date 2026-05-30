---@module 'custom.find_in_folder'
---@brief Find files in a selected or given folder using Telescope or fzf-lua.
---@description
--- Entry point for the find_in_folder feature.
---
--- Setup (call once from your init.lua or mappings module):
--- ```lua
--- require("custom.find_in_folder").setup()
--- ```
---
--- This registers:
---   • <leader>fb  – interactive: pick folder, then fuzzy-find
---   • :FindInFolder [path] [telescope|fzf]
---
--- Programmatic use:
--- ```lua
--- require("custom.find_in_folder").run({ folder = "~/projects/myapp", picker = "fzf" })
--- require("custom.find_in_folder").run({ folder = "." })   -- CWD with Telescope
--- require("custom.find_in_folder").run({})                 -- full interactive flow
--- ```

local M = {}

---Setup keymaps and user command.
---@param opts? { keymaps?: boolean, usercmds?: boolean }
function M.setup(opts)
  opts = opts or {}
  local do_keymaps  = opts.keymaps  ~= false
  local do_usercmds = opts.usercmds ~= false

  if do_keymaps then
    require("custom.find_in_folder.keymaps").setup()
  end

  if do_usercmds then
    require("custom.find_in_folder.usercmds").setup()
  end
end

---Direct programmatic entry (no setup required).
---@param opts FindInFolder.Opts|nil
function M.run(opts)
  require("custom.find_in_folder.core").run(opts)
end

return M
