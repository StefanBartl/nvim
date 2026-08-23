---@meta
---@module 'lsp.@types.servers'

---@class MarksmanLocalConfig
---@field suppress_missing_doc_links boolean        -- Whether to suppress "non-existent document" diagnostics
---@field missing_doc_links_pattern string          -- Lua pattern that matches Marksman's broken-link message
---@field root_dir_fallbacks string[]               -- Markers used to detect project root for multi-file mode
---@field filetypes string[]                        -- Filetypes to attach to (prefer plain markdown)

return {}
