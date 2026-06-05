---@module 'custom.format.table.@types'
---@brief Type definitions for the Markdown table formatter.

-- ─────────────────────────────────────────────────────────────────────────────
-- Alignment
-- ─────────────────────────────────────────────────────────────────────────────

---@alias Custom.Fmt.FmtTbl.Alignment "left"|"center"|"right"

-- ─────────────────────────────────────────────────────────────────────────────
-- Column exceptions
-- ─────────────────────────────────────────────────────────────────────────────

---Specifies a per-column alignment override.
---Columns are identified by 1-based index or by header name (case-insensitive).
---
---Examples:
---  { col = 1,            align = "left" }   -- first column always left
---  { col = "Beschreibung", align = "left" } -- column with that header name
---
---@class Custom.Fmt.FmtTbl.ColOverride
---@field col integer|string  Column index (1-based) or header name (case-insensitive match)
---@field align Custom.Fmt.FmtTbl.Alignment

-- ─────────────────────────────────────────────────────────────────────────────
-- Format options  (passed to the public API)
-- ─────────────────────────────────────────────────────────────────────────────

---Options accepted by `format_table_at_cursor` and `format_tables_in_scope`.
---All fields are optional; sensible defaults apply.
---
---@class Custom.Fmt.FmtTbl.Opts
---@field header_align?    Custom.Fmt.FmtTbl.Alignment  Alignment for the header row (default: "center")
---@field entry_align?     Custom.Fmt.FmtTbl.Alignment  Alignment for data rows      (default: "center")
---@field col_overrides?   Custom.Fmt.FmtTbl.ColOverride[]  Per-column exceptions
---@field scope?           Custom.Fmt.FmtTbl.Scope          Where to apply formatting

-- ─────────────────────────────────────────────────────────────────────────────
-- Scope
-- ─────────────────────────────────────────────────────────────────────────────

---Controls which tables are formatted.
---
---  "cursor"  – Only the table the cursor currently sits in (default).
---  "buffer"  – Every table in the current buffer  (same as `%` in the command).
---  "cwd"     – Every *.md file under the current working directory (recursive).
---  A string that is not one of the above keywords is treated as a file path
---  (absolute or relative to cwd) and all tables in that file are formatted.
---
---@alias Custom.Fmt.FmtTbl.Scope
---| "cursor"   # Only the table under the cursor
---| "buffer"   # All tables in the current buffer
---| "cwd"      # All *.md files under vim.fn.getcwd()
---| string     # Explicit file path or glob pattern

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal parsed representation
-- ─────────────────────────────────────────────────────────────────────────────

---@class Custom.Fmt.FmtTbl.ParsedTable
---@field start_line     integer      First line of the table (1-indexed)
---@field end_line       integer      Last line of the table  (1-indexed)
---@field rows           string[][]   rows[1] = header cells; rows[2..n] = data cells
---@field separator_style "compact"|"spaced"
---@field col_count      integer

-- ─────────────────────────────────────────────────────────────────────────────
-- Module config (persistent defaults)
-- ─────────────────────────────────────────────────────────────────────────────

---@class Custom.Fmt.FmtTbl.Cfg
---@field header_align   Custom.Fmt.FmtTbl.Alignment
---@field entry_align    Custom.Fmt.FmtTbl.Alignment

return {}
