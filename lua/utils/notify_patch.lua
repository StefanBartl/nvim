---@module 'utils.notify_patch'

-- Save reference to the original notify function
---@type fun(msg: string|any, ...: any): any
local original_notify = vim.notify

--- Override vim.notify to normalize path separators in messages
--- Converts Windows-style backslashes (`\`) to forward slashes (`/`)
---@param msg string|any Message to display in the notification
---@param ... any Additional arguments passed to the original notify
---@return any Return value from the original notify function
vim.notify = function(msg, ...)
  if type(msg) == "string" then
    -- Path normalization: replace backslashes with forward slashes
    msg = msg:gsub("\\", "/")
  end
  return original_notify(msg, ...)
end
