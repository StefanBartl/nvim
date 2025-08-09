local autocmd = vim.api.nvim_create_autocmd

vim.api.nvim_create_augroup("myterminal", { clear = true })

---   Disable absolute and relative line numbers in any terminal buffer.
---   Triggered automatically on the 'TermOpen' event.
---   Useful to reduce visual clutter in embedded or floating terminals.
---@event TermOpen
---@group custom-term-open
autocmd("TermOpen", {
  group = "myterminal",
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

--- On VimEnter, disables Kitty terminal padding and margin via shell command.
--- Requires Kitty to be running and the `kitty @` remote control interface to be available.
---@event VimEnter
---@command :silent !kitty @ set-spacing padding=0 margin=0
autocmd("VimEnter", {
  group = "myterminal",
  command = ":silent !kitty @ set-spacing padding=0 margin=0",
})

--- On VimLeavePre, restores default Kitty padding and margin via shell command.
--- Used in conjunction with a layout optimized for Neovim.
---@event VimLeavePre
---@command :silent !kitty @ set-spacing padding=20 margin=10
autocmd("VimLeavePre", {
  group = "myterminal",
  command = ":silent !kitty @ set-spacing padding=20 margin=10",
})
