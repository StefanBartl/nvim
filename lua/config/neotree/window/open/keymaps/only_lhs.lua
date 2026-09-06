---@module 'config.neotree.window.open.keymaps.only_lhs'
---Neo-tree window keymaps using direct Neo-tree command execution.
---This module attaches normal-mode mappings that toggle Neo-tree
---in different window positions without any opener factory abstraction.

--- This module defines a minimal, explicit set of normal-mode keymaps that
--- directly call `neo-tree.command.execute()` without any abstraction layer.
--- The intent is to keep the behavior fully transparent and configurable
--- at the call site. Only `toggle`/`position`/`reveal`/`reveal_force_cwd` are
--- used below; for the full `execute()` options overview (`dir`, `source`,
--- `focus`, `find_file`, ...) see wkdbook-Neovim/MyNotes/
--- neotree-command-execute-options.md.

local map = require("lib.nvim.bindings.keymap")

local M = {}

---Attach Neo-tree opener mappings.
---Mappings directly call the standard Neo-tree command with a custom lhs.
---@return nil
function M.attach()
  map("n", "<M-c>", function()
    -- Toggle Neo-tree in the current window position.
    require("neo-tree.command").execute({
      toggle = true,
      position = "current",
      reveal = true,
      reveal_force_cwd = true,
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
      reveal = true,
      reveal_force_cwd = true,
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
      reveal = true,
      reveal_force_cwd = true,
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
      reveal = true,
      reveal_force_cwd = true,
    })
  end, {
    desc = "[Neo-tree] Toggle window (right)",
    silent = true,
    noremap = true,
  })
end

return M
