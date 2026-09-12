---@module 'autocmds'
--- Wires up every autocmd submodule. General/git/terminals/text below take a
--- config table; the two explorer helpers self-register on setup().

require("autocmds.auto-center-fexplorer").setup()

-- NOTE: verify the explorer open/close/reopen-once cascade (<A-l> vs
-- <leader>.) against a live neo-tree + snacks session before trusting it.
require("autocmds.explorer-singleton").setup()

-- Formerly in lua/options.lua; stayed here when that file moved into
-- StefanBartl/my.nvim, because it is a markdown.nvim integration rather than
-- a generic editor option. See the module header.
require("autocmds.markdown_folds").setup()

------------------------------------------------------
--- General
------------------------------------------------------

-- Kitty padding (autocmds.terminals, below) and last_loc (autocmds.text,
-- below) used to be configurable here too -- both were exact duplicates of
-- those modules' own features (kitty was actively double-firing on every
-- VimEnter/VimLeavePre; last_loc was disabled here and never actually ran).
-- Removed 2026-09-12, one owner each now.
require("autocmds.general").enable({
  cursorline = {
    enable = false, -- Toggles the local 'cursorline' option on focus/normal events and hides it on insert/leave events.
  },
  no_name_guard = {
    -- SUPERSEDED: this generic sweep has no tree-window exclusion and raced
    -- with neo-tree's startup (state.tree nil). Re-done tree-aware in
    -- filetree.nvim's features/nav/no_name_guard — enable it there once the
    -- neo-tree block migrates (Liste 1). Keep off here.
    enable = false,
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
    enable = true, -- On terminal open, turns off local 'number' and 'relativenumber' to declutter terminal panes.
  },
  kitty = {
    enable = true, -- In Kitty, applies compact padding/margin on VimEnter and restores defaults on VimLeavePre.
  },
  auto_insert = {
    enable = false, -- Automatically enters Insert mode in terminal buffers; add "TermEnter" to events if desired.
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
