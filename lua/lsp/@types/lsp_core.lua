---@meta
---@module 'lsp.@types.lsp_core'

---@class lsp.Client
---@field name string
---@field id integer
---@field config table
---@field supports_method fun(self: lsp.Client, method:string):boolean
---@field server_capabilities any

---@class AttachOptions
---@field use_workspace_diagnostics boolean
---@field use_lazydev boolean
---@class AttachApi
---@field on_attach fun(client: any, bufnr:integer)
---@field on_init   fun(client: any, _):boolean
