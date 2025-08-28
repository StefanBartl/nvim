---@module 'ui.tty_look'
--- Enforce a terminal-like appearance and the classic "~" EOB markers.

-- 1) Opt out of truecolor to rely on terminal palette (classic Vim feel)
vim.opt.termguicolors = false

-- 2) Show "~" on lines after EOF (many UIs hide them via eob = " ")
do
  ---@type table<string,string>
  local fc = vim.opt.fillchars:get()
  fc.eob = "~"                        -- draw the classic tildes
  vim.opt.fillchars = fc
end

-- 3) Guard against plugins re-enabling truecolor or wiping EOB tildes
local aug = vim.api.nvim_create_augroup("tty_look_guard", { clear = true })

vim.api.nvim_create_autocmd("OptionSet", {
  group = aug,
  pattern = "termguicolors",
  desc = "Keep termguicolors disabled for a terminal-like look",
  callback = function()
    if vim.opt.termguicolors:get() then
      vim.opt.termguicolors = false
    end
  end,
})

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "User" }, {
  group = aug,
  pattern = { "*", "VeryLazy" },
  desc = "Restore EOB tildes after theme or lazy events",
  callback = function()
    local fc = vim.opt.fillchars:get()
    if fc.eob ~= "~" then
      fc.eob = "~"
      vim.opt.fillchars = fc
    end
  end,
})

