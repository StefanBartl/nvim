---@meta
---@module '@types.git'
-- Common aliases

--- Git executable to use (absolute path or binary on $PATH)
---@alias Git.Command string  -- e.g. "git" (default), "/usr/local/bin/git"

--- Neovim buffer type filter (subset of well-known values)
---@alias Git.BufType '" "'
---| '"acwrite"'
---| '"help"'
---| '"nofile"'
---| '"nowrite"'
---| '"prompt"'
---| '"quickfix"'
---| '"terminal"'

--- Neovim mode selector (single-character) used by `modes`
---@alias Git.ModeChar '"n"'  -- Normal
---| '"v"'                   -- Visual (includes V and CTRL-V internally)
---| '"i"'                   -- Insert

return {}

