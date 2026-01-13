---@module 'wkddap.commands'

local M = {}

function M.setup(opts)
  if opts.autocmds then
    local ok, autocmds = pcall(require, "wkddap.commands.autocmds")
    if ok then pcall(autocmds.setup) end
  end

  local ok, usercmds = pcall(require, "wkddap.commands.usercmds")
  if ok then pcall(usercmds.setup) end
end

return M
