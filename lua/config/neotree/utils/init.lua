---@module 'config.neotree.utils'
---@brief Shared utilities for Neo-tree configuration
local M = {}

---Check if buffer is a valid file buffer for reveal purposes
---@param buf integer|nil Buffer number (0 or nil = current)
---@return boolean
function M.is_valid_file_buffer(buf)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end

  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end

  local buftype = vim.bo[buf].buftype
  if buftype ~= "" then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if not name or name == "" then
    return false
  end

  return vim.fn.filereadable(name) == 1
end

---Get buffer context for reveal operations
---@param buf integer|nil
---@return {buf:integer, file:string, dir:string}|nil
function M.get_buffer_context(buf)
  if not M.is_valid_file_buffer(buf) then
    return nil
  end

  buf = buf or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local dir = vim.fn.fnamemodify(file, ":p:h")

  return {
    buf = buf,
    file = file,
    dir = dir,
  }
end

---Safe hide preview without errors
---@return boolean success
function M.safe_hide_preview()
  local ok = pcall(function()
    local preview = require("neo-tree.sources.common.preview")
    if preview and preview.hide then
      preview.hide()
    end
  end)
  return ok
end

---Get current Neo-tree position if open
---@return NeoTreePosition|nil
function M.get_current_position()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then
    return nil
  end

  local state = manager.get_state and manager.get_state("filesystem")
  return state and state.window and state.window.position
end

---Check if Neo-tree is open in current tab
---@return boolean
function M.is_neotree_open()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neo-tree" then
        return true
      end
    end
  end
  return false
end

return M

