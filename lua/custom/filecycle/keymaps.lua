---@module 'custom.filecycle.keymaps'
require("custom.filecycle.@types")

local core = require("custom.filecycle.core")
local map = require("lib.map")

local M = {}

---@param opts FileCycle.Config
---@return nil
function M.attach(opts)
  -- Next file with count support
  map("n", "<leader>nf", function()
    local count = vim.v.count1  -- Get count from vim (default: 1)
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      core.navigate(dir, "next", opts, count)
    end
  end, { desc = "[filecycle] Next file(s) in directory", silent = true })

  -- Previous file with count support
  map("n", "<leader>pf", function()
    local count = vim.v.count1  -- Get count from vim (default: 1)
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      core.navigate(dir, "prev", opts, count)
    end
  end, { desc = "[filecycle] Previous file(s) in directory", silent = true })
end

return M
