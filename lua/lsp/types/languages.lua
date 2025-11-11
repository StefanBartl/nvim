---@module 'lsp.languages.types.languages'

---@class LspClient
---@field name? string
---@field server_capabilities { codeActionProvider?: boolean|{ codeActionKinds?: string[] } }|nil
---@field offset_encoding? string
---@field supports_method fun(self: LspClient, method: string): boolean
---@field request fun(self: LspClient, method: string, params: table, handler: fun(...: any), bufnr: integer)

---@class CodeActionParams
---@field textDocument { uri: string }
---@field range { start: { line: integer, character: integer }, ["end"]: { line: integer, character: integer } }
---@field context { only?: string[], diagnostics?: table[] }

