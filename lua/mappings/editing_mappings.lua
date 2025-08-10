---@module 'mappings.editing'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>+", function() vim.cmd("vertical resize +5") end, { desc = "[Window] Increase width" })
  map("n", "<leader>-", function() vim.cmd("vertical resize -5") end, { desc = "[Window] Decrease width" })

  -- Insert empty line above on <CR> without moving cursor
  map("n", "<CR>", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { "" })
    vim.api.nvim_win_set_cursor(0, { row, col })
  end, { desc = "[Text] Insert line above" })

  -- Insert line below and move to beginning
  map({ "n", "i", "v" }, "<A-CR>", "o<Esc>^", { desc = "[Text] Insert line below, go to BOL" })

  -- Move selected lines
  map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "[Text] Move selection up" })
  map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "[Text] Move selection down" })

  -- Navigation fix for <A-h> in insert
  vim.schedule(function()
    pcall(vim.keymap.del, "i", "<A-h>")
    vim.keymap.set("i", "<A-h>", "<Left>", { desc = "[Navigation] Move left (insert)", noremap = true, silent = true })
  end)
end

return M
