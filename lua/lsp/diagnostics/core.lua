---@module 'lsp.diagnostics.core'
--- Core helpers shared by all diagnostics submodules.
--- Contains severity parsing and mapping only.
require("lua.lsp.diagnostics.@types")

---@class Lsp.Diagnostics.Core
local M = {}

---@type table<string, integer>
M.severity_map = {
  error = vim.diagnostic.severity.ERROR,
  err = vim.diagnostic.severity.ERROR,
  e = vim.diagnostic.severity.ERROR,

  warn = vim.diagnostic.severity.WARN,
  warning = vim.diagnostic.severity.WARN,
  w = vim.diagnostic.severity.WARN,

  info = vim.diagnostic.severity.INFO,
  i = vim.diagnostic.severity.INFO,

  hint = vim.diagnostic.severity.HINT,
  h = vim.diagnostic.severity.HINT,
}

---@param s string|integer|nil
---@return integer|nil
function M.parse_severity(s)
  if type(s) == "number" then
    return s
  end
  if type(s) ~= "string" then
    return nil
  end
  if s == "" or s == "all" then
    return nil
  end
  return M.severity_map[s:lower()]
end

return M

