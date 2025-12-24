---@module 'custom.recommender.utils'
---Shared helper utilities

local M = {}

local api = vim.api

---Safely set buffer lines
---@param bufnr integer
---@param lines string[]
function M.buf_set_lines_safe(bufnr, lines)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  pcall(api.nvim_buf_set_option, bufnr, "modifiable", true)
  pcall(api.nvim_buf_set_lines, bufnr, 0, -1, false, lines)
  pcall(api.nvim_buf_set_option, bufnr, "modifiable", false)
end

---Create a shallow copy of a table
---@param tbl table
---@return table
function M.tbl_copy(tbl)
  local out = {}
  for k, v in pairs(tbl) do
    out[k] = v
  end
  return out
end

---Deep copy a table
---@param tbl table
---@return table
function M.tbl_deep_copy(tbl)
  if type(tbl) ~= "table" then
    return tbl
  end

  local out = {}
  for k, v in pairs(tbl) do
    out[k] = M.tbl_deep_copy(v)
  end
  return out
end

return M
