require "nvchad.options"

-- True Color Unterstützung aktivieren
if vim.fn.has("termguicolors") == 1 then
	vim.opt.termguicolors = true
end

vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#1a1a1a" })

vim.opt.number = true
vim.o.relativenumber = true
vim.opt.cursorline = true -- Highlight current line

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldtext = "" -- Controls the text shown when a fold is closed. An empty string means the first visible line in the folded section is displayed.
vim.opt.foldlevel = 4 -- Sets the fold level globally. Folds with level higher than this will be closed.
vim.opt.foldlevelstart = 3 -- Sets the initial fold level when a buffer is opened. If this is lower than `foldlevel`, deeper folds will be closed at startup.
vim.opt.foldnestmax = 6 -- Limits how deep folds can be nested. Higher values allow deeper folding.

vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

vim.opt.signcolumn = "yes"
vim.opt.cmdheight = 1

-- vim.opt.backup = true
-- vim.opt.writebackup = true
-- vim.opt.backupdir = vim.fn.stdpath("data") .. "/backup//"

vim.opt.swapfile = true
vim.opt.directory = vim.fn.stdpath("data") .. "/swap//"

vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
