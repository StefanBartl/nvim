require "nvchad.options"

-- True Color Unterstützung aktivieren
if vim.fn.has("termguicolors") == 1 then
	vim.opt.termguicolors = true
end

vim.opt.signcolumn = "yes"
vim.o.relativenumber = true

-- Faltmethoden und Treesitter Faltintegration konfigurieren
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldcolumn = "0"   -- keine extra Informationen an der Seite
vim.opt.foldtext = ""      -- bestimmt, wie der Text angezeigt wird, wenn ein Fold (Codeblock) geschlossen ist. "" bedeutet erste sichtbare Text im Fold-Bereich angezeigt
vim.opt.foldlevel = 99     -- toplevel folds öffnen
vim.opt.foldlevelstart = 1
vim.opt.foldnestmax = 6
