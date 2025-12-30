---@meta
---@module 'usrcmds.migrate.notify.@types'

---@alias MigrateNotify.LogLevel
---| "TRACE"
---| "DEBUG"
---| "INFO"
---| "WARN"
---| "ERROR"
---| "OFF"

---@class MigrateNotify.Match
---@field line integer           # 1-based line number (start)
---@field col integer            # 0-based byte column (start)
---@field end_line integer       # 1-based line number (end, may differ for multiline)
---@field end_col integer        # 0-based byte end column
---@field original string        # Original call (e.g. "vim.notify(...)")
---@field replacement string     # Target call (e.g. "notify.info(...)")
---@field log_level MigrateNotify.LogLevel

---@class MigrateNotify.FileMatches
---@field path string
---@field matches MigrateNotify.Match[]

---@class MigrateNotify.RefactorResult
---@field success boolean
---@field modified_lines integer
---@field errors string[]

---@class MigrateNotify.ScanOpts
---@field dry_run boolean|nil    # Preview only, no modifications
---@field telescope boolean|nil  # Show results in Telescope picker

return {}
