---@module 'wkdoptions.commands.options'
--- Options-related user command registration.
--- Commands: WKDOptSet, WKDOptShow, WKDOptList

local Core = require("wkdoptions.commands.core")
local C = require("wkdoptions.config")
local notify = require("lib.nvim.notify").create("[Commands.Options]")

local M = {}

--- Register options-related user commands.
---@param spec WKDOptions.Commands.Opt_Spec
---@return nil
function M.register(spec)
  if type(spec) ~= "table" then
    notify.error("register_options_commands: spec required")
    return
  end

  if type(spec.show_table) ~= "table" then
    notify.error("register_options_commands: spec.show_table must be a table")
    return
  end

  local names = vim.tbl_extend(
    "force",
    { set = "WKDOptSet", show = "WKDOptShow", list = "WKDOptList" },
    spec.names or {}
  )

  -- :WKDOptSet
  Core.define_cmd(names.set, function(opts)
    local key, value_str = Core.parse_args(opts.fargs)

    if not key then
      notify.info(("Usage: :%s {keypath} {value}"):format(names.set))
      return
    end

    local toggle = (opts.bang == true) and (value_str == nil or value_str == "")
    local value = C.parse(value_str)

    local ok, err = C.set("options", key, value, toggle)
    if not ok then
      notify.error(("%s: %s"):format(names.set, tostring(err or "unknown error")))
      return
    end

    if type(spec.after_set) == "function" then
      pcall(spec.after_set, key)
    end

    local msg = toggle and ("toggled " .. key) or (key .. " = " .. vim.inspect(value))
    notify.info(("%s: %s"):format(names.set, msg))
  end, { bang = true, nargs = "+", complete = Core.make_complete(function()
    return C.keys("options")
  end) })

  -- :WKDOptShow
  Core.define_cmd(names.show, function(opts)
    local key = opts.fargs[1]
    if not key or key == "" then
      notify.info(vim.inspect(spec.show_table))
      return
    end

    local node = Core.get_by_path(spec.show_table, key)
    if node == nil then
      notify.warn(("%s: unknown key '%s'"):format(names.show, key))
      return
    end

    notify.info(("%s = %s"):format(key, vim.inspect(node)))
  end, { nargs = "?" })

  -- :WKDOptList
  Core.define_cmd(names.list, function()
    local keys = C.keys("options")
    local lines = { "Options keys:" }
    for i = 1, #keys do
      lines[#lines + 1] = "  " .. keys[i]
    end
    notify.info(table.concat(lines, "\n"))
  end, {})
end

return M
