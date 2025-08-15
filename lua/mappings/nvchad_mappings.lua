---@module 'mappings.nvchad'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- General
  map("n", "<Esc>", "<cmd>noh<CR>", { desc = "[General] Clear highlights" })
  map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "[General] Copy whole file" })
  map("n", "<leader>tln", "<cmd>set nu!<CR>", { desc = "[General] Toggle number" })
  map("n", "<leader>trn", "<cmd>set rnu!<CR>", { desc = "[General] Toggle relativenumber" })
  map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "[General] NvCheatsheet" })

  -- Format via Conform (fallback handled in LSP attach)
  map({ "n", "x" }, "<leader>fm", function()
    local ok, conform = pcall(require, "conform"); if ok then conform.format { lsp_fallback = true } end
  end, { desc = "[General] Format file" })

  -- Which-key
  map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "[General] WhichKey (all)" })
  map("n", "<leader>wk", function()
    vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
  end, { desc = "[General] WhichKey query" })

  -- Insert-mode cursor moves
  map("i", "<C-b>", "<ESC>^i", { desc = "[Text] BOL" })
  map("i", "<C-e>", "<End>", { desc = "[Text] EOL" })
  map("i", "<C-h>", "<Left>", { desc = "[Text] Left" })
  map("i", "<C-l>", "<Right>", { desc = "[Text] Right" })
  map("i", "<C-j>", "<Down>", { desc = "[Text] Down" })
  map("i", "<C-k>", "<Up>", { desc = "[Text] Up" })

  -- Comment.nvim
  map("n", "<leader>/", "gcc", { desc = "[Text] Toggle comment", remap = true })
  map("v", "<leader>/", "gc", { desc = "[Text] Toggle comment", remap = true })
  map("n", "<leader><M-7>", "gcc", { desc = "[Text] Toggle comment linewise", remap = true })
  map("v", "<leader><M-7>", "gc", { desc = "[Text] Toggle comment linewise", remap = true })
  -- NvimTree

  map("n", "<C-q>", "<cmd>NvimTreeToggle<CR>", { desc = "[NvimTree] Toggle" })

  -- Terminals
  map({ "n", "t" }, "<A-v>",
    function()
      local ok, nt = pcall(require, "nvchad.term"); if ok then nt.toggle { pos = "vsp", id = "vtoggleTerm" } end
    end, { desc = "[Term] Toggle vertical" })
  map({ "n", "t" }, "<A-h>",
    function()
      local ok, nt = pcall(require, "nvchad.term"); if ok then nt.toggle { pos = "sp", id = "htoggleTerm" } end
    end, { desc = "[Term] Toggle horizontal" })
  map({ "n", "t" }, "<A-i>",
    function()
      local ok, nt = pcall(require, "nvchad.term"); if ok then nt.toggle { pos = "float", id = "floatTerm" } end
    end, { desc = "[Term] Toggle floating" })
end

return M
