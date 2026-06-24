---@module 'bindings.mappings.custom'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>cp", function()
    vim.fn.setreg("+", vim.fn.expand("%:p"))
    print("Copied path to clipboard")
  end, { desc = "[General] Copy file path" })

end

return M
