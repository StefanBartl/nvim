---@meta
---@module 'usrcmds.emojis.@types'

-- #####################################################################
-- Emojis Usercommand Types

---@alias Emojis.Action
---| '"clear"'   # Remove all emojis from scope
---| '"insert"'  # Open picker and insert emoji at cursor
---| '"list"'    # List all emojis found in scope (quickfix)
---| '"count"'   # Count emojis in scope and notify result
---| '"replace"' # Replace emojis with their text-names (e.g. 😀 → :grinning:)

---@alias Emojis.Scope
---| '"word"'    # The word under cursor (<cword>)
---| '"line"'    # Current line (cursor line)
---| '"visual"'  # Currently selected / last visual selection
---| '"%"'       # Whole current buffer
---| '"cwd"'     # All files under cwd (ripgrep-based, async)

---@class Emojis.Opts
---@field action Emojis.Action
---@field scope  Emojis.Scope

---@class Emojis.CmdArgs : Lib.UserCommand.Args
---@field args   string  Raw argument string passed to the command
---@field fargs  string[] Parsed argument tokens
---@field range  integer  0 = no range, 1 = one line, 2 = line range
---@field line1  integer  First line of range (1-based)
---@field line2  integer  Last line of range (1-based)

---@class Emojis.OpResult
---@field ok      boolean
---@field changed integer   Number of emojis affected (removed / replaced)
---@field err     string|nil

---@class usrcmds.emojis.Module
---@field setup fun(opts?: usrcmds.emojis.SetupOpts)

---@class usrcmds.emojis.SetupOpts
---@field default_scope? Emojis.Scope  Override the default scope (default: "%")

return {}
return {}
