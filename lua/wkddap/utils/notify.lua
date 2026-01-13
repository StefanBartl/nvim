---@module 'wkddap.utils.notify'

--FIX: LIB

local M = {}

local prefix = "[wkddap]"

function M.info(msg)
  vim.notify(string.format("%s %s", prefix, msg), vim.log.levels.INFO)
end

function M.warn(msg)
  vim.notify(string.format("%s %s", prefix, msg), vim.log.levels.WARN)
end

function M.error(msg)
  vim.notify(string.format("%s %s", prefix, msg), vim.log.levels.ERROR)
end

function M.debug(msg)
  if vim.log.levels.DEBUG >= vim.log.levels.DEBUG then
    vim.notify(string.format("%s %s", prefix, msg), vim.log.levels.DEBUG)
  end
end

return M
