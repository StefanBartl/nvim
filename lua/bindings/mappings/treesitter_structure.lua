---@module 'bindings.mappings.treesitter_structure'
---@brief Climb out of the structure the cursor is in: `[u` to its head, `]u`
---@brief to its end, repeatable.
---@description
--- From line 40 of a nested configuration table, `[u` puts the cursor on the
--- head of the table that encloses it; press it again and you are one level
--- further out, until you reach the outermost one. `]u` does the same downward,
--- to the closing end. In a function it climbs `for` -> `if` -> `function`
--- instead, because those are the enclosing structures there.
---
--- `u` for "up and out"; the letter names the feature and the bracket names
--- the direction, the way `[d`/`]d` work.
---
--- **This is nvim-treesitter-textobjects' `move` module, not a feature written
--- here.** `goto_previous_start` walks to the nearest match *before* the
--- cursor, and the enclosing node's own head is exactly that -- so "previous
--- start" and "climb out one level" are the same motion, and repeating it
--- climbs. Nothing else was needed.
---
--- The plugin was installed and configured nowhere: `plugins/treesitter.lua`
--- lists it with `lazy = false` and never called into it, and nothing in
--- `lua/` referenced it. These two keys are the first use of it.
---
--- **What did need writing is one query line per language**, in
--- `after/queries/<lang>/textobjects.scm`. The shipped `@block.outer` is
--- `(_ (block)) @block.outer` -- function bodies, `if`, `for`, `while`. A Lua
--- table constructor is not a `block`, and JSON has no blocks at all, so the
--- case this motion exists for was the one case it could not reach. Those
--- files extend the same capture rather than adding a new one: "the thing I am
--- inside" is one idea, and one capture keeps the motion a single argument.
---
--- Languages covered so far: lua, json, python, rust, toml, yaml -- each node
--- name read off the real grammar rather than guessed, because an unknown node
--- name does not degrade, it makes the whole `textobjects` query for that
--- language fail to parse. Adding a language is one file; block languages
--- (go, c, typescript, …) already work for their blocks with no file at all.
---
--- **Two ways to switch this off**, at the two levels it can be unwanted:
---
--- * *The plugin*: set `["nvim-treesitter-textobjects"] = "disabled"` in
---   `plugins/treesitter.lua`'s `modes` table. This module then binds nothing
---   at all -- the keys stay free rather than being taken by a mapping that
---   only complains when pressed.
--- * *Just these keys*: `setup({ enable = false })` in
---   `bindings/mappings/init.lua`, or `setup({ keys = { … } })` to move them.
---   Use this when the plugin is wanted for something else.
---
--- **On the choice of key.** This was `[b`/`]b` for about an hour, on the
--- strength of a grep over `lua/` that found no such mapping. The grep was the
--- wrong instrument: `[b`/`]b`/`[B`/`]B` are Neovim 0.12's *own* defaults for
--- buffer navigation (`vim/_core/defaults.lua`), so the pair was never free
--- and taking it would have shadowed `:bprevious`. Asking the running editor
--- rather than the source found it, along with the rest of what is taken:
--- `[a ]a [A ]A [b ]b [B ]B [t ]t [T ]T [L ]L [Q ]Q` from Neovim,
--- `[d ]d [D ]D [l ]l [q ]q [w ]w` from lsp.nvim, and `[s ]s` from
--- snacks.nvim's scope motion -- the closest neighbour to this one.
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
