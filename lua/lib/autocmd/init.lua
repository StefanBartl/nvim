---@module 'lib.autocmd'
-- =========================================================
-- Autocommand helper utilities.
--
-- Provides standardized autocmd creation with automatic
-- augroup handling and defensive callbacks.
-- =========================================================

local M = {}

---@type table<string, integer>
local groups = {}

---@param name string
---@param clear boolean|nil
---@return integer
function M.group(name, clear)
  if groups[name] == nil then
    groups[name] = vim.api.nvim_create_augroup(name, { clear = clear == true })
  end
  return groups[name]
end

---@class LibAutocmdOpts
---@field group? string|integer
---@field pattern? string|string[]
---@field desc? string
---@field once? boolean
---@field nested? boolean

---@param event string|string[]
---@param callback fun(args:vim.api.keyset.autocmd)
---@param opts LibAutocmdOpts|nil
function M.create(event, callback, opts)
  opts = opts or {}

  if opts.desc == nil then
    opts.desc = ""
  end

  local group = opts.group
  if type(group) == "string" then
    group = M.group(group)
  end

  local user_cb = callback
  callback = function(args)
    local ok, err = pcall(user_cb, args)
    if not ok then
      vim.notify(
        ("Autocmd failed (%s):\n%s"):format(
          table.concat(vim.tbl_flatten({ event }), ", "),
          err
        ),
        vim.log.levels.ERROR
      )
    end
  end

  vim.api.nvim_create_autocmd(event, {
    group = group,
    pattern = opts.pattern,
    desc = opts.desc,
    once = opts.once == true,
    nested = opts.nested == true,
    callback = callback,
  })
end

return M

