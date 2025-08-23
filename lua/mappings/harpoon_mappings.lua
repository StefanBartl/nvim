---@module 'mappings.harpoon'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>h", function()
    local ok, m = pcall(require, "harpoon.mark"); if ok then m.add_file() end
  end, { desc = "[Harpoon] Add file" })
  map("n", "<C-e>", function()
    local ok, ui = pcall(require, "harpoon.ui"); if ok then ui.toggle_quick_menu() end
  end, { desc = "[Harpoon] Toggle UI" })
end

return M
