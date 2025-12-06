---@module 'mappings.telescope'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>os", function()
    require("search").open()
  end, { desc = "[Telescope] Multi search UI" })
  map("n", "<leader>ts", ":Telescope<CR>", { desc = "[Telescope] UI" })

  map("n", "<leader>tg", function()
    local ok, tb = pcall(require, "telescope.builtin")
    if not ok then
      return
    end
    tb.grep_string({ search = vim.fn.input("Grep > ") })
  end, { desc = "[Telescope] Grep" })

  map("n", "<leader><leader>", "<cmd>Telescope live_grep<CR>", { desc = "[Telescope] Live Grep" })
  map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "[Telescope] Find keymaps" })
  map("n", "<leader>bu", "<cmd>Telescope buffers<CR>", { desc = "[Telescope] Buffers" })
  map("n", "<leader>com", "<cmd>Telescope commands<CR>", { desc = "[Telescope] Commands" })
  map("n", "<leader>com", "<cmd>Telescope colorscheme<CR>", { desc = "[Telescope] Colorscheme" })
  map("n", "<leader>help", "<cmd>Telescope help_tags<CR>", { desc = "[Telescope] Help" })
  map("n", "<leader>old", "<cmd>Telescope oldfiles<CR>", { desc = "[Telescope] Oldfiles" })
  map("n", "<leader>cb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "[Telescope] In Buffer" })
  map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "[Telescope] Find Files" })
  map(
    "n",
    "<leader>fa",
    "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "[Telescope] Find All Files" }
  )
end

return M
