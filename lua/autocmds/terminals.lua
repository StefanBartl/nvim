---@description
---   Disable absolute and relative line numbers in any terminal buffer.
---   Triggered automatically on the 'TermOpen' event.
---   Useful to reduce visual clutter in embedded or floating terminals.
---@event TermOpen
---@group custom-term-open
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

---@description
--- Bind <Esc> to close a floating terminal window if the opened buffer path matches 'floaterm'.
--- Sets a buffer-local keymap on terminal open.
---
---@event TermOpen
---@pattern *
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function(args)
    local bufnr = args.buf

    if vim.api.nvim_buf_get_name(bufnr):find("floaterm") then
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>:lua vim.api.nvim_win_close(0, true)<CR>", {
        buffer = bufnr,
        silent = true,
        desc = "Close floating terminal with ESC"
      })
    end
  end,
})

local autocmd = vim.api.nvim_create_autocmd

---@description
--- On VimEnter, disables Kitty terminal padding and margin via shell command.
--- Requires Kitty to be running and the `kitty @` remote control interface to be available.
---@event VimEnter
---@command :silent !kitty @ set-spacing padding=0 margin=0
autocmd("VimEnter", {
  command = ":silent !kitty @ set-spacing padding=0 margin=0",
})

---@description
--- On VimLeavePre, restores default Kitty padding and margin via shell command.
--- Used in conjunction with a layout optimized for Neovim.
---@event VimLeavePre
---@command :silent !kitty @ set-spacing padding=20 margin=10
autocmd("VimLeavePre", {
  command = ":silent !kitty @ set-spacing padding=20 margin=10",
})
