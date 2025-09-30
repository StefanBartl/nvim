---@meta
---@module 'autocmds.git.types.aliases'

--------------------------------------------------------------------------------
-- Common aliases (string literal unions help LuaLS provide better completions)
--------------------------------------------------------------------------------

--- Highlight group name (must exist or resolve via colorscheme)
---@alias HighlightGroup string

--- Path-like string (absolute or relative)
---@alias PathString string

--- Git executable to use (absolute path or binary on $PATH)
---@alias GitCommand string  -- e.g. "git" (default), "/usr/local/bin/git"

--- Neovim buffer type filter (subset of well-known values)
---@alias Buftype '" "'
---| '"acwrite"'
---| '"help"'
---| '"nofile"'
---| '"nowrite"'
---| '"prompt"'
---| '"quickfix"'
---| '"terminal"'

--- Neovim mode selector (single-character) used by `modes`
---@alias GitModeChar '"n"'  -- Normal
---| '"v"'                   -- Visual (includes V and CTRL-V internally)
---| '"i"'                   -- Insert

--- Autocmd event names used across modules (documented for completion)
---@alias AutocmdEvent
---| '"VimEnter"'
---| '"FocusGained"'
---| '"BufEnter"'
---| '"BufHidden"'
---| '"BufWinEnter"'
---| '"BufWinLeave"'
---| '"FileType"'
---| '"CursorHold"'
---| '"CursorHoldI"'
---| '"CursorMoved"'
---| '"InsertEnter"'

