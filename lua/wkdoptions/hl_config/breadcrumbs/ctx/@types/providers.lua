---@meta
---@module 'wkdoptions.hl_config.breadcrumbs.ctx.@types.providers'

---@class Breadcrumbs.ProviderContext
---@field node TSNode|nil # Current TreeSitter node
---@field cfg WKDOptionsBreadcrumbsCtx # Config reference
---@field filetype string # Buffer filetype
---@field base_symbol string|nil # Pre-extracted base token (for container provider)

---@class Breadcrumbs.Provider
---@field name string # Unique provider identifier
---@field priority integer # Execution priority (higher = earlier)
---@field enabled fun(cfg: WKDOptionsBreadcrumbsCtx): boolean # Runtime check
---@field extract fun(ctx: Breadcrumbs.ProviderContext): string|nil # Main extraction logic

---@class Breadcrumbs.LangModule
---@field detect_literal_field fun(node: TSNode|nil): boolean # Check if node is inside literal/constructor
---@field extract_owner fun(node: TSNode|nil): string|nil # Extract owner from literal (e.g., "M" from "M = {...}")
---@field extract_container fun(node: TSNode|nil, max_depth: integer): string|nil # Extract container chain (e.g., "Class.Nested")
---@field extract_base fun(node: TSNode|nil): string|nil # Extract base identifier (fallback)

---@class Breadcrumbs.TSPattern
---@diagnostic disable-next-line: undefined-doc-name
---@field query vim.treesitter.Query # Compiled query
---@field cache_key string # Pattern identifier for bytecode cache

---@class Breadcrumbs.TSHelpers
---@field node_text fun(node: TSNode|nil): string # Memoized text extraction
---@field find_ancestor fun(node: TSNode|nil, types: table<string, boolean>): TSNode|nil # Memoized ancestor search
---@field node_at_cursor fun(): TSNode|nil # Cached node-at-cursor (per tick)
---@field compile_pattern fun(lang: string, pattern: string): Breadcrumbs.TSPattern|nil # Pre-compile TS queries

---@class Breadcrumbs.TextUtils
---@field dedupe_consecutive fun(parts: string[]): string[] # Remove adjacent duplicates
---@field extract_identifier fun(text: string, lang: string): string|nil # Cached pattern extraction
---@field split_dotted fun(path: string): string[] # Split "a.b.c" → {"a", "b", "c"}
---@field escape_pattern fun(s: string): string # Escape for Lua patterns

return {}
