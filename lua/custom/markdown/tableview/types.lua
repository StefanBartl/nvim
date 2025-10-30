---@module 'custom.markdown.tableview.types'

--- ======================================
--- init.lua -----------------------------
--- ======================================
---@alias TableViewOptions {floating?: boolean, width?: number, height?: number, bufname?: string}


--- ======================================
--- parser.lua ---------------------------
--- ======================================
---@class MarkdownTableCell
---@field content string

---@class MarkdownTableRow
---@field cells MarkdownTableCell[]

---@class MarkdownTable
---@field header MarkdownTableRow
---@field alignments string[]  -- "left"|"center"|"right"
---@field rows MarkdownTableRow[]
---@field start_line integer
---@field end_line integer

