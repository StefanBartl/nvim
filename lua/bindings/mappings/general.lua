---@module 'bindings.mappings.general'
--- Editor-wide keymaps that belong to no plugin: `<C-a>` select all, `<C-s>` save,
--- `jk` to leave insert mode, and yank-free `x`/`dw`.

local M = {}

function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  map("n", "<C-a>", "gg<S-v>G", { desc = "[General] Select all" })

  map({ "n", "v", "t" }, "<C-s>", function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("write")

    -- Clamp: the file may be shorter after a save-time formatter ran.
    local last_line = vim.api.nvim_buf_line_count(0)
    if pos[1] > last_line then
      pos[1] = last_line
    end
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end, { desc = "[General] Save file" })
  map("i", "<C-s>", function() -- explicit i-mode map so it beats vim.lsp.buf.signature_help()
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

  -- Insert today's date as dd.mm.yyyy. buffer-ctx.nvim's :Insert can also
  -- place timestamps, but this is the one-key shortcut for the common case.
  map("n", "<leader>date", function()
    vim.api.nvim_put({ tostring(os.date("%d.%m.%Y")) }, "c", false, true)
  end, { desc = "[General] Insert date" })
end

return M
