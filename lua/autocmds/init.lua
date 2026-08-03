---@module 'autocmds'
--- Initialize module for 'autocmds'

--FIX: Modularisere die submodule in eigene module

-- AUDIT: Wenn keine Probleme, dann dauerhaft implementieren, aber nach wkdoptions/ui oder ähnliches:
require("autocmds.auto-center-fexplorer").setup()

-- AUDIT: not exercised against a live neo-tree + snacks session yet — verify
-- the open/close/reopen-once cascade (<A-l> vs <leader>.) before trusting it.
require("autocmds.explorer-singleton").setup()

------------------------------------------------------
--- General
------------------------------------------------------

require("autocmds.general").enable({
  kitty = {
    enable = true, -- Sets Kitty padding/margin to compact values on VimEnter and restores them on VimLeavePre.
  },
  cursorline = {
    enable = false, -- Toggles the local 'cursorline' option on focus/normal events and hides it on insert/leave events.
  },
  last_loc = {
    enable = false, -- On BufReadPost, jumps back to the last cursor position unless the filetype is excluded.
  },
  no_name_guard = {
    enable = false, -- SUPERSEDED: this generic sweep has no tree-window exclusion, which raced with neo-tree's own startup/open sequence (state.tree nil in commands.lua:827). Re-implemented tree-aware in filetree.nvim (features/nav/no_name_guard, using util/buffer.lua's TREE_FT/adapter.get_winid() exclusion) — enable there once the neo-tree block migrates to filetree.nvim (Liste 1). Keep disabled here.
  },
})

------------------------------------------------------
--- Git
------------------------------------------------------

local ok_g, git = pcall(require, "autocmds.git")
if ok_g then
  git.enable(true)
end

------------------------------------------------------
--- Terminals
------------------------------------------------------

require("autocmds.terminals").enable({
  numbers = {
    enable = true,              -- On terminal open, turns off local 'number' and 'relativenumber' to declutter terminal panes.
  },
  kitty = {
    enable = true,              -- In Kitty, applies compact padding/margin on VimEnter and restores defaults on VimLeavePre.
  },
  auto_insert = {
    enable = false,             -- Automatically enters Insert mode in terminal buffers; add "TermEnter" to events if desired.
  },
})

------------------------------------------------------
--- Text
------------------------------------------------------

require("autocmds.text").enable({
  trim_trailing = {
    enable = true, -- On BufWritePre, removes trailing whitespace at end-of-line in normal, modifiable buffers.
  },
  trim_blank = {
    enable = true, -- On BufWritePre, cleans whitespace-only (blank) lines; restores the exact cursor position afterwards.
  },
  last_loc = {
    enable = true, -- On BufReadPost, jumps back to the last saved cursor position unless filetype is excluded.
  },
})
