---@module 'config.treesitter.guards'
---@brief Central guard logic for Treesitter activation

local M = {}

--- List of filetypes where Treesitter should be active
---@type table<string, boolean>
local whitelist = {
  lua = true,
  vim = true,
  vimdoc = true,

  bash = true,
  zsh = true,

  javascript = true,
  typescript = true,
  tsx = true,

  go = true,
  rust = true,
  python = true,
  c = true,
  cpp = true,

  json = true,
  yaml = true,
  toml = true,
  markdown = true,
}

--- Check whether Treesitter should be enabled for a buffer
---@param bufnr integer
---@return boolean
function M.is_enabled(bufnr)
  -- invalid buffer safety
  if not bufnr or bufnr == 0 then
    return false
  end

  local ft = vim.bo[bufnr].filetype

  if not ft or ft == "" then
    return false
  end

  return whitelist[ft] == true
end

return M
