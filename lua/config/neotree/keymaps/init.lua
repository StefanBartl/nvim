---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.

local lazy = require("lib.lua.lazy")
local source_command = lazy.require("config.neotree.commands.source")
local node_utils = require("config.neotree.utils.node")

---@return table<string, any>
return {

  -- Default delete is disabled here; filetree.nvim's trash feature owns `d`
  -- (buffer-local, set after this via FileType and always wins - verified).
  ["d"] = "noop",

  --====================== Yank / Clipboard ===========================

  -- neo-tree's default `y` is `copy_to_clipboard`, which stages the node in
  -- neo-tree's *filesystem* clipboard for a later paste. Two things were wrong
  -- with leaving it:
  --
  --   1. It is an exact duplicate of filetree.nvim's copy_move `c` (same
  --      stage-then-paste model, and copy_move is the one with the conflict
  --      prompt, the marks integration and the C/X extmarks), and it never
  --      touches the system clipboard - so `y` on a node looked like a yank
  --      and put nothing in "+.
  --   2. renderer.set_buffer_mappings() additionally installs a *visual-mode*
  --      map whenever `state.commands[<name> .. "_visual"]` exists, and
  --      copy_to_clipboard_visual does. That buffer-local `v`/`x` map shadowed
  --      the native yank, so selecting a name with `v` and pressing `y` staged
  --      a file copy instead of yanking the text.
  --
  -- Binding a *function* fixes both at once: the `_visual` lookup happens only
  -- in the `type(func) == "string"` branch, so a function installs the
  -- normal-mode map alone and visual `y` falls back to the native yank (which
  -- reaches the system clipboard via 'clipboard' = unnamedplus, see options).
  --
  -- The normal-mode action delegates to filetree.nvim's path_copy - the same
  -- code path as `[a` - rather than reimplementing it here. The local fallback
  -- only runs when filetree is absent or path_copy is disabled.
  ["y"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      -- feature() hands back the module only while it is actively loaded, so
      -- an absent or disabled path_copy falls through to the local copy below
      -- instead of warning "No node under cursor" from a nil adapter.
      local ok, filetree = pcall(require, "filetree")
      local path_copy = ok and filetree.feature("path_copy") or nil
      if path_copy and type(path_copy.copy_absolute) == "function" then
        path_copy.copy_absolute()
        return
      end

      local path = node_utils.get_path(node_utils.get_current(state))
      if path == "" then
        vim.notify("Neo-tree: no node under cursor", vim.log.levels.INFO)
        return
      end

      vim.fn.setreg("+", path)
      vim.fn.setreg('"', path)
      vim.notify("Copied: " .. path, vim.log.levels.INFO)
    end,
    desc = "Copy absolute path to system clipboard",
  },

  -- Same defect as `y` above, one key over: filetree.nvim's copy_move owns
  -- normal-mode `x` (stage cut), but neo-tree's own cut_to_clipboard kept a
  -- visual-mode map alive through cut_to_clipboard_visual - so `v` then `x`
  -- silently staged files for a cut instead of behaving like a read-only
  -- buffer. "noop" is checked before any map is installed, so this drops
  -- neo-tree's normal *and* visual map and leaves filetree's `x` untouched.
  ["x"] = "noop",

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
