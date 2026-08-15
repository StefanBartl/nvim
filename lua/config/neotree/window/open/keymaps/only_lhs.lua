---@module 'config.neotree.window.open.keymaps.only_lhs'
---Neo-tree window keymaps using direct Neo-tree command execution.
---This module attaches normal-mode mappings that toggle Neo-tree
---in different window positions without any opener factory abstraction.

--- This module defines a minimal, explicit set of normal-mode keymaps that
--- directly call `neo-tree.command.execute()` without any abstraction layer.
--- The intent is to keep the behavior fully transparent and configurable
--- at the call site.
---
--- ------------------------------------------------------------------------
--- Common execute() options overview
--- ------------------------------------------------------------------------
---
--- toggle : boolean
--- When true, Neo-tree toggles visibility:
--- - if the window is already open at the given position, it will be closed
--- - otherwise, a new Neo-tree window is opened
--- If false or omitted, Neo-tree is always opened.
---
--- position : string
--- Controls where the Neo-tree window is opened.
--- Valid values:
--- "left" -> vertical split on the left side
--- "right" -> vertical split on the right side
--- "current" -> replaces the current window
--- "float" -> floating window
--- The position also implicitly selects the corresponding window layout.
---
--- reveal : boolean
--- When true, Neo-tree attempts to focus and reveal the current buffer's file
--- in the tree.
--- - If the file is inside the current working directory, it is highlighted.
--- - If the file is outside the cwd, Neo-tree may prompt for confirmation
--- unless `reveal_force_cwd` is set.
---
--- reveal_force_cwd : boolean
--- When true and `reveal = true`:
--- - if the file to be revealed is outside the current cwd
--- - Neo-tree automatically changes the cwd to the file's parent directory
--- - no confirmation dialog is shown
--- This option has global side effects and is therefore opt-in.
---
--- dir : string
--- Explicit root directory for the Neo-tree instance.
--- - Overrides the current cwd for this invocation
--- - Prevents cwd changes when revealing files outside the project
--- - If the revealed file is not under this directory, no reveal occurs
---
--- source : string
--- Selects the Neo-tree source to display.
--- Common values:
--- "filesystem" (default)
--- "buffers"
--- "git_status"
--- If omitted, the configured default source is used.
---
--- focus : boolean
--- When true, focus is moved to the Neo-tree window after opening.
--- When false, Neo-tree opens in the background.
--- Defaults depend on Neo-tree internal configuration.
---
--- find_file : boolean
--- Legacy alias for `reveal` in older Neo-tree versions.
--- Prefer `reveal` for clarity and forward compatibility.
---

local map = require("lib.nvim.map")

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
