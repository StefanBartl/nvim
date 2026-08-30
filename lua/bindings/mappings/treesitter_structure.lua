---@module 'bindings.mappings.treesitter_structure'
---@brief Climb out of the structure the cursor is in: `[b` to its head, `]b`
---@brief to its end, repeatable.
---@description
--- From line 40 of a nested configuration table, `[b` puts the cursor on the
--- head of the table that encloses it; press it again and you are one level
--- further out, until you reach the outermost one. `]b` does the same downward,
--- to the closing end. In a function it climbs `for` -> `if` -> `function`
--- instead, because those are the enclosing structures there.
---
--- **This is nvim-treesitter-textobjects' `move` module, not a feature written
--- here.** `goto_previous_start` walks to the nearest match *before* the
--- cursor, and the enclosing node's own head is exactly that -- so "previous
--- start" and "climb out one level" are the same motion, and repeating it
--- climbs. Nothing else was needed.
---
--- The plugin was installed and configured nowhere: `plugins/treesitter.lua`
--- lists it with `lazy = false` and never calls into it, and nothing in
--- `lua/` referenced it. These four keys are the first use of it.
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
--- `[b`/`]b` were free in this config; the other bracket pairs in use are
--- `[f [F [p [r [s [t` here and `[d [l [q [w` from lsp.nvim.
---
---@see plugins.treesitter

local M = {}

--- Captures that count as "a structure you can be inside". `@block.outer` is
--- the shipped one, extended per language in `after/queries`.
---@type string[]
local CAPTURES = { "@block.outer" }

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  --- `move` is required per keypress, not at setup: this module is loaded
  --- during the mappings phase, and pulling the textobjects runtime in there
  --- would pay for a motion most sessions never use.
  ---@param fn "goto_previous_start"|"goto_next_end"
  ---@return fun(): nil
  local function go(fn)
    return function()
      local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
      if not ok then
        require("lib.nvim.notify")
          .create("[bindings.treesitter_structure]")
          .warn("nvim-treesitter-textobjects is not available")
        return
      end
      move[fn](CAPTURES, "textobjects")
    end
  end

  map(
    { "n", "x", "o" },
    "[b",
    go("goto_previous_start"),
    { desc = "Jump to the head of the enclosing structure (repeatable)" }
  )
  map(
    { "n", "x", "o" },
    "]b",
    go("goto_next_end"),
    { desc = "Jump to the end of the enclosing structure (repeatable)" }
  )
end

return M
