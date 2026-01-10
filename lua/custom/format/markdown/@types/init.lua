---@module 'custom.format.markdown.@types'
---@brief Type definitions for markdown formatting operations
---@description
--- Defines types for markdown-specific formatting subcommands.

---@alias Custom.Format.Markdown.SubcommandName
---| "headline_separators"  -- Ensure proper spacing between H2+ sections

---@class Custom.Format.Markdown.Section
---@field heading_idx integer Line number of H2+ heading (1-based)
---@field section_end_idx integer Line number of last content line (1-based)
---@field next_heading_idx integer Line number of next H2+ heading (1-based)

---@class Custom.Format.Markdown.SeparatorOpts
---@field notify boolean|nil Whether to show notifications (default: true)
---@field dry_run boolean|nil Preview mode without modifications (default: false)

return {}
