---@meta
---@module 'utils.help_sync.types'

---@class HelpSyncConfig
---@field search_roots string[]?     -- Roots to scan recursively; defaults to { stdpath("config"), stdpath("config").."/lua" }
---@field docs_dirnames string[]?    -- Folder names to treat as help containers (default { "docs" })
---@field aggregator_ns string?      -- Namespace under the state dir (default "local")
---@field prefer_symlink boolean?    -- Try symlinks first; fallback to copy (default true)
---@field clear_before_build boolean?-- Remove old aggregator files before a rebuild (default true)
---@field rebuild_on_start boolean?  -- Run once on VimEnter (default false)
---@field notify_prefix string?      -- Prefix for vim.notify messages (default "[HelpSync] ")

-- Runtime options (all required)
---@class HelpSyncRuntimeOptions
---@field search_roots string[]
---@field docs_dirnames string[]
---@field aggregator_ns string
---@field prefer_symlink boolean
---@field clear_before_build boolean
---@field rebuild_on_start boolean
---@field notify_prefix string

---@class HelpSyncModule
---@field opts HelpSyncConfig
