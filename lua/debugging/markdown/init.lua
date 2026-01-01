---@module 'debugging.markdown'

local M = {}
---@param opts markdown_modules
---@return nil
function M.attach(opts)
  opts = opts or {}

  if opts.inline_debug_fixed and opts.inline_debug_fixed == true then
    require("debugging.markdown.inline_debug")
  end
end

return M
