---@module 'wkddap.utils.notify'

--FIX: LIB

local notify = require("lib.notify").create("[wkddap.utils.notify]")

local M = {}

local prefix = "[wkddap]"

function M.info(msg)
  notify.info(string.format("%s %s", prefix, msg))
end

function M.warn(msg)
  notify.warn(string.format("%s %s", prefix, msg))
end

function M.error(msg)
  notify.error(string.format("%s %s", prefix, msg))
end

function M.debug(msg)
  if vim.log.levels.DEBUG >= vim.log.levels.DEBUG then
    notify.debug(string.format("%s %s", prefix, msg))
  end
end

return M
