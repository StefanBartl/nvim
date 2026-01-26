---@module 'wkdoptions.commands.highlight'
--- Highlight-related user command registration.
--- Commands: WKDHighlightSet, WKDHighlightShow, WKDHighlightList

local lazy = require("lib.lazy")
local notify = lazy.require("lib.notify").create("[Commands.Highlight]")
local Core = lazy.require("wkdoptions.commands.core")
local C = lazyrequire("wkdoptions.config")

local M = {}

--- Register highlight-related user commands.
---@param spec WKDOptions.Commands.HL_Spec
---@return nil
function M.register(spec)
  if type(spec) ~= "table" then
    notify.error("register_highlight_commands: spec required")
    return
  end

  if type(spec.show_table) ~= "table" then
    notify.error("register_highlight_commands: spec.show_table must be a table")
    return
  end

  local names = vim.tbl_extend(
    "force",
    { set = "WKDHighlightSet", show = "WKDHighlightShow", list = "WKDHighlightList" },
    spec.names or {}
  )

  -- :WKDHighlightSet
  Core.define_cmd(names.set, function(opts)
    local key, value_str = Core.parse_args(opts.fargs)

    if not key then
      notify.info(("Usage: :%s {keypath} {value}"):format(names.set))
      return
    end

    local toggle = (opts.bang == true) and (value_str == nil or value_str == "")
    local value = C.parse(value_str)

    local ok, err = C.set("highlight", key, value, toggle)
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
    return C.keys("highlight")
  end) })

  -- :WKDHighlightShow
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

  -- :WKDHighlightList
  Core.define_cmd(names.list, function()
    local keys = C.keys("highlight")
    local lines = { "Highlight keys:" }
    for i = 1, #keys do
      lines[#lines + 1] = "  " .. keys[i]
    end
    notify.info(table.concat(lines, "\n"))
  end, {})
end

return M
