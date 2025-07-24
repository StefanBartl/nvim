require "nvchad.options"

-- True Color Unterstützung aktivieren
if vim.fn.has("termguicolors") == 1 then
	vim.opt.termguicolors = true
end

vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#1a1a1a" })

-- Allgemeine Benutzererfahrung
vim.opt.number = true     -- Zeilennummern anzeigen
vim.o.relativenumber = true
vim.opt.cursorline = true -- Hervorheben der aktuellen Zeile
--vim.opt.wrap = false                   -- Kein automatischer Zeilenumbruch
--vim.opt.scrolloff = 8                  -- Abstand vom Cursor zum Rand des Fensters
--vim.opt.sidescrolloff = 8              -- Horizontaler Abstand vom Cursor zum Rand
--vim.opt.mouse = "a"                    -- Mausunterstützung aktivieren
--vim.opt.clipboard = "unnamedplus"      -- Systemzwischenablage verwenden
--vim.opt.hidden = true                  -- Puffer können gewechselt werden, ohne sie zu speichern

-- Faltmethoden und Treesitter Faltintegration konfigurieren
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldcolumn = "0" -- keine extra Informationen an der Seite
vim.opt.foldtext =
""                       -- bestimmt, wie der Text angezeigt wird, wenn ein Fold (Codeblock) geschlossen ist. "" bedeutet erste sichtbare Text im Fold-Bereich angezeigt
vim.opt.foldlevel = 99   -- toplevel folds öffnen
--vim.opt.foldlevelstart = 1
vim.opt.foldnestmax = 6

-- Tab- und Indentationssteuerung
--vim.opt.expandtab = true               -- Tabulatoren in Leerzeichen umwandeln
vim.opt.shiftwidth = 2 -- Breite für Auto-Indents
vim.opt.tabstop = 2    -- Breite eines Tabs

-- UI-Verbesserungen
vim.opt.signcolumn = "yes"
vim.opt.cmdheight = 1 -- Höhe der Befehlszeile erhöhen

-- Sicherheits-/Backup-Optionen
vim.opt.backup = false   -- Keine Backup-Dateien erstellen
vim.opt.swapfile = false -- Keine Swap-Dateien erstellen
--vim.opt.undofile = true                              -- Änderungsverlauf speichern
--vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo" -- Speicherort für Undo-Dateien
