---@meta
---@module 'custom.markdown.tableview.@types'

---@alias Custom.TableView.Options {floating?: boolean, width?: number, height?: number, bufname?: string}

--- parser

---@class Custom.Markdown.TableCell
---@field content string

---@class Custom.Markdown.TableRow
---@field cells Custom.Markdown.TableCell[]

---@class Custom.Markdown.Table
---@field header Custom.Markdown.TableRow?
---@field alignments string[]  -- "left"|"center"|"right"
---@field rows Custom.Markdown.TableRow[]
---@field start_line integer
---@field end_line integer
