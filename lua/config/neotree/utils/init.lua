---@module 'config.neotree.utils'
---@brief Unified utilities for Neo-tree configuration

local M = {}

---Safe hide Neo-tree preview
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
---@return string|nil position
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
