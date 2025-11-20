---@module 'mappings.editing'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- Branch-aware redo/undo that survives auto-changes by plugins
  map("n", "<C-r>", "g+", { desc = "Redo (branch-aware)" })

  -- Insert blank lines
  map("n", "<leader><CR>", "o<Esc>k", { desc = "Insert blank line below" })
  map("n", "<CR>", "0i<CR><Esc>k", { desc = "Insert blank line" })

  -- Move selected lines (unchanged as requested)
  map("n", "<A-Up>", ":m .-2<CR>==", { desc = "[Text] Move line up", noremap = true, silent = true })
  map("n", "<A-Down>", ":m .+1<CR>==", { desc = "[Text] Move line down", noremap = true, silent = true })
  map("i", "<A-Up>", "<C-o>:m .-2<CR><C-o>==", { desc = "[Text] Move line up", noremap = true, silent = true })
  map("i", "<A-Down>", "<C-o>:m .+1<CR><C-o>==", { desc = "[Text] Move line down", noremap = true, silent = true })
  map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "[Text] Move selection up", noremap = true, silent = true })
  map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "[Text] Move selection down", noremap = true, silent = true })

  -- Indent / Outdent
  map("n", "<A-Right>", function()
    return string.rep(">>", vim.v.count1)
  end, { desc = "[Text] Indent current line", noremap = true, silent = true, expr = true })
  map("n", "<A-Left>", function()
    return string.rep("<<", vim.v.count1)
  end, { desc = "[Text] Outdent current line", noremap = true, silent = true, expr = true })
  map("i", "<A-Right>", "<C-t>", { desc = "[Text] Indent line (insert)", noremap = true, silent = true })
  map("i", "<A-Left>", "<C-d>", { desc = "[Text] Outdent line (insert)", noremap = true, silent = true })
  map("v", "<A-Right>", ">gv", { desc = "[Text] Indent selection", noremap = true, silent = true })
  map("v", "<A-Left>", "<gv", { desc = "[Text] Outdent selection", noremap = true, silent = true })
end

return M
