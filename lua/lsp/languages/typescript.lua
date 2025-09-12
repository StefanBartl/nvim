---@module 'lsp.languages.typescript'

-- AUDIT:
---@class LangTsQoL

-- Local structural typings for LuaLS (avoid dependency on external doc names)

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

local M = {}

--- Check whether a client supports a given CodeActionKind.
---@param client LspClient
---@param kind string
---@return boolean
local function client_supports_code_action_kind(client, kind)
  if not (client and client.supports_method and client:supports_method "textDocument/codeAction") then
    return false
  end
  local caps = client.server_capabilities or {}
  local provider = caps.codeActionProvider
  local kinds = (type(provider) == "table") and provider.codeActionKinds or nil
  if type(kinds) == "table" then
    for _, k in ipairs(kinds) do
      if k == kind or k == "source" then
        return true
      end
    end
    return false
  end
  return true
end

--- Run "source.organizeImports" synchronously before save.
--- Builds proper CodeActionParams, applies edits, and executes commands explicitly.
---@param bufnr integer
---@return boolean applied
local function organize_imports_sync(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr }
  if #clients == 0 then
    return false
  end

  ---@type LspClient[]
  local eligible = {}
  for _, c in ipairs(clients) do

    ---@diagnostic disable-next-line
    if client_supports_code_action_kind(c, "source.organizeImports") then
      ---@diagnostic disable-next-line
      eligible[#eligible + 1] = c
    end
  end
  if #eligible == 0 then
    return false
  end

  local enc = eligible[1].offset_encoding or "utf-16"

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local td = vim.lsp.util.make_text_document_params(bufnr)

  ---@type CodeActionParams
  local params = {
    textDocument = td,
    range = {
      start = { line = 0, character = 0 },
      ["end"] = { line = math.max(0, line_count - 1), character = 0 },
    },
    context = { only = { "source.organizeImports" }, diagnostics = {} },
  }

  local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
  if not results then
    return false
  end

  local applied = false
  for _, res in pairs(results) do
    local actions = res and res.result
    if type(actions) == "table" then
      for _, action in ipairs(actions) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, enc)
          applied = true
        end
        local cmd = action.command
        if cmd then
          for _, c in ipairs(eligible) do
            if c.supports_method and c:supports_method "workspace/executeCommand" then
              c:request("workspace/executeCommand", cmd, function() end, bufnr)
              applied = true
            end
          end
        end
      end
    end
  end

  return applied
end

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangTs", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = grp,
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function(ev)
      pcall(organize_imports_sync, ev.buf)
    end,
  })
end

return M
