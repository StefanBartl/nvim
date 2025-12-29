---@module 'custom.filecycle.keymaps'
require("custom.filecycle.@types")

local core = require("custom.filecycle.core")
local map = require("lib.map")

local M = {}

---@param opts FileCycle.Config
---@return nil
function M.attach(opts)
  map("n", "<leader>nf", function()
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      core.navigate(dir, "next", opts)
    end
  end, { desc = "[filecycle] Next file in directory", silent = true })

  map("n", "<leader>pf", function()
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      core.navigate(dir, "prev", opts)
    end
  end, { desc = "[filecycle] Previous file in directory", silent = true })
end

return M
