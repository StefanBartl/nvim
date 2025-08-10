---@module 'mappings.floaterm'

local M = {}

function M.setup()
  local map = vim.g.__map_helper
  local toggle_cmd = [[<C-\><C-n>:lua require("floaterm").toggle()<CR>]]

  map("t", "<C-t>", toggle_cmd, { desc = "[Floaterm] Toggle (terminal)" })
  map("n", "<C-t>", function()
    local ok, f = pcall(require, "floaterm"); if ok then f.toggle() end
  end, { desc = "[Floaterm] Toggle (normal)" })
end

return M
