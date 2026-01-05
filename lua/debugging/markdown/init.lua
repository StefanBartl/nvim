---@module 'debugging.markdown'

local M = {}
---@param opts Dbg.Markdown.Modules
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.inline_debug_fixed and opts.inline_debug_fixed == true or opts.all == true then
    require("debugging.markdown.inline_debug").enable()
  end
end

return M
