---@module 'custom.utils.notify_patch'

local original_notify = vim.notify

vim.notify = function(msg, ...)
  if type(msg) == "string" then
    -- Pfadbereinigung: \ -> /
    msg = msg:gsub("\\", "/")
  end
  return original_notify(msg, ...)
end
