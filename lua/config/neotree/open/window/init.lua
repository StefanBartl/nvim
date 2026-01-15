---@module 'config.neotree.open.window'
---@brief Neo-tree window keymaps using centralized controller

local map = require("lib.map")

local M = {}

---@param opts? table
---@return nil
function M.attach_opener_mappings(opts)
  opts = opts or {}

  local specs = {
    { lhs = "<A-c>", pos = "current", desc = "[Neo-tree] Toggle window (current)" },
    { lhs = "<A-f>", pos = "float", desc = "[Neo-tree] Toggle window (float)" },
    { lhs = "<A-l>", pos = "left", desc = "[Neo-tree] Toggle window (left)" },
    { lhs = "<A-r>", pos = "right", desc = "[Neo-tree] Toggle window (right)" },
  }

  local opener_factory

  if opts.debug then
    opener_factory = require("config.neotree.open.window.measuring").make_opener
  else
    opener_factory = require("config.neotree.open.window.controller").make_opener
  end

  for i = 1, #specs do
    local s = specs[i]
    map("n", s.lhs, opener_factory(s.pos), {
      desc = s.desc,
      silent = true,
    })
  end

end

return M
