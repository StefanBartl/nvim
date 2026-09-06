---@module 'bindings.mappings.treesitter_structure'
---@brief Climb out of the structure the cursor is in: `[u` to its head, `]u`
---@brief to its end, repeatable. `u` = "up and out".
---@description
--- Thin wrapper over nvim-treesitter-textobjects' `move` module: "previous
--- start" of `@block.outer` is the enclosing node's head, so repeating the
--- motion climbs. The shipped `@block.outer` misses Lua table constructors
--- and JSON (no `block` node), so `after/queries/<lang>/textobjects.scm`
--- extends the same capture — lua/json/python/rust/toml/yaml so far. Details:
--- wkdbook-Neovim/MyNotes/treesitter-textobjects-block-outer-erweitern.md.
---
--- Off: `["nvim-treesitter-textobjects"] = "disabled"` in
--- `plugins/treesitter.lua`'s `modes` (binds nothing), or
--- `setup({ enable = false })` in `bindings/mappings/init.lua` (just these keys).
---
--- Key choice `[u`/`]u`: `[b`/`]b` is a Neovim 0.12 default. See the bracket-
--- pair inventory in docs/NOTES/CrossPlugin/Keymaps-Collisions.md.
---
---@see plugins.treesitter

local M = {}

--- Captures that count as "a structure you can be inside". `@block.outer` is
--- the shipped one, extended per language in `after/queries`.
---@type string[]
local CAPTURES = { "@block.outer" }

---@class Bindings.TreesitterStructure.Opts
---@field enable? boolean # false binds nothing. Default true.
---@field keys? { up?: string|false, down?: string|false } # false drops one direction.

---@type { up: string, down: string }
local DEFAULT_KEYS = { up = "[u", down = "]u" }

---@internal
--- Is the motion actually available? Checked once, at setup, rather than per
--- keypress: if the plugin is switched off in the spec, the honest outcome is
--- an unbound key, not a key that answers with a complaint.
---@return boolean
local function available()
  return (pcall(require, "nvim-treesitter-textobjects.move"))
end

---@param opts Bindings.TreesitterStructure.Opts|nil
---@return boolean bound # false when nothing was mapped, and why is on the caller.
function M.setup(opts)
  opts = opts or {}
  if opts.enable == false then
    return false
  end
  if not available() then
    return false
  end

  local map = require("lib.nvim.bindings.keymap")
  local keys = vim.tbl_extend("force", DEFAULT_KEYS, opts.keys or {})

  --- `move` is required per keypress, not held from `available()`: the check
  --- above proves it loads, and re-requiring is a table lookup once it is in
  --- `package.loaded`.
  ---@param fn "goto_previous_start"|"goto_next_end"
  ---@return fun(): nil
  local function go(fn)
    return function()
      require("nvim-treesitter-textobjects.move")[fn](CAPTURES, "textobjects")
    end
  end

  if keys.up then
    map(
      { "n", "x", "o" },
      keys.up,
      go("goto_previous_start"),
      { desc = "Jump to the head of the enclosing structure (repeatable)" }
    )
  end
  if keys.down then
    map(
      { "n", "x", "o" },
      keys.down,
      go("goto_next_end"),
      { desc = "Jump to the end of the enclosing structure (repeatable)" }
    )
  end

  return true
end

return M
