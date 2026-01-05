---@module 'debugging.nvim_options'

local M = {}

---@param opts Dbg.NvimOpts.Modules|nil
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.indent_helpers and opts.indent_helpers == true or opts.all == true then
    require("debugging.nvim_options").enable()
  end
end

return M
