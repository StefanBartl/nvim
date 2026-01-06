---@module 'custom.format.table.@types'

---@alias Custom.Fmt.FmtTbl.Alignment "left"|"center"|"right"

---@class Custom.Fmt.FmtTbl.Cfg
---@field header_align Custom.Fmt.FmtTbl.Alignment Default alignment for header row
---@field entry_align Custom.Fmt.FmtTbl.Alignment Default alignment for data rows

---@class Custom.Fmt.FmtTbl.ParsedTable
---@field start_line integer First line number (1-indexed)
---@field end_line integer Last line number (1-indexed)
---@field rows string[][] Array of rows, each row is array of cell contents
---@field separator_style "compact"|"spaced" Whether separator uses | ----- | or |-----|
---@field col_count integer Number of columns

return  {}

