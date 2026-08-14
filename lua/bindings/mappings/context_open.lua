---@module 'bindings.mappings.context_open'
--- Keymaps for `bindings.usrcmds.context_open` -- see that module's README.

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<M-o>", function()
    require("bindings.usrcmds.context_open").open()
  end, { desc = "[Open] Open whatever is under the cursor" })

  map("n", "<M-O>", function()
    require("bindings.usrcmds.context_open").list()
  end, { desc = "[Open] List every openable target in the buffer" })
end

return M
