---@module 'config.neotree.open.keymaps_only_ls'
---Neo-tree window keymaps using direct Neo-tree command execution.
---This module attaches normal-mode mappings that toggle Neo-tree
---in different window positions without any opener factory abstraction.

local map = require("lib.map")

local M = {}

---Attach Neo-tree opener mappings.
---Mappings directly call the standard Neo-tree command with a custom lhs.
---
---@return nil
function M.attach()
  map("n", "<M-c>", function()
    -- Toggle Neo-tree in the current window position.
    require("neo-tree.command").execute({
      toggle = true,
      position = "current",
    })
  end, {
    desc = "[Neo-tree] Toggle window (current)",
    silent = true,
    noremap = true,
  })

  map("n", "<M-f>", function()
    -- Toggle Neo-tree as a floating window.
    require("neo-tree.command").execute({
      toggle = true,
      position = "float",
    })
  end, {
    desc = "[Neo-tree] Toggle window (float)",
    silent = true,
    noremap = true,
  })

  map("n", "<M-l>", function()
    -- Toggle Neo-tree in a left-side vertical split.
    require("neo-tree.command").execute({
      toggle = true,
      position = "left",
    })
  end, {
    desc = "[Neo-tree] Toggle window (left)",
    silent = true,
    noremap = true,
  })

  map("n", "<M-r>", function()
    -- Toggle Neo-tree in a right-side vertical split.
    require("neo-tree.command").execute({
      toggle = true,
      position = "right",
    })
  end, {
    desc = "[Neo-tree] Toggle window (right)",
    silent = true,
    noremap = true,
  })
end

return M
