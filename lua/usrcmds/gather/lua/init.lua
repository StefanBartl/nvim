---@module 'usrcmds.gather.lua'
---@description Entry point for Lua gather commands using hover selection

local hover_select = require("lib.hover_select")
local notify = vim.notify

local M = {}

---@type table<string, fun(): nil>
local gatherers = {
  functions = function()
    require("usrcmds.gather.lua.functions").run()
  end,
  tables = function()
    require("usrcmds.gather.lua.tables").run()
  end,
  strings = function()
    require("usrcmds.gather.lua.strings").run()
  end,
}

---Open hover selection and dispatch to the selected gatherer
function M.run()
  hover_select.open({
    title = "Lua gather",
    items = {
      "functions",
      "tables",
      "strings",
    },
    on_select = function(selected)
      local handler = gatherers[selected]
      if not handler then
        notify("Unknown gather target: " .. selected, vim.log.levels.ERROR)
        return
      end
      handler()
    end,
  })
end

return M

