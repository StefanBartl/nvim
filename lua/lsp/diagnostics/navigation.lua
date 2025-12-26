---@module 'lsp.diagnostics.navigation'
--- Logical navigation layer for diagnostics.
--- Decides buffer vs workspace semantics and delegates rendering.
require("lua.lsp.diagnostics.@types")

local core = require("lsp.diagnostics.core")
local quickfix = require("lsp.diagnostics.quickfix")

---@class Lsp.Diagnostics.Navigation
local M = {}

---@param severity integer|nil
---@param opts table|nil
---@return nil
function M.goto_next(severity, opts)
  opts = opts or {}
  local o = vim.tbl_extend("force", {
    wrap = true,
    float = true,
  }, opts)

  if severity ~= nil then
    o.severity = severity
  end

  vim.diagnostic.jump(vim.tbl_extend("force", o, { count = 1 }))
end

---@param severity integer|nil
---@param opts table|nil
---@return nil
function M.goto_prev(severity, opts)
  opts = opts or {}
  local o = vim.tbl_extend("force", {
    wrap = true,
    float = true,
  }, opts)

  if severity ~= nil then
    o.severity = severity
  end

  vim.diagnostic.jump(vim.tbl_extend("force", o, { count = -1 }))
end

---@param severity integer|nil
---@return nil
function M.workspace_next(severity)
  quickfix.to_qf({ severity = severity, open = true })
  quickfix.qf_next()
end

---@param severity integer|nil
---@return nil
function M.workspace_prev(severity)
  quickfix.to_qf({ severity = severity, open = true })
  quickfix.qf_prev()
end

---@param s string|integer|nil
---@return integer|nil
function M.parse_severity(s)
  return core.parse_severity(s)
end

return M

