---@module 'autocmds.markdown.helpers'

local M = {}

--- Create/clear a namespaced augroup.
---@param name string
---@return integer
function M.augroup(name)
  return vim.api.nvim_create_augroup("markdown_autocmds_" .. name, { clear = true })
end

--- Normalize a FileType autocmd pattern field.
---@param pat any
---@return string|string[]
function M.norm_pattern(pat)
  if pat == nil then
    return "markdown"
  end
  return pat
end

--- Return text of a Treesitter node (safe).
---@param node TSNode
---@param bufnr integer
---@return string|nil
function M.ts_text(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  return ok and text or nil
end

return M
