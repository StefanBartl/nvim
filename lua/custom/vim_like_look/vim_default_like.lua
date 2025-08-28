---@module 'colors.vim_default_like'
--- Minimal colorscheme that defers to the terminal palette (like classic Vim).
--- Intended for :colorscheme vim_default_like
--- Tip: set `vim.opt.termguicolors = false` and ensure EOB tildes in your options.

-- Clear existing highlights and reset syntax
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "vim_default_like"

-- Keep Normal group uncolored so terminal decides foreground/background
-- This matches the classic behavior closely.
vim.api.nvim_set_hl(0, "Normal", {})

-- NonText (~ markers and similar) slightly bluish like many default terminals
-- Use cterm indices so it works with termguicolors=false
-- 12 is a typical "Blue" on many 256-color palettes; adjust as needed.
vim.api.nvim_set_hl(0, "NonText", { ctermfg = 12 })
vim.api.nvim_set_hl(0, "EndOfBuffer", { link = "NonText" })

-- Keep other groups mostly untouched; rely on default links.
-- Add minimal, conservative links to reduce harsh accents:
vim.api.nvim_set_hl(0, "Directory", { ctermfg = 12 })
vim.api.nvim_set_hl(0, "Title",     { ctermfg = 12, bold = true })
vim.api.nvim_set_hl(0, "Visual",    { reverse = true }) -- classic visual invert

