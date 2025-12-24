---@meta
---@module 'lsp.@types'

---@class MyLspInit
---@field ensure_installing boolean|nil

---@class LspClientCapabilities
---@field codeLensProvider table|nil
---@field inlayHintProvider table|nil
---@field semanticTokensProvider table|nil
---@field documentFormattingProvider boolean|nil
---@field documentRangeFormattingProvider boolean|nil
---@field completionProvider table|nil
---@field definitionProvider boolean|nil
---@field codeActionProvider boolean|nil
---@field textDocumentSync any
---@field positionEncoding string|nil
---@field diagnosticProvider boolean|nil
---@field publishDiagnosticsProvider boolean|nil

---@class LspClient
---@field id integer
---@field name string
---@field offset_encoding string|nil
---@field root_dir string|nil
---@field workspace_folders { name?: string, uri?: string }[]|nil
---@field config table|nil
---@field supports_method fun(self: LspClient, method: string): boolean
---@field server_capabilities LspClientCapabilities|nil
---@field request fun(self: LspClient, method: string, params: table, callback: fun(err:any, res:any), bufnr: integer)

-- ---@field request fun(self: LspClient, method: string, params: table, callback: fun(err:any, res:any), bufnr: integer)
-- ---@field server_capabilities { codeActionProvider?: boolean|{ codeActionKinds?: string[] } }|nil

---@alias LspPositionEncoding "utf-8"|"utf-16"|"utf-32"

---@class LspPosition
---@field line integer        # 0-based line index
---@field character integer  # character offset in the given positionEncoding

---@class LspRange
---@field start LspPosition
---@field ["end"] LspPosition
-- ---@field range { start: { line: integer, character: integer }, ["end"]: { line: integer, character: integer } }

---@class TextDocumentIdentifier
---@field uri string          # document URI (e.g. file:///...)
-- ---@field textDocument { uri: string }

---@class CodeActionContext
---@field diagnostics table[]|nil
---@field only string[]|nil
---@field triggerKind integer|nil
-- ---@field context { only?: string[], diagnostics?: table[] }

---@class CodeActionParams
---@field textDocument TextDocumentIdentifier
---@field range LspRange
---@field context CodeActionContext
---@field workDoneToken any|nil
---@field partialResultToken any|nil

---@class AttachOptions
---@field use_workspace_diagnostics boolean
---@field use_lazydev boolean
---@class AttachApi
---@field on_attach fun(client: any, bufnr:integer)
---@field on_init   fun(client: any, _):boolean

return {}
