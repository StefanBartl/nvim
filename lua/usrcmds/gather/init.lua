---@module 'usrcmds.gather'
---@description Main entry point for gather user commands

require("usrcmds.gather.@types")

local M = {}

local api = vim.api

--- Setup gather commands
---@param opts UsrCmds.Gather.Config
function M.setup(opts)
  opts = opts or {}

  if opts.lua then
    api.nvim_create_user_command("GatherLua", function(cmd_opts)
      local arg = cmd_opts.args:match("%S+")

      ---@type UsrCmds.Gather.Lua.ScanMode
      local mode = "buffer"

      if arg == "cwd" then
        mode = "cwd"
      elseif arg == "%" or arg == "buffer" or arg == "" then
        mode = "buffer"
      else
        vim.notify("Invalid argument. Use: [empty], %, buffer, or cwd", vim.log.levels.ERROR)
        return
      end

      require("usrcmds.gather.lua").run(mode)
    end, {
      nargs = "?",
      desc = "Gather Lua symbols (functions, tables, strings)",
      complete = function()
        return { "%", "buffer", "cwd" }
      end,
    })
  end
end

return M
