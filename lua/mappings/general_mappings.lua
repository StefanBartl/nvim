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
  end, { desc = "[General] Force quit all" })

 map({ "n", "i", "v", "t" }, "<C-s>", function()
  -- Exit insert/terminal mode before saving
  if vim.fn.mode() ~= "n" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end
  vim.cmd("silent! w!")
end, { desc = "[General] Save file silently" })



-- Improved wrapped-line movement with auto-centering
-- If no count is given: move by screen line (gj/gk)
-- If a count is given: move by physical line (j/k)
-- After movement, center the cursor (zz) for better visibility
map({ "n", "x" }, "j",
  "v:count == 0 ? 'gjzz' : 'jzz'",
  { desc = "Down (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
)

map({ "n", "x" }, "<Down>",
  "v:count == 0 ? 'gjzz' : 'jzz'",
  { desc = "Down (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
)

map({ "n", "x" }, "k",
  "v:count == 0 ? 'gkzz' : 'kzz'",
  { desc = "Up (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
)

map({ "n", "x" }, "<Up>",
  "v:count == 0 ? 'gkzz' : 'kzz'",
  { desc = "Up (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
)



-- Smart movement for wrapped lines + auto-centering
-- j/k/<Down>/<Up>:
--   - No count  → move by screen line (gj/gk)
--   - With count → move by physical line (j/k)
--   - Always center after move (zz)
-- gJ/gK:
--   - No count  → move by 5 screen lines down/up
--   - With count → move by count*5 screen lines down/up
--   - Always center after move (zz)

-- Standard down/up (1 line)
-- map({ "n", "x" }, "j",
--   "v:count == 0 ? 'gjzz' : 'jzz'",
--   { desc = "Down (smart: wrapped-line aware, centers)", expr = true, silent = true }
-- )
--
-- map({ "n", "x" }, "<Down>",
--   "v:count == 0 ? 'gjzz' : 'jzz'",
--   { desc = "Down (smart: wrapped-line aware, centers)", expr = true, silent = true }
-- )
--
-- map({ "n", "x" }, "k",
--   "v:count == 0 ? 'gkzz' : 'kzz'",
--   { desc = "Up (smart: wrapped-line aware, centers)", expr = true, silent = true }
-- )
--
-- map({ "n", "x" }, "<Up>",
--   "v:count == 0 ? 'gkzz' : 'kzz'",
--   { desc = "Up (smart: wrapped-line aware, centers)", expr = true, silent = true }
-- )
--
-- -- Fast down/up (5 screen lines at once)
-- map({ "n", "x" }, "gJ",
--   "v:count == 0 ? '5gjzz' : (v:count * 5) .. 'gjzz'",
--   { desc = "Fast down (5× smart screen lines, centers)", expr = true, silent = true }
-- )
--
-- map({ "n", "x" }, "gK",
--   "v:count == 0 ? '5gkzz' : (v:count * 5) .. 'gkzz'",
--   { desc = "Fast up (5× smart screen lines, centers)", expr = true, silent = true }
-- )
--




 map({ "n", "i", "v", "t" }, "<C-s>", "<cmd>w<CR>", { desc = "[General] Save file" })
  map({ "i", "v", "t" }, "jk", "<Esc>", { desc = "[General] Exit to normal mode" })

map("n", "x", '"_x', { desc = "[Edit] Delete char without yanking" })
map("n", "+", "<C-a>", { desc = "[Number] Increment" })
map("n", "-", "<C-x>", { desc = "[Number] Decrement" })
map("n", "dw", 'vb"_d', { desc = "[Edit] Delete word backwards without yanking" })
map("n", "<C-a>", "gg<S-v>G", { desc = "[General] Select all" })

-- Zeilenfortsetzung verhindern
map("n", "<Leader>o", "o<Esc>^Da", { desc = "[Edit] New line below without continuation" })
map("n", "<Leader>O", "O<Esc>^Da", { desc = "[Edit] New line above without continuation" })

map("n", "te", ":tabedit<CR>", { desc = "[Tab] New tab" })

map("n", "ss", ":split<CR>", { desc = "[Window] Horizontal split" })
map("n", "sv", ":vsplit<CR>", { desc = "[Window] Vertical split" })

map("n", "sh", "<C-w>h", { desc = "[Window] Focus left" })
map("n", "sk", "<C-w>k", { desc = "[Window] Focus up" })
map("n", "sj", "<C-w>j", { desc = "[Window] Focus down" })
map("n", "sl", "<C-w>l", { desc = "[Window] Focus right" })

map("n", "<C-w><left>", "<C-w><", { desc = "[Window] Resize left" })
map("n", "<C-w><right>", "<C-w>>", { desc = "[Window] Resize right" })
map("n", "<C-w><up>", "<C-w>+", { desc = "[Window] Resize up" })
map("n", "<C-w><down>", "<C-w>-", { desc = "[Window] Resize down" })

-- Craftzdog custom
map("n", "<leader>hsl", function()
  require("utils.craftzdog.hsl").replaceHexWithHSL()
end, { desc = "[Craftzdog] Replace hex color with HSL in current line" })

map("n", "<leader>i", function()
  require("craftzdog.lsp").toggleInlayHints()
end, { desc = "[Craftzdog] Toggle inlay hints" })

vim.api.nvim_create_user_command("ToggleAutoformat", function()
  require("craftzdog.lsp").toggleAutoformat()
end, { desc = "[Craftzdog] Toggle autoformat" })


end

return M
