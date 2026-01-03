---@module 'usrcmds.format_table.@types'

---@alias UsrCmds.FmtTbl.Alignment "left"|"center"|"right"

---@class UsrCmds.FmtTbl.Cfg
---@field header_align UsrCmds.FmtTbl.Alignment Default alignment for header row
---@field entry_align UsrCmds.FmtTbl.Alignment Default alignment for data rows

---@class UsrCmds.FmtTbl.ParsedTable
---@field start_line integer First line number (1-indexed)
---@field end_line integer Last line number (1-indexed)
---@field rows string[][] Array of rows, each row is array of cell contents
---@field separator_style "compact"|"spaced" Whether separator uses | ----- | or |-----|
---@field col_count integer Number of columns

return  {}

