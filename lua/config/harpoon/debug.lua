---@module 'config.harpoon.debug'
--- Minimal observability for Harpoon state: dump the current items into a
--- scratch buffer. Exposed as `:Harpoon debug` (config.harpoon.usrcmds).

local M = {}

local path_shorten = require("lib.nvim.fs.path_shorten")
local bo = vim.bo
local nvim_buf_set_lines = vim.api.nvim_buf_set_lines

---@return string[]
local function collect_lines()
  local lines ---@type string[]
  lines = {}

  local ok, harpoon = pcall(require, "harpoon")
  if not ok then
    lines[#lines + 1] = "[harpoon] not available"
    return lines
  end

  local list = harpoon:list()
  lines[#lines + 1] = string.format("Items: %d", type(list.items) == "table" and #list.items or 0)

  if type(list.items) == "table" then
    for i = 1, #list.items do
      local it = list.items[i]
      local v = type(it) == "table" and it.value or tostring(it)
      lines[#lines + 1] = string.format("%3d  %s", i, path_shorten(v, nil, { style = "label" }))
    end
  end
  return lines
end

---Dump the current Harpoon items into a throwaway scratch buffer.
---@return nil
function M.dump()
  local out = collect_lines()
  vim.cmd("new")
  nvim_buf_set_lines(0, 0, -1, false, out)
  bo.buftype = "nofile"
  bo.bufhidden = "wipe"
  bo.swapfile = false
  vim.bo.modifiable = false
end

return M
