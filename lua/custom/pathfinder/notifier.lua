---@module 'custom.pathfinder.notifier'
--- Simple wrapper around vim.notify to centralize debug/verbosity.
--- All messages go through this module so behavior can be changed centrally.

local M = {}

-- map verbosity strings to vim log levels
local levels = {
  error = vim.log.levels.ERROR,
  warn  = vim.log.levels.WARN,
  info  = vim.log.levels.INFO,
  debug = vim.log.levels.DEBUG,
}

--- Notify helper
---@param msg string
---@param level? string|integer optional; if string, one of "error","warn","info","debug"
function M.notify(msg, level)
  if vim.g.PATHFINDER_LOG ~= true then return end

  local lvl
  if type(level) == "string" then
    lvl = levels[level] or vim.log.levels.INFO
  elseif type(level) == "number" then
    lvl = level
  else
    lvl = vim.log.levels.INFO
  end

  -- ensure safe call in environments without vim.notify replacement
  pcall(vim.notify, ("[pathfinder] %s"):format(msg), lvl)
end

return M
