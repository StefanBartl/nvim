---@module 'usrcmds.migrate.@types'

--=== migrate

---@class UsrCmds.Migrate.Config
---@field opt boolean|nil Enable option API migration (:MigrateOpt)
---@field notify boolean|nil Enable notify migration (:MigrateNotify)

--=== notify

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

---== opts

---@class MigrateOpt.Match
---@field bufnr number|nil Buffer number (only for buffer-local matches)
---@field fname string|nil File name (absolute path for file matches)
---@field lnum number Line number (1-indexed)
---@field text string Original line text
---@field migrated string Migrated line text
---@field source "buf"|"file" Source type: buffer or file

return {}
