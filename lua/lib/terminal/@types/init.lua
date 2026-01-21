---@meta
---@module 'lib.terminal.@types'

---@class Lib.Terminal.Escape
---@field escape fun(path: string): string

---@class Lib.Terminal.Query
---@field is_terminal_buf fun(bufnr: integer): boolean|nil

---@class Lib.Terminal.Modify
---@field delete_terminal_buf fun(bufnr: integer): boolean|nil

---@class Lib.Terminal
---@field escape Lib.Terminal.Escape
---@field query Lib.Terminal.Query
---@field modify Lib.Terminal.Modify

---@class Lib.Terminal.ALL
---@field escape fun(path: string): string
---@field is_terminal_buf fun(bufnr: integer): boolean|nil
---@field delete_terminal_buf fun(bufnr: integer): boolean|nil

return {}
