require "nvchad.mappings"
local map = vim.keymap.set

-- LSP
-- LSP Standardfunktionen
map("n", "grn", "<cmd>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true, desc = "LSP: Rename Symbol" })
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "gra", "<cmd>lua vim.lsp.buf.code_action()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "grr", "<cmd>lua vim.lsp.buf.references()<CR>", { silent = true, noremap = true, desc = "LSP: References" })
map("n", "gri", "<cmd>lua vim.lsp.buf.implementation()<CR>", { silent = true, noremap = true, desc = "LSP: Implementations" })
map("n", "gO", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", { silent = true, noremap = true, desc = "LSP: Document Symbols" })
--map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { silent = true, noremap = true, desc = "LSP: Hover Documentation" })
map("i", "<C-s>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { silent = true, noremap = true, desc = "LSP: Signature Help" })
map("n", "gq", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", { silent = true, noremap = true, desc = "LSP: Format Line" })
-- Weitere nützliche LSP-Funktionen
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { silent = true, noremap = true, desc = "LSP: Go to Definition" })
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { silent = true, noremap = true, desc = "LSP: Go to Declaration" })
map("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { silent = true, noremap = true, desc = "LSP: Type Definition" })
-- Navigation durch Diagnostics
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { silent = true, noremap = true, desc = "LSP: Previous Diagnostic" })
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { silent = true, noremap = true, desc = "LSP: Next Diagnostic" })
-- Diagnostic Tools
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", { silent = true, noremap = true, desc = "LSP: Show Diagnostic Popup" })
map("n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", { silent = true, noremap = true, desc = "LSP: Set Location List" })
map("n", "<leader>f", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", { silent = true, noremap = true, desc = "LSP: Format Document" })

-- loclist
map("n", "<leader>ds", function()
  vim.diagnostic.setloclist()
  vim.cmd("lopen")
end, { desc = "LSP diagnostic loclist (open)" })

-- Trouble.nvim v3+ Keymaps
-- Diagnostics
map("n", "<leader>xt", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle: Diagnostics" })
map("n", "<leader>xx", "<cmd>Trouble diagnostics<cr>", { desc = "Diagnostics: All" })
map("n", "<leader>xw", "<cmd>Trouble diagnostics filter.buf=nil<cr>", { desc = "Diagnostics: Workspace" })
map("n", "<leader>xd", "<cmd>Trouble diagnostics filter.buf=0<cr>", { desc = "Diagnostics: Current Buffer" })

-- LSP: Referenzen, Definitionen, Implementierungen, Symbole
map("n", "<leader>xlr", "<cmd>Trouble lsp_references<cr>", { desc = "LSP: References" })
map("n", "<leader>xld", "<cmd>Trouble lsp_definitions<cr>", { desc = "LSP: Definitions" })
map("n", "<leader>xlt", "<cmd>Trouble lsp_type_definitions<cr>", { desc = "LSP: Type Definitions" })
map("n", "<leader>xli", "<cmd>Trouble lsp_implementations<cr>", { desc = "LSP: Implementations" })
map("n", "<leader>xls", "<cmd>Trouble lsp_document_symbols<cr>", { desc = "LSP: Document Symbols" })

-- Location List & Quickfix List
map("n", "<leader>xl", "<cmd>Trouble loclist<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>Trouble qflist<cr>", { desc = "Quickfix List" })

-- Navigation innerhalb von Listen
map("n", "[q", "<cmd>cprevious<cr>", { desc = "Previous Quickfix Item" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next Quickfix Item" })
map("n", "[l", "<cmd>lprevious<cr>", { desc = "Previous Location Item" })
map("n", "]l", "<cmd>lnext<cr>", { desc = "Next Location Item" })

-- Telescope Integration
map("n", "<leader>tf", "<cmd>Trouble telescope_files<cr>", { desc = "Telescope Files in Trouble" })
map("n", "<leader>tt", "<cmd>Trouble telescope<cr>", { desc = "Telescope Results in Trouble" })


-- Utils
map({"i", "v", "t"}, "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("i", "jk", "<ESC>")
map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
map("n", "<leader>uz", ":echo len(join(getline(1, '$'), ''))<CR>", { desc = "Zeichen zählen" })
map("n", "<leader>uw", ":echo len(split(join(getline(1, '$'), ''), '\\s\\+'))<CR>", { desc = "Wörter zählen" })
map("n", "copyz", ':let @+=getline(".")<CR>:echo "Line copied to clipboard"<CR>', { desc = "Zeile in die Zwischenablage kopieren" })
map("n", "cpe", ':.,$y+<CR>:echo "Copied to clipboard from cursor to EOF"<CR>', { desc = "Von Cursor bis EOF in die Zwischenablage kopieren" })
map("n", "cpf", ':%y+<CR>:echo "Copied entire file to clipboard"<CR>', { desc = "Gesamte Datei in die Zwischenablage kopieren" })
map("v", "cps", '"+y<CR>:echo "Copied selected text to clipboard"<CR>', { desc = "Ausgewählten Text in die Zwischenablage kopieren" })
map("n", "<leader>ex", ":bufdo bd | qa<CR>", { desc = "Alle Buffer schließen und Neovim beenden" })
map("n", "<leader>del", ":lua confirm_delete()<CR>", { desc = "Aktuelle Datei löschen (mit Bestätigung)" })
map("n", "<leader>d!!", ":call DeleteFile()<CR>", { desc = "Datei löschen und Buffer schließen (ohne Bestätigung)" })
map("n", "<CR>", function()
  -- Speichert die aktuelle Cursorposition
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  -- Fügt oberhalb der aktuellen Zeile eine neue Zeile ein
  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { "" })
  -- Bewegt den Cursor in die ursprüngliche Zeile
  vim.api.nvim_win_set_cursor(0, { row, col })
end, { desc = "Zeile oberhalb einfügen" })


-- Window and Tab manipulation
map("n", "<leader>p", "<cmd>tabprevious<CR>", { desc = "Go to previous tab" })
map("n", "<leader>n", "<cmd>tabnext<CR>", { desc = "Go to next tab" })
map("n", "<A-+>", function() vim.cmd("resize +5") end, { desc = "Increase window height" })
map("n", "<A-_>", function() vim.cmd("resize -5") end, { desc = "Decrease window height" }) -- Alt+Minus
map("n", "<A-.>", function() vim.cmd("vertical resize -5") end, { desc = "Make window narrower" }) -- Alt+.
map("n", "<A-#>", function() vim.cmd("vertical resize +5") end, { desc = "Make window wider" })    -- Alt+#


-- Nvimtree
map("n", "<leader>+", function() vim.cmd("vertical resize +5") end, { desc = "Increase NvimTree width by 5" })
map("n", "<leader>-", function() vim.cmd("vertical resize -5") end, { desc = "Decrease NvimTree width by 5" })


-- Quickfix
map("n", "<leader>qo", ":copen<CR>", { desc = "Quickfix: Öffne Quickfix-Fenster" })
map("n", "<leader>qn", ":cnext<CR>", { desc = "Quickfix: Gehe zum nächsten Fehler" })
map("n", "<leader>qp", ":cprev<CR>", { desc = "Quickfix: Gehe zum vorherigen Fehler" })
map("n", "<leader>qe", ":clist<CR>", { desc = "Quickfix: Zeige die Fehlerliste" })


-- Treesitter
map("n", "<leader>nf", "]m", { desc = "Nächste Funktion" })
map("n", "<leader>pf", "[m", { desc = "Vorherige Funktion" })
map("n", "<leader>nc", "]C", { desc = "Nächste Klasse" })
map("n", "<leader>pc", "[C", { desc = "Vorherige Klasse" })
map("n", "<leader>yf", "yaf", { desc = "Ganze Funktion kopieren" })
map("n", "<leader>yc", "yac", { desc = "Ganze Klasse kopieren" })
map("n", "<leader>df", "daf", { desc = "Ganze Funktion löschen" })
map("n", "<leader>dc", "dac", { desc = "Ganze Klasse löschen" })
map("n", "<leader>xf", "xaf", { desc = "Ganze Funktion ausschneiden" })
map("n", "<leader>xc", "xac", { desc = "Ganze Klasse ausschneiden" })
map("n", "<leader>if", "vif", { desc = "Inneren Funktionsinhalt auswählen" })
map("n", "<leader>ic", "vic", { desc = "Inneren Klasseninhalt auswählen" })
map("n", "<leader>ab", "vab", { desc = "Äußeren Block auswählen" })
map("n", "<leader>ib", "vib", { desc = "Inneren Block auswählen" })
map("n", "<leader>nb", "]b", { desc = "Nächsten Block finden" })
map("n", "<leader>pb", "[b", { desc = "Vorherigen Block finden" })
map("n", "<leader>np", "]p", { desc = "Nächsten Parameter finden" })
map("n", "<leader>pp", "[p", { desc = "Vorherigen Parameter finden" })
map("n", "<leader>ip", "vip", { desc = "Inneren Parameter auswählen" })
map("n", "<leader>ap", "vap", { desc = "Äußeren Parameter auswählen" })


-- Telescope
map("n", "<leader>ff", function() require("telescope.builtin").find_files() end, { desc = "Find Files" })
map("n", "<leader>lg", function() require("telescope.builtin").live_grep() end, { desc = "Live Grep" })
map("n", "<leader>git", "<cmd> Telescope git_files <CR>", { desc = "Öffne Git-Dateien" })
map("n", "<Space>gf", "<cmd> Telescope live_grep <CR>", { desc = "Live-Grep" })
map("n", "<Space>fh", "<cmd> Telescope help_tags <CR>", { desc = "Hilfe-Tags durchsuchen" })
map("n", "<leader>pf", "<cmd> Telescope find_files <CR>", { desc = "Dateien finden" })
map("n", "<Space>comm", "<cmd> Telescope git_commits <CR>", { desc = "Git-Commits anzeigen" })
map("n", "<leader>gs", function() require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") }) end, { desc = "Grep-Suche" })
map("n", "<leader>tu", ":Telescope<CR>", { desc = "Telescope UI starten" })
map("i", "<M-p>", "<Cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Vorherige Suchkategorie" })
map("i", "<M-n>", "<Cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Nächste Suchkategorie" })


-- Harpoon
map("n", "<leader>h", function() require("harpoon.mark").add_file() end, { desc = "Datei zu Harpoon hinzufügen" })
map("n", "<C-h>", function() require("harpoon.ui").toggle_quick_menu() end, { desc = "Harpoon-Menü umschalten" })
map("n", "<leader>1", function() require("harpoon.ui").nav_file(1) end, { desc = "Navigiere zu Harpoon Datei 1" })
map("n", "<leader>2", function() require("harpoon.ui").nav_file(2) end, { desc = "Navigiere zu Harpoon Datei 2" })
map("n", "<leader>3", function() require("harpoon.ui").nav_file(3) end, { desc = "Navigiere zu Harpoon Datei 3" })
map("n", "<leader>4", function() require("harpoon.ui").nav_file(4) end, { desc = "Navigiere zu Harpoon Datei 4" })
map("n", "<leader>5", function() require("harpoon.ui").nav_file(5) end, { desc = "Navigiere zu Harpoon Datei 5" })
map("n", "<leader>6", function() require("harpoon.ui").nav_file(6) end, { desc = "Navigiere zu Harpoon Datei 6" })
map("n", "<leader>7", function() require("harpoon.ui").nav_file(7) end, { desc = "Navigiere zu Harpoon Datei 7" })
map("n", "<leader>8", function() require("harpoon.ui").nav_file(8) end, { desc = "Navigiere zu Harpoon Datei 8" })
map("n", "<leader>9", function() require("harpoon.ui").nav_file(9) end, { desc = "Navigiere zu Harpoon Datei 9" })


-- Diffview
map("n", "<leader>dv", ":DiffviewOpen<CR>", { desc = "Diffview öffnen" })
map("n", "<leader>dc", ":DiffviewClose<CR>", { desc = "Diffview schließen" })
map("n", "<leader>dh", ":DiffviewFileHistory<CR>", { desc = "Dateihistorie in Diffview anzeigen" })


-- { "<leader>la", "<cmd>LazyGit<cr>", desc = "LazyGit" }
-- Neogit
map("n", "<leader>ng", function() require("neogit").open() end, { desc = "Neogit Interface öffnen" })
map("n", "<leader>nc", function() require("neogit").open({ "commit" }) end, { desc = "Neogit Commit" })


-- Markdown
-- Insert mode fold mappings
map("i", "<C-Down>", "<Esc>zRi", { desc = "Open all foldings" })            -- Alle Foldings öffnen
map("i", "<C-Up>", "<Esc>zMi", { desc = "Close all foldings" })             -- Alle Foldings schließen
-- Nomral mode fold mappings
map("n", "<C-Right>", "za", { desc = "Toggle fold under cursor" })
map("n", "<C-Left>", "zc", { desc = "Close fold under cursor" })

map("i", "<C-Right>", "<Esc>zai", { desc = "Toggle folding under cursor" })
map("i", "<C-Down>", "<Esc>zRi", { desc = "Open all foldings" })
map("i", "<C-Left>", "<Esc>zci", { desc = "Close folding under cursor" })
map("i", "<C-Up>", "<Esc>zMi", { desc = "Close all foldings" })
map("n", "<leader>fo", "za", { desc = "Toggle Fold unter dem Cursor" }) -- Fold unter dem Cursor ein-/ausklappen
map("n", "<leader>fa", "ggVGzM", { desc = "Alle Headings falten" })     -- Alle Headings falten

-- Normal mode fold mappings
map("n", "zA", "zA", { desc = "Toggle all foldings" }) -- Standard für alle Foldings öffnen/schließen
map("n", "zO", "zO", { desc = "Open all foldings" })   -- Alle Foldings öffnen
map("n", "zC", "zC", { desc = "Close all foldings" })  -- Alle Foldings schließen

-- Visual mode line shifting mappings
map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })    -- Zeilen nach oben verschieben
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" }) -- Zeilen nach unten verschieben


-- Copilot
map("i", "<C-y>", 'copilot#Accept("<CR>")', { silent = true, expr = true, noremap = true, desc = "Accept Copilot suggestion" })
map("i", "<C-l>", "<Plug>(copilot-accept-word)", { noremap = false, desc = "Accept next word of suggestion" })
map("i", "<C-k>", "<Plug>(copilot-accept-line)", { noremap = false, desc = "Accept next line of suggestion" })
map("i", "<C-r>", "<Plug>(copilot-dismiss)", { noremap = false, desc = "Dismiss Copilot suggestion" })
map("i", "<C-n>", "<Plug>(copilot-next)", { noremap = false, desc = "Cycle to next Copilot suggestion" })
map("i", "<C-p>", "<Plug>(copilot-previous)", { noremap = false, desc = "Cycle to previous Copilot suggestion" })
map("i", "<C-s>", "<Plug>(copilot-suggest)", { noremap = false, desc = "Explicitly request a new suggestion" })


-- FZF
-- Allgemeine Keymaps für FZF-Lua und Navigation
map("n", "<leader>fzh", ":FzfLua help_tags<CR>", { desc = "Hilfe-Tags durchsuchen" })
map("n", "<leader>fzj", ":FzfLua jumps<CR>", { desc = "Sprungpunkte durchsuchen" })
-- Befehle durchsuchen
map("n", "<leader>fza", ":FzfLua commands<CR>", { desc = "Befehle durchsuchen" })
map("n", "<leader>fz5", ":FzfLua command_history<CR>", { desc = "Befehlshistorie durchsuchen" })
map("n", "<leader>fz1", ":FzfLua resume<CR>", { desc = "Letzten Befehl/Abfrage fortsetzen" })
map("n", "<leader>fz3", ":FzfLua builtin<CR>", { desc = "Eingebaute Befehle anzeigen" })
map("n", "<leader>fz2", ":FzfLua search_history<CR>", { desc = "Suchverlauf anzeigen" })
-- Dateien und Buffer
map("n", "<leader>fzb", ":FzfLua buffers<CR>", { desc = "Buffer durchsuchen" })
map("n", "<leader>fze", ":FzfLua files<CR>", { desc = "Dateien durchsuchen" })
map("n", "<leader>fzn", ":FzfLua quickfix_stack<CR>", { desc = "Quickfix-Stack anzeigen" })
map("n", "<leader>old", ":FzfLua oldfiles<CR>", { desc = "Dateiverlauf anzeigen" })
-- Tags und Zeilen
map("n", "<leader>fzt", ":FzfLua tags<CR>", { desc = "Tags suchen" })
map("n", "<leader>fzu", ":FzfLua blines<CR>", { desc = "Zeilen durchsuchen" })
map("n", "<leader>fzk", ":FzfLua lines<CR>", { desc = "Zeilen durchsuchen" })
-- Farben und Schlüsselzuordnungen
map("n", "<leader>color", ":FzfLua colorschemes<CR>", { desc = "Farbschemata durchsuchen" })
map("n", "<leader>key", ":FzfLua keymaps<CR>", { desc = "Schlüsselzuordnungen anzeigen" })
-- Git
map("n", "<leader>fzd", ":FzfLua git_status<CR>", { desc = "Git-Status anzeigen" })
map("n", "<leader>fzg", ":FzfLua git_commits<CR>", { desc = "Git-Commits durchsuchen" })
map("n", "<leader>fzi", ":FzfLua git_files<CR>", { desc = "Git-Dateien durchsuchen" })
-- Diagnosen
map("n", "<leader>diad", ":FzfLua diagnostics_document<CR>", { desc = "Dokumentdiagnosen anzeigen" })
map("n", "<leader>diaw", ":FzfLua diagnostics_workspace<CR>", { desc = "Workspace-Diagnosen anzeigen" })
-- LSP
map("n", "<leader>fzv", ":FzfLua lsp_code_actions<CR>", { desc = "Codeaktionen anzeigen" })
map("n", "<leader>fzw", ":FzfLua lsp_document_diagnostics<CR>", { desc = "Dokumentdiagnosen anzeigen" })
map("n", "<leader>fzx", ":FzfLua lsp_finder<CR>", { desc = "LSP-Finder" })
map("n", "<leader>fzy", ":FzfLua lsp_references<CR>", { desc = "Referenzen anzeigen" })
map("n", "<leader>fzz", ":FzfLua lsp_typedefs<CR>", { desc = "Typdefinitionen anzeigen" })
map("n", "<leader>fz0", ":FzfLua lsp_implementations<CR>", { desc = "Implementierungen anzeigen" })
-- Register und Änderungen
map("n", "<", ":FzfLua registers<CR>", { desc = "Register durchsuchen" })
map("n", "<leader>fzr", ":FzfLua changes<CR>", { desc = "Änderungen durchsuchen" })
-- Quickfix und Man-Pages
map("n", "<leader>fzm", ":FzfLua quickfix<CR>", { desc = "Quickfix-Liste durchsuchen" })
map("n", "<leader>fzs", ":FzfLua man_pages<CR>", { desc = "Man-Pages anzeigen" })
-- Suche
map("n", "<leader>grep", ":FzfLua live_grep<CR>", { desc = "Live-Grep" })
map("n", "<leader>fz6", ":FzfLua grep<CR>", { desc = "Grep-Historie anzeigen" })
-- Datei-Typen
map("n", "<leader>fz7", ":FzfLua filetypes<CR>", { desc = "Dateitypen anzeigen" })


-- Toggleterm
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<C-c>", "<C-\\><C-n>", { desc = "Exit terminal mode" })


-- Custom plugins

-- myterm
local term = require("custom.myterm")
map("n", "<leader>to", ":Floaterminal<CR>", { desc = "Toggle Floating Terminal" })
map("n", "<leader>ts", term.set_command, { desc = "Set terminal command" })
map("n", "<leader>tr", term.run_command, { desc = "Run terminal command" })
map("n", "<leader>tc", term.clear_command, { desc = "Clear terminal command" })

-- find mappings
local keysearch = require("custom.keymap_search")
map("n", "<leader>fk", keysearch.search_keymaps, { desc = "Finde Keymaps (Telescope)" })
local run = require("custom.run_mappings")
map("n", "<leader>fs", run.find_keymap, { desc = "Keymap-Suche via Bash-Script" })

-- find files on system
map("n", "<leader><leader>", require("custom.system_find").system_find, { desc = "Systemweite Dateisuche mit Endung" })

-- command history
map({"n", "v"}, "<leader>hy", require("custom.command_history").show_command_history, { desc = "Zeige Command-History" })
