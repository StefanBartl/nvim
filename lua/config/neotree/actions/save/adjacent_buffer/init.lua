---@module 'config.neotree.actions.save.adjacent_buffer'
---Helper to force-save the last usable file buffer via :w!
---! Works with neo-tree, netrw, nvim-tree, oil, floating explorers, etc.

local buffer = require("config.neotree.utils.buffer")

return function()
  local buf, win = buffer.find_last_normal_buffer()

  if buf and win then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("w!")
    end)
    return true
  end

  return false
end
