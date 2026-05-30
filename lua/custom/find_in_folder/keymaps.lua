---@module 'custom.find_in_folder.keymaps'
---@brief Registers <leader>fb keymap.

local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>fb", function()
    require("custom.find_in_folder.core").run({})
  end, {
    desc   = "Find in folder",
    silent = true,
    noremap = true,
  })
end

return M
