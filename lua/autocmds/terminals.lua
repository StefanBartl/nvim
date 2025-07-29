local autocmd = vim.api.nvim_create_autocmd

---   Disable absolute and relative line numbers in any terminal buffer.
---   Triggered automatically on the 'TermOpen' event.
---   Useful to reduce visual clutter in embedded or floating terminals.
---@event TermOpen
---@group custom-term-open
autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
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
  command = ":silent !kitty @ set-spacing padding=0 margin=0",
})

--- On VimLeavePre, restores default Kitty padding and margin via shell command.
--- Used in conjunction with a layout optimized for Neovim.
---@event VimLeavePre
---@command :silent !kitty @ set-spacing padding=20 margin=10
autocmd("VimLeavePre", {
  command = ":silent !kitty @ set-spacing padding=20 margin=10",
})

-- Register a user command :TerminalsPrintAll that prints all ToggleTerm terminals via :messages
vim.api.nvim_create_user_command("TerminalsPrintAll", function()
  local Term = require("toggleterm.terminal")
  local terminals = Term.get_all()

  if #terminals == 0 then
    print("No terminals found.")
    return
  end

  for _, t in ipairs(terminals) do
    local msg = string.format(
      "ID: %d  Name: %s  Direction: %s  Open: %s",
      t.id,
      t.name or "-",
      t.direction or "-",
      tostring(t:is_open())
    )
    vim.notify(msg, vim.log.levels.INFO, { title = "ToggleTerm" })
  end
end, {})
