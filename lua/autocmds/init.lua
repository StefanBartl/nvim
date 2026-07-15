---@module 'autocmds'
--- Initialize module for 'autocmds'

--FIX: Modularisere die submodule in eigene module

-- AUDIT: Wenn keine Probleme, dann dauerhaft implementieren, aber nach wkdoptions/ui oder ähnliches:
require("autocmds.auto-center-fexplorer").setup()

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
    enable = false, -- TEMP DISABLED: investigating a possible interaction with neo-tree's own startup/open sequence (state.tree nil in commands.lua:827) reported right after this shipped.
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
