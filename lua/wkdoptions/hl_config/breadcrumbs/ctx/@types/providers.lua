---@meta
---@module 'wkdoptions.hl_config.breadcrumbs.ctx.@types.providers'

---@class Breadcrumbs.Provider
---@field enabled fun(cfg: WKDOptionsBreadcrumbsCtx): boolean # Runtime check
---@field extract fun(node: TSNode|nil, cfg: WKDOptionsBreadcrumbsCtx): string|nil # Main extraction logic

---@class Breadcrumbs.LangModule
---@field detect_literal_field fun(node: TSNode|nil): boolean # Check if node is inside literal/constructor
---@field extract_owner fun(node: TSNode|nil): string|nil # Extract owner from literal (e.g., "M" from "M = {...}")
---@field extract_container fun(node: TSNode|nil, max_depth: integer): string|nil # Extract container chain (e.g., "Class.Nested")
---@field extract_base fun(node: TSNode|nil): string|nil # Extract base identifier (fallback)

---@class Breadcrumbs.TSHelpers
---@field node_text fun(node: TSNode|nil): string # Memoized text extraction
---@field find_ancestor fun(node: TSNode|nil, types: table<string, boolean>): TSNode|nil # Memoized ancestor search
---@field node_at_cursor fun(): TSNode|nil # Cached node-at-cursor (per tick)

---@class Breadcrumbs.TextUtils
---@field dedupe_consecutive fun(parts: string[]): string[] # Remove adjacent duplicates
---@field extract_identifier fun(text: string, lang: string): string|nil # Cached pattern extraction
---@field escape_pattern fun(s: string): string # Escape for Lua patterns

return {}
