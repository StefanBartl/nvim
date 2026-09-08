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

---Toggle Neo-tree at `position`, self-healing the E95 buffer-name-collision
---race: firing this mapping again before Neo-tree's own (debounced)
---`filesystem_navigate` scan from a PREVIOUS toggle has settled — easiest to
---hit as a keypress that lands right after startup, before Neo-tree is done
---initializing — makes `nvim_buf_set_name` collide inside
---`renderer.lua`'s `acquire_window()` (Vim:E95: Buffer with this name
---already exists). Left alone, that leaves a permanently blank, unfocusable
----except-broken "neo-tree" window on screen that re-errors on every
---redraw; the previously known workaround was pressing the mapping again,
---which opened a second, working window next to the dead one. This does
---that recovery automatically: on failure, close any window still showing
---an unnamed (never successfully rendered) neo-tree buffer, then retry once.
---@param position "current"|"float"|"left"|"right"
---@return nil
local function toggle(position)
  local commands = require("neo-tree.command")
  local opts = {
    toggle = true,
    position = position,
    reveal = true,
    reveal_force_cwd = true,
  }
  local ok, err = pcall(commands.execute, opts)
  if ok then
    return
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" and vim.api.nvim_buf_get_name(buf) == "" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  local retry_ok = pcall(commands.execute, opts)
  if not retry_ok then
    vim.notify("[Neo-tree] toggle failed: " .. tostring(err), vim.log.levels.WARN)
  end
end

---Attach Neo-tree opener mappings.
---Mappings directly call the standard Neo-tree command with a custom lhs.
---@return nil
function M.attach()
  map("n", "<M-c>", function()
    toggle("current")
  end, {
    desc = "[Neo-tree] Toggle window (current)",
    silent = true,
    noremap = true,
  })

  map("n", "<M-f>", function()
    toggle("float")
  end, {
    desc = "[Neo-tree] Toggle window (float)",
    silent = true,
    noremap = true,
  })

  map("n", "<M-l>", function()
    toggle("left")
  end, {
    desc = "[Neo-tree] Toggle window (left)",
    silent = true,
    noremap = true,
  })

  map("n", "<M-r>", function()
    toggle("right")
  end, {
    desc = "[Neo-tree] Toggle window (right)",
    silent = true,
    noremap = true,
  })
end

return M
