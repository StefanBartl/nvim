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
      local mode = "buffer"  -- Default is buffer mode

      if arg == "cwd" then
        mode = "cwd"
      -- All other cases (%, buffer, or empty) default to buffer mode
      end

      require("usrcmds.gather.lua").run(mode)
    end, {
      nargs = "?",
      desc = "Gather Lua symbols (functions, tables, strings). Default: buffer mode. Use 'cwd' for project-wide",
      complete = function()
        return { "%", "cwd" }
      end,
    })
  end
end

return M
