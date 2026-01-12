---@module 'lib.usercmd'
-- =========================================================
-- User command helper utilities.
--
-- Standardized wrapper around nvim_create_user_command with
-- sane defaults, defensive execution and LuaLS annotations.
-- =========================================================

local M = {}

---@class LibUserCommandOpts
---@field nargs? string|integer
---@field bang? boolean
---@field range? boolean|integer
---@field count? integer
---@field complete? string|fun(arg_lead:string, cmd_line:string, cursor_pos:number):string[]
---@field desc? string
---@field force? boolean

---@param name string
---@param callback string|fun(args:vim.api.keyset.user_command)
---@param opts LibUserCommandOpts|nil
function M.create(name, callback, opts)
  opts = opts or {}

  if opts.desc == nil then
    opts.desc = ""
  end

  if opts.nargs == nil then
    opts.nargs = 0
  end

  local force = opts.force == true
  opts.force = nil

  if type(callback) == "function" then
    local user_cb = callback
    callback = function(args)
      local ok, err = pcall(user_cb, args)
      if not ok then
        vim.notify(
          ("UserCommand '%s' failed:\n%s"):format(name, err),
          vim.log.levels.ERROR
        )
      end
    end
  end

  vim.api.nvim_create_user_command(name, callback, opts, force)
end

return M

