---@module 'lib.notify'
---Generic notification factory for Neovim configs
---Allows per-module prefix configuration while mirroring vim.notify semantics
require("lib.notify.@types")

local M = {}

---Create a prefixed notify helper
---@param prefix string Notification prefix, e.g. "[neotree-fs-refactor]"
---@return Lib.Notify.Notifier
function M.create(prefix)
  -- Normalize prefix once
  if type(prefix) ~= "string" then
    prefix = ""
  end

  if prefix ~= "" and not prefix:match("%s$") then
    prefix = prefix .. " "
  end

  ---@type Lib.Notify.Notifier
  local notifier = {}

  ---Core notify function
  ---@param msg string
  ---@param level? integer
  ---@param opts? table
  function notifier.notify(msg, level, opts)
    if type(msg) ~= "string" then
      msg = tostring(msg)
    end

    level = level or vim.log.levels.INFO
    opts = opts or {}

    vim.notify(prefix .. msg, level, opts)
  end

  ---@param msg string
  ---@param opts? table
  function notifier.info(msg, opts)
    notifier.notify(msg, vim.log.levels.INFO, opts)
  end

  ---@param msg string
  ---@param opts? table
  function notifier.warn(msg, opts)
    notifier.notify(msg, vim.log.levels.WARN, opts)
  end

  ---@param msg string
  ---@param opts? table
  function notifier.error(msg, opts)
    notifier.notify(msg, vim.log.levels.ERROR, opts)
  end

  ---@param msg string
  ---@param opts? table
  function notifier.debug(msg, opts)
    notifier.notify(msg, vim.log.levels.DEBUG, opts)
  end

  return notifier
end

return M
