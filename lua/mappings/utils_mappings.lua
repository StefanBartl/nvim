---@module 'mappings.utils'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- Counters
  map("n", "<leader>uz", ":echo len(join(getline(1, '$'), ''))<CR>", { desc = "[Text] Count chars" })
  map("n", "<leader>uw", ":echo len(split(join(getline(1, '$'), ''), '\\s\\+'))<CR>", { desc = "[Text] Count words" })

  -- Clipboard helpers
  map("n", "copyz", ':let @+=getline(".")<CR>:echo "Copy current line to clipboard"<CR>',
    { desc = "[Text] Copy line to clipboard" })
  map("n", "cpe", ':.,$y+<CR>:echo "Copied from cursor to EOF to clipboard"<CR>',
    { desc = "[Text] Copy from cursor to EOF" })
  map("n", "cpf", ':%y+<CR>:echo "Copied entire file to clipboard"<CR>', { desc = "[Text] Copy entire file" })
  map("v", "cps", '"+y<CR>:echo "Copied selected text to clipboard"<CR>', { desc = "[Text] Copy selection" })
end

return M
