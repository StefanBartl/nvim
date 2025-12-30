---@module 'usrcmds.gather'

local M = {}

---@class UsrCmds.Gather.Config
---@field lua boolean

---@param opts UsrCmds.Gather.Config
---@return nil
function M.setup(opts)
  if opts.lua then
    vim.api.nvim_create_user_command("GatherLua", function()
      require("usrcmds.gather.lua").run()
    end, { desc = "Gather Lua symbols (functions, tables, strings)" })
  end
end

return M
