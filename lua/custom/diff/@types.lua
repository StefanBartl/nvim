---@meta
---@module 'custom.diff.types'
---@brief Type definitions for the custom diff subsystem.

-- ─────────────────────────────────────────────────────────────────────────────
-- init.lua
-- ─────────────────────────────────────────────────────────────────────────────

---@alias Custom.Diff.Target
---| '"clipboard"'  # Pull content from the system clipboard (+)
---| string         # Absolute or relative file path (tab-completion supported)
---| integer        # An already-open buffer number

---@alias Custom.Diff.Source
---| '"current"'    # The buffer active when :Diff was invoked (default)
---| string         # File path
---| integer        # Buffer number

---@alias Custom.Diff.View
---| '"vsplit"'     # Side-by-side vertical split + diffmode (default)
---| '"split"'      # Horizontal split + diffmode
---| '"inline"'     # Reserved — no new window (not yet implemented)

---@alias Custom.Diff.Output
---| '"buffer"'     # Interactive scratch buffer inside the split (default)
---| '"prompt"'     # Unified-diff text sent to the more-prompt
---| '"file"'       # Write unified diff to a temp file on disk

---@class Custom.Diff.Opts
--- Flags passed to `require("custom.diff").enable(opts)`.
--- All fields are optional; `enable_all = true` is equivalent to setting every
--- feature flag to true.
---@field diff_exit?   boolean  Enable :DiffExit / safe-quit for diffmode
---@field diff_origin? boolean  Enable :DiffOrigin (compare buffer vs last save)
---@field diff?        boolean  Enable the new :Diff command
---@field enable_all?  boolean  Shorthand: enable every sub-feature at once

---@class Custom.Diff.ResolvedOpts
--- Internal: fully-resolved options passed to the `execute` helper.
---@field target Custom.Diff.Target
---@field source Custom.Diff.Source
---@field view   Custom.Diff.View
---@field output Custom.Diff.Output

---@class Custom.Diff.Module
---@field enable fun(opts: Custom.Diff.Opts): nil
---@field run    fun(raw_args: string): nil
---@field clear  fun(): nil

return {}
