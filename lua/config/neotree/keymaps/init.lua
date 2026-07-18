---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.

local lazy = require("lib.lua.lazy")
local source_command = lazy.require("config.neotree.commands.source")

---@return table<string, any>
return {

  -- Default delete is disabled here; filetree.nvim's trash feature owns `d`
  -- (buffer-local, set after this via FileType and always wins - verified).
  ["d"] = "noop",

  --====================== Window Control =============================

  ["q"] = "close_window",
  ["?"] = "show_help",
  ["g?"] = "noop",

  -- <Esc> is intentionally not mapped here: filetree.nvim's tree_reset
  -- feature (buffer-local, set after this table via FileType) always wins
  -- over this table's mapping for the same key/buffer - a native entry here
  -- would only ever be dead code (verified via :verbose map).

  --====================== Source Switching ===========================

  ['"'] = function(_)
    source_command.next_source()
  end,
  ["!"] = function(_)
    source_command.prev_source()
  end,
  ["<"] = "noop",

  --====================== Window Management ==========================

  ["R"] = "refresh",
  ["C"] = "close_node",
  ["z"] = "close_all_nodes",
  ["W"] = "open_with_window_picker",

  -- "w" is intentionally not mapped here: filetree.nvim's window_size_cycler
  -- feature (buffer-local, set after this table via FileType) always wins
  -- over this table's mapping for the same key/buffer - a native entry here
  -- would only ever be dead code (verified via :verbose map).

  --====================== Splits / Tabs ==============================

  -- These are intentionally disabled here and enabled per-source
  ["s"] = "noop",
  ["t"] = "noop",
}
