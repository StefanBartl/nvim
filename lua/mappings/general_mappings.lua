---@module 'mappings.general'
-- General purpose keymaps (F1 disable, save, esc helpers).

-- WHIHKEY


local M = {}

function M.setup()
  local map = vim.g.__map_helper

  for _, mode in ipairs({ "n", "i", "v", "t", "c" }) do
    map(mode, "<F1>", "<Nop>", { desc = "[General] Disable F1" })
  end

  map("n", "<leader><Esc>", function()
    require("custom.last_file.last_session").save()
    vim.cmd("qa!")
  end, { desc = "[General] Save lasz file and Force quit all" })

  map("n", "<C-z>", "gg<S-v>G", { desc = "[General] Select all" })
  map({ "n", "i", "v", "t" }, "<C-s>", function()
    if vim.fn.mode() ~= "n" then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    end
    vim.cmd("silent! w!")
  end, { desc = "[General] Save file silently" })

  map({ "n", "i", "v", "t" }, "<C-s>", "<cmd>w<CR>", { desc = "[General] Save file" })
  map({ "i", "v", "t" }, "jk", "<Esc>", { desc = "[General] Exit to normal mode" })

  map("n", "+", "<C-a>", { desc = "[Number] Increment" })
  map("n", "-", "<C-x>", { desc = "[Number] Decrement" })
  map("n", "x", '"_x', { desc = "[Edit] Delete char without yanking" })
  map("n", "dw", 'vb"_d', { desc = "[Edit] Delete word backwards without yanking" })

  -- Resize window
  map("n", "<A-Left>", "<cmd>vertical resize -5<CR>", { desc = "[Window] Resize narrower" })
  map("n", "<A-Right>", "<cmd>vertical resize +5<CR>", { desc = "[Window] Resize wider" })
  map("n", "<A-Up>", "<cmd>resize +5<CR>", { desc = "[Window] Resize taller" })
  map("n", "<A-Down>", "<cmd>resize -5<CR>", { desc = "[Window] Resize shorter" })

  -- NOTE: Check this out for some time
  -- Improved wrapped-line movement with auto-centering
  -- After movement, center the cursor (zz) for better visibility
  -- If no count is given: move by screen line (gj/gk)
  -- If a count is given: move by physical line (j/k)
  --map({ "n", "x" }, "j",
  --  "v:count == 0 ? 'gjzz' : 'jzz'",
  --  { desc = "Down (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
  --)
  --
  --map({ "n", "x" }, "<Down>",
  --  "v:count == 0 ? 'gjzz' : 'jzz'",
  --  { desc = "Down (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
  --)
  --
  --map({ "n", "x" }, "k",
  --  "v:count == 0 ? 'gkzz' : 'kzz'",
  --  { desc = "Up (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
  --)
  --
  --map({ "n", "x" }, "<Up>",
  --  "v:count == 0 ? 'gkzz' : 'kzz'",
  --  { desc = "Up (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
  --)
end

return M
