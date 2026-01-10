---@module 'custom.commands_keymaps'

---@class Custom.CmdsKms.Config
---@field delete_current_file boolean

local M = {}

---@param opts Custom.CmdsKms.Config|nil
---@return nil
function M.setup(opts)
  if opts and opts.delete_current_file == true then
    require("custom.commands_keymaps.delete_current_file") --FIX enable attach
  end
end

return M
