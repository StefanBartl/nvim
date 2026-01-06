---@module 'custom.format.misc'

local M = {}

--- Setup 'misc'-Usercommands
---@return nil
function M.enable_usercmds()
  vim.api.nvim_create_user_command("BufferClear", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  end, {
    desc = "Clear all lines in the current buffer",
  })
end

return M
