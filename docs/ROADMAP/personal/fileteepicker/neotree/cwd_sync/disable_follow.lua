---@module 'config.neotree.cwd_sync.disable_follow'
---@brief Permanently disable Neo-tree's problematic follow behavior

local M = {}

---Disable neo-tree-follow event completely
---@return boolean success
function M.disable_follow()
  local ok, events = pcall(require, "neo-tree.events")
  if not ok or not events or not events._handlers then
    return false
  end

  -- Replace with safe no-op
  if events._handlers["neo-tree-follow"] then
    events._handlers["neo-tree-follow"] = function() end
    return true
  end

  return false
end

---Setup: disable follow on Neo-tree load
function M.setup()
  -- Disable immediately if Neo-tree is already loaded
  M.disable_follow()

  -- Also disable on Neo-tree initialization
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "neo-tree",
    once = true,
    callback = function()
      vim.defer_fn(function()
        M.disable_follow()
      end, 100)
    end,
    desc = "Disable Neo-tree follow behavior",
  })
end

return M
