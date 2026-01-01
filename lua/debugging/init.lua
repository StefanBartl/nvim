---@module 'debugging'

local M = {}

---@param opts debugging_setup|nil
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.autocmds or opts.all == true then
    require("debugging.autocmds").enable(opts.autocmds)
  end

  if opts.markdown or opts.all == true then
    require("debugging.markdown").attach(opts.markdown)
  end

  if opts.terminals or opts.all == true then
    require("debugging.terminals").attach(opts.terminals)
  end

  if opts.views ~= false or opts.all == true then
    require("debugging.views").setup(opts.views or {})
  end

  -- User commands (BufReport, TabReport, WinReport)
  if opts.usercmds ~= false or opts.all == true then
    require("debugging.usercmds").enable()
  end
end

return M
