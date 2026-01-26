---@module 'config.neotree.cwd_sync.timer'
---@brief Memoized timer instance for cwd_sync

local memo = require("lib.memo")

---@return uv.uv_timer_t|nil
local get_timer = memo.fn(function()
  local uv = vim.uv or vim.loop
  return uv.new_timer()
end, { size = 1 })

return get_timer
