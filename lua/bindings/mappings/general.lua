---@module 'bindings.mappings.general'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<C-a>", "gg<S-v>G", { desc = "[General] Select all" })

  -- map({ "n", "i", "v", "t" }, "<C-s>", function()
  --   if vim.fn.mode() ~= "n" then
  --     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  --   end
  --   vim.cmd "silent! w!"
  -- end, { desc = "[General] Save file silently" })
  map({ "n", "v", "t" }, "<C-s>", function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("write")

    -- Verhindert Fehler, falls die Datei nach dem Speichern/Formatieren kürzer ist
    local last_line = vim.api.nvim_buf_line_count(0)
    if pos[1] > last_line then
        pos[1] = last_line
    end
    pcall(vim.api.nvim_win_set_cursor, 0, pos)

  end, { desc = "[General] Save file" })
  map("i", "<C-s>", function() --- explicit because of vim.lsp.buf.signature_help()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("write")

    local last_line = vim.api.nvim_buf_line_count(0)
    if pos[1] > last_line then
        pos[1] = last_line
    end
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end, { desc = "[General] Save file", noremap = true })

  map({ "i", "v", "t" }, "jk", "<Esc>", { desc = "[General] Exit to normal mode" })
  map("n", "x", '"_x', { desc = "[Edit] Delete char without yanking" })
  map("n", "dw", 'vb"_d', { desc = "[Edit] Delete word backwards without yanking" })
  map(
    { "n", "i", "v", "t", "c" },
    "<F1>",
    "<Nop>",
    { desc = "[General] Disable F1", silent = true }
  )

  -- Fügt das aktuelle Datum ein (z. B. 10.07.2026) buffer-ctx.nvim!
  vim.keymap.set("n", "<leader>date", function()
    vim.api.nvim_put({ os.date("%d.%m.%Y") }, "c", false, true)
  end, { desc = "Datum einfügen" })
end

return M
