---@module 'autocmds.terminals'

-- Create (or clear) an augroup for terminal-related autocmds
vim.api.nvim_create_augroup("terminal_autocmds", { clear = true })

--- Disable absolute and relative line numbers in any terminal buffer
--- Triggered on the 'TermOpen' event
vim.api.nvim_create_autocmd("TermOpen", {
  group = "terminal_autocmds",
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

--- On VimEnter, disable Kitty terminal padding and margin via remote control
--- Requires Kitty with `kitty @` remote control enabled
vim.api.nvim_create_autocmd("VimEnter", {
  group = "terminal_autocmds",
  command = ":silent !kitty @ set-spacing padding=0 margin=0",
})

--- On VimLeavePre, restore default Kitty padding and margin
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = "terminal_autocmds",
  command = ":silent !kitty @ set-spacing padding=20 margin=10",
})
