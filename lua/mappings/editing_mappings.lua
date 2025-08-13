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
-- Move current line up/down in normal mode
map("n", "<A-Up>", ":m .-2<CR>==", { desc = "[Text] Move line up", noremap = true, silent = true })
map("n", "<A-Down>", ":m .+1<CR>==", { desc = "[Text] Move line down", noremap = true, silent = true })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "[Text] Move line up", noremap = true, silent = true })
map("n", "<A-j>", ":m .+1<CR>==", { desc = "[Text] Move line down", noremap = true, silent = true })

-- Preserve behaviour in visual mode (optional, falls du auch mehrere Zeilen verschieben willst)
map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "[Text] Move selection up", noremap = true, silent = true })
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "[Text] Move selection down", noremap = true, silent = true })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "[Text] Move selection up", noremap = true, silent = true })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "[Text] Move selection down", noremap = true, silent = true })

-- Normal mode: indent right / left
map("n", "<A-Right>", ">>", { desc = "[Custom] Indent current line right" })
map("n", "<A-Left>", "<<", { desc = "[Custom] Indent current line left" })

-- Visual mode: indent selection right / left and reselect
map("v", "<A-Right>", ">gv", { desc = "[Custom] Indent selection right" })
map("v", "<A-Left>", "<gv", { desc = "[Custom] Indent selection left" })

  -- Navigation fix for <A-h> in insert
  vim.schedule(function()
    pcall(vim.keymap.del, "i", "<A-h>")
    vim.keymap.set("i", "<A-h>", "<Left>", { desc = "[Navigation] Move left (insert)", noremap = true, silent = true })
  end)
end

return M
