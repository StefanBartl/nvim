---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.
---
--- Only neo-tree-native command names and `noop`s live here. Every key that
--- runs code of this config's own used to be in this table too, and each
--- one has since moved into filetree.nvim, which binds it buffer-locally on
--- FileType and always wins: `d` (trash), `x`/`c`/`p` (copy_move), `y`
--- (path_copy, aliased to it in plugins/personal/init.lua), `"`/`!`
--- (source_switcher, 2026-09-19). What stays for such a key is a `noop`
--- where neo-tree's own default would otherwise install a normal- or
--- visual-mode map underneath filetree's.

---@return table<string, any>
return {

  -- Default delete is disabled here; filetree.nvim's trash feature owns `d`
  -- (buffer-local, set after this via FileType and always wins - verified).
  ["d"] = "noop",

  --====================== Yank / Clipboard ===========================

  -- neo-tree's default `y` is `copy_to_clipboard`, which stages the node in
  -- neo-tree's *filesystem* clipboard for a later paste -- an exact
  -- duplicate of filetree.nvim's copy_move `c`, and it never touches the
  -- system clipboard, so `y` looked like a yank and put nothing in "+.
  -- Worse, renderer.set_buffer_mappings() also installs a *visual-mode* map
  -- whenever `state.commands[<name> .. "_visual"]` exists, and
  -- copy_to_clipboard_visual does: selecting a name with `v` and pressing
  -- `y` staged a file copy instead of yanking the text.
  --
  -- "noop" is checked before any map is installed, so it drops neo-tree's
  -- normal *and* visual map. filetree.nvim's path_copy then owns normal-mode
  -- `y` (`keymap_abs = { "[a", "y" }` in plugins/personal/init.lua), and
  -- visual `y` falls back to the native yank, which reaches the system
  -- clipboard via 'clipboard' = unnamedplus.
  ["y"] = "noop",

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

  -- `"`/`!` are filetree.nvim's source_switcher (buffer-local, FileType):
  -- next/previous source keeping the tree's position. neo-tree's own `<`
  -- re-opens at the configured position instead, so it stays off; `>` is
  -- left as neo-tree's default.
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
