---@meta
---@module 'lib.buffer.@types'

---@class Lib.Buffer.Query
---@field is_markdown_buf fun(bufnr_arg: integer|nil): integer|nil

---@class Lib.Buffer.Modify
---@field insert_lines fun(lines: string[], pos?: Lib.Buf.InsertLinesPos): nil

---@class Lib.Buffer
---@field query Lib.Buffer.Query
---@field modify Lib.Buffer.Modify

---@class Lib.Buffer.ALL
---@field is_markdown_buf fun(bufnr_arg: integer|nil): integer|nil
---@field insert_lines fun(lines: string[], pos?: Lib.Buf.InsertLinesPos): nil

return {}
