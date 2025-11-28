---@module 'config.telescope.selected_index.config'


local M = {}

---@alias position 'overlay'|'right'|'eol'|'top'|'down'

M.config = {
    ---@type position
    position = 'right',
}

---@class SetupOpts
---@field position position

---@param opts SetupOpts
function M.setup(opts)
   if opts.position and type(opts.position) == 'string' then
    M.config.position = opts.position and opts.position or 'right'
   end
end

return M
