---@module 'options'

require "nvchad.options"

if vim.fn.has("termguicolors") == 1 then
	vim.opt.termguicolors = true
end

vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#1a1a1a" })

vim.opt.number = true
vim.o.relativenumber = true
vim.opt.cursorline = true

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99      -- Sets the fold level globally. Folds with level higher than this will be closed.
vim.opt.foldlevelstart = 99 -- Sets the initial fold level when a buffer is opened. If this is lower than `foldlevel`, deeper folds will be closed at startup.

vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

vim.opt.signcolumn = "yes"
vim.opt.cmdheight = 1

 vim.opt.backup = false
 vim.opt.writebackup = false
-- vim.opt.backupdir = vim.fn.stdpath("data") .. "/backup//"

 vim.opt.swapfile = false
--vim.opt.directory = vim.fn.stdpath("data") .. "/swap//"

vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
