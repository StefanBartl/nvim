---@module 'custom.recommender.blacklist'
---Chains that should never be suggested

local M = {}

---Default blacklist entries
M.default = {
  -- Vim API chains that you don't want to alias
  -- "vim.api",           -- Would exclude ALL vim.api.* chains
  -- "vim.fn",            -- Would exclude ALL vim.fn.* chains

  -- Standard Lua functions you prefer to use as-is
  -- "table.insert",
  -- "table.concat",
  -- "string.format",

  -- Specific chains you don't want
  -- "vim.api.nvim_get_current_buf",
  -- "vim.keymap.set",

  -- Add your blacklist entries here
}

---Check if a chain is blacklisted (prefix matching)
---@param chain string The chain to check
---@param blacklist string[] List of blacklisted prefixes
---@return boolean
function M.is_blacklisted(chain, blacklist)
  if not blacklist or #blacklist == 0 then
    return false
  end

  for _, prefix in ipairs(blacklist) do
    -- Check if chain starts with the blacklist entry
    if chain:sub(1, #prefix) == prefix then
      return true
    end
  end

  return false
end

return M
