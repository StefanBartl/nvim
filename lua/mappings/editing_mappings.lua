---@module 'mappings.editing'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>+", function() vim.cmd("vertical resize +5") end, { desc = "[Window] Increase width" })
  map("n", "<leader>-", function() vim.cmd("vertical resize -5") end, { desc = "[Window] Decrease width" })

  -- Mapping: Insert blank line above (safe)
  local text = require("utils.text")
  if type(text) ~= "table" or type(text.insert_blank_line_above) ~= "function" then
    error("utils.text must return a table with function 'insert_blank_line_above'")
  end

  vim.keymap.set("n", "<CR>", function()
    text.insert_blank_line_above({
      keep_cursor_on_text = true,
      notify = true,
    })
  end, { desc = "[Text] Insert blank line above (safe)" })

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
