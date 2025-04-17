-- Deactivate numbers in terminal
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

-- Close open floating terminal
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function(args)
    local bufnr = args.buf

    -- Nur für dein Custom Floating-Terminal
    if vim.api.nvim_buf_get_name(bufnr):find("floaterm") then
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>:lua vim.api.nvim_win_close(0, true)<CR>", {
        buffer = bufnr,
        silent = true,
        desc = "Close floating terminal with ESC"
      })
    end
  end,
})
