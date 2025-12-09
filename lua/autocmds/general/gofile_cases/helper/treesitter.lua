---@module 'autocmds.general.gofile_cases.helper.treesitter'

local M = {}

--- Safe treesitter node text retrieval.
--- @param node userdata
--- @param bufnr integer
--- @return string|nil
function M.ts_text(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  return ok and text or nil
end

return M
