require "nvchad.mappings"
local map = vim.keymap.set


--==================================================
--=== FZF-LUA (Fuzzy Finder Alternative) ===========
--==================================================

--=== Befehle durchsuchen ==========================
map("n", "<leader>fza", ":FzfLua commands<CR>", { desc = "Befehle durchsuchen" })
map("n", "<leader>fhc", ":FzfLua command_history<CR>", { desc = "Befehlshistorie durchsuchen" })
map("n", "<leader>fb", ":FzfLua builtin<CR>", { desc = "Eingebaute Befehle anzeigen" })
map("n", "<leader>fsh", ":FzfLua search_history<CR>", { desc = "Suchverlauf anzeigen" })

--=== Dateien und Buffer ===========================
map("n", "<leader>fzb", ":FzfLua buffers<CR>", { desc = "Buffer durchsuchen" })
map("n", "<leader>fze", ":FzfLua files<CR>", { desc = "Dateien durchsuchen" })
map("n", "<leader>fzn", ":FzfLua quickfix_stack<CR>", { desc = "Quickfix-Stack anzeigen" })
map("n", "<leader>old", ":FzfLua oldfiles<CR>", { desc = "Dateiverlauf anzeigen" })

--=== Farben und Schlüsselzuordnungen ==============
map("n", "<leader>color", ":FzfLua colorschemes<CR>", { desc = "Farbschemata durchsuchen" })
map("n", "<leader>key", ":FzfLua keymaps<CR>", { desc = "Schlüsselzuordnungen anzeigen" })

--=== Git ==========================================
map("n", "<leader>fgs", ":FzfLua git_status<CR>", { desc = "Git-Status anzeigen" })
map("n", "<leader>fgc", ":FzfLua git_commits<CR>", { desc = "Git-Commits durchsuchen" })
map("n", "<leader>fgf", ":FzfLua git_files<CR>", { desc = "Git-Dateien durchsuchen" })

--=== Diagnosen ====================================
map("n", "<leader>fdo", ":FzfLua diagnostics_document<CR>", { desc = "Dokumentdiagnosen anzeigen" })
map("n", "<leader>fwo", ":FzfLua diagnostics_workspace<CR>", { desc = "Workspace-Diagnosen anzeigen" })

--=== LSP ==========================================
map("n", "<leader>fzv", ":FzfLua lsp_code_actions<CR>", { desc = "Codeaktionen anzeigen" })
map("n", "<leader>fzw", ":FzfLua lsp_document_diagnostics<CR>", { desc = "Dokumentdiagnosen anzeigen" })
map("n", "<leader>fzx", ":FzfLua lsp_finder<CR>", { desc = "LSP-Finder" })
map("n", "<leader>fzy", ":FzfLua lsp_references<CR>", { desc = "Referenzen anzeigen" })
map("n", "<leader>fzz", ":FzfLua lsp_typedefs<CR>", { desc = "Typdefinitionen anzeigen" })
map("n", "<leader>fz0", ":FzfLua lsp_implementations<CR>", { desc = "Implementierungen anzeigen" })

--=== Register und Änderungen ======================
map("n", "<", ":FzfLua registers<CR>", { desc = "Register durchsuchen" })
map("n", "<leader>fzr", ":FzfLua changes<CR>", { desc = "Änderungen durchsuchen" })

--=== Quickfix und Man-Pages =======================
map("n", "<leader>fqf", ":FzfLua quickfix<CR>", { desc = "Quickfix-Liste durchsuchen" })
map("n", "<leader>man", ":FzfLua man_pages<CR>", { desc = "Man-Pages anzeigen" })

--=== Suche ========================================
map("n", "<leader>lgp", ":FzfLua live_grep<CR>", { desc = "Live-Grep" })
map("n", "<leader>fgp", ":FzfLua grep<CR>", { desc = "Grep-Historie anzeigen" })

--=== Datei-Typen ==================================
map("n", "<leader>fil", ":FzfLua filetypes<CR>", { desc = "Dateitypen anzeigen" })



--==================================================
--=== LSP (Language Server Protocol) ===============
--==================================================

map("n", "grn", "<cmd>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true, desc = "LSP: Rename Symbol" })
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "gra", "<cmd>lua vim.lsp.buf.code_action()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "grr", "<cmd>lua vim.lsp.buf.references()<CR>", { silent = true, noremap = true, desc = "LSP: References" })
map("n", "gri", "<cmd>lua vim.lsp.buf.implementation()<CR>", { silent = true, noremap = true, desc = "LSP: Implementations" })
map("n", "gO", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", { silent = true, noremap = true, desc = "LSP: Document Symbols" })
map("n", "gq", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", { silent = true, noremap = true, desc = "LSP: Format Line" })
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { silent = true, noremap = true, desc = "LSP: Go to Definition" })
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { silent = true, noremap = true, desc = "LSP: Go to Declaration" })
map("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { silent = true, noremap = true, desc = "LSP: Type Definition" })
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { silent = true, noremap = true, desc = "LSP: Previous Diagnostic" })
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { silent = true, noremap = true, desc = "LSP: Next Diagnostic" })
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", { silent = true, noremap = true, desc = "LSP: Show Diagnostic Popup" })
map("n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", { silent = true, noremap = true, desc = "LSP: Set Location List" })
map("n", "<leader>f", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", { silent = true, noremap = true, desc = "LSP: Format Document" })
map("i", "<C-h>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { silent = true, noremap = true, desc = "LSP: Signature Help" })

map("n", "<leader>ds", function()
  vim.diagnostic.setloclist()
  vim.cmd("lopen")
end, { desc = "LSP diagnostic loclist (open)" })



--==================================================
--=== TROUBLE (Diagnostics und Lists) ==============
--==================================================

--=== Diagnostics ==================================
map("n", "<leader>xt", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle: Diagnostics" })
map("n", "<leader>xx", "<cmd>Trouble diagnostics<cr>", { desc = "Diagnostics: All" })
map("n", "<leader>xw", "<cmd>Trouble diagnostics filter.buf=nil<cr>", { desc = "Diagnostics: Workspace" })
map("n", "<leader>xd", "<cmd>Trouble diagnostics filter.buf=0<cr>", { desc = "Diagnostics: Current Buffer" })

--=== LSP: Referenzen, Definitionen, Implementierungen, Symbole
map("n", "<leader>xlr", "<cmd>Trouble lsp_references<cr>", { desc = "LSP: References" })
map("n", "<leader>xld", "<cmd>Trouble lsp_definitions<cr>", { desc = "LSP: Definitions" })
map("n", "<leader>xlt", "<cmd>Trouble lsp_type_definitions<cr>", { desc = "LSP: Type Definitions" })
map("n", "<leader>xli", "<cmd>Trouble lsp_implementations<cr>", { desc = "LSP: Implementations" })
map("n", "<leader>xls", "<cmd>Trouble lsp_document_symbols<cr>", { desc = "LSP: Document Symbols" })

--=== Location List & Quickfix List ================
map("n", "<leader>xl", "<cmd>Trouble loclist<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>Trouble qflist<cr>", { desc = "Quickfix List" })

--=== Navigation innerhalb von Listen ==============
map("n", "[q", "<cmd>cprevious<cr>", { desc = "Previous Quickfix Item" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next Quickfix Item" })
map("n", "[l", "<cmd>lprevious<cr>", { desc = "Previous Location Item" })
map("n", "]l", "<cmd>lnext<cr>", { desc = "Next Location Item" })

--=== Telescope Integration ========================
map("n", "<leader>tf", "<cmd>Trouble telescope_files<cr>", { desc = "Telescope Files in Trouble" })
map("n", "<leader>tt", "<cmd>Trouble telescope<cr>", { desc = "Telescope Results in Trouble" })



--==================================================
--=== TELESCOPE (Fuzzy Finder) =====================
--==================================================

map("n", "<leader>ts", ":Telescope<CR>", { desc = "Telescope UI starten" })
map("n", "<leader>ff", function() require("telescope.builtin").find_files() end, { desc = "Find Files" })
map("n", "<leader><leader>", function() require("telescope.builtin").live_grep() end, { desc = "Live Grep" })
map("n", "<leader>gs", function() require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") }) end, { desc = "Grep-Suche" })
map("n", "<leader>git", function() require("telescope.builtin").git_files() end, { desc = "Git-Dateien durchsuchen" })
map("n", "<leader>hp", function() require("telescope.builtin").help_tags() end, { desc = "Hilfe-Tags durchsuchen" })
map("n", "<leader>com", function() require("telescope.builtin").git_commits() end, { desc = "Git-Commits anzeigen" })
map("i", "<M-p>", function() require("telescope.builtin").find_files() end, { desc = "Vorherige Suchkategorie" })
map("i", "<M-n>", function() require("telescope.builtin").find_files() end, { desc = "Nächste Suchkategorie" })



--==================================================
--=== UTILS (Clipboard, Counter) ===================
--==================================================

map({"n", "i", "v", "t"}, "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("i", "jk", "<ESC>")

map("n", "<leader>uz", ":echo len(join(getline(1, '$'), ''))<CR>", { desc = "Zeichen zählen" })
map("n", "<leader>uw", ":echo len(split(join(getline(1, '$'), ''), '\\s\\+'))<CR>", { desc = "Wörter zählen" })

map("n", "copyz", ':let @+=getline(".")<CR>:echo "Line copied to clipboard"<CR>', { desc = "Zeile in die Zwischenablage kopieren" })
map("n", "cpe", ':.,$y+<CR>:echo "Copied to clipboard from cursor to EOF"<CR>', { desc = "Von Cursor bis EOF in die Zwischenablage kopieren" })
map("n", "cpf", ':%y+<CR>:echo "Copied entire file to clipboard"<CR>', { desc = "Gesamte Datei in die Zwischenablage kopieren" })
map("v", "cps", '"+y<CR>:echo "Copied selected text to clipboard"<CR>', { desc = "Ausgewählten Text in die Zwischenablage kopieren" })



--==================================================
--=== FOLDING ======================================
--==================================================

map("i", "<C-Down>", "<Esc>zRi", { desc = "Open all foldings" })
map("i", "<C-Up>", "<Esc>zMi", { desc = "Close all foldings" })
map("i", "<C-Right>", "<Esc>zai", { desc = "Toggle folding under cursor" })
map("i", "<C-Left>", "<Esc>zci", { desc = "Close folding under cursor" })
map("n", "zA", "zA", { desc = "Toggle all foldings" })
map("n", "zO", "zO", { desc = "Open all foldings" })
map("n", "zC", "zC", { desc = "Close all foldings" })
map("n", "<leader>fo", "za", { desc = "Toggle Fold unter dem Cursor" })
map("n", "<leader>fa", "ggVGzM", { desc = "Alle Headings falten" })
map("n", "<C-Right>", "za", { desc = "Toggle fold under cursor" })
map("n", "<C-Left>", "zc", { desc = "Close fold under cursor" })



--==================================================
--=== BUFFER / WINDOW / TAB MANAGEMENT =============
--==================================================

map("n", "<leader>ex", ":bufdo bd | qa<CR>", { desc = "Alle Buffer schließen und Neovim beenden" })
map("n", "<leader>del", ":lua confirm_delete()<CR>", { desc = "Aktuelle Datei löschen (mit Bestätigung)" })
map("n", "<leader>d!!", ":call DeleteFile()<CR>", { desc = "Datei löschen und Buffer schließen (ohne Bestätigung)" })

map("n", "<A-+>", function() vim.cmd("resize +5") end, { desc = "Increase window height" })
map("n", "<A-_>", function() vim.cmd("resize -5") end, { desc = "Decrease window height" })
map("n", "<A-.>", function() vim.cmd("vertical resize -5") end, { desc = "Make window narrower" })
map("n", "<A-#>", function() vim.cmd("vertical resize +5") end, { desc = "Make window wider" })

map("n", "<leader>p", "<cmd>tabprevious<CR>", { desc = "Go to previous tab" })
map("n", "<leader>n", "<cmd>tabnext<CR>", { desc = "Go to next tab" })



--==================================================
--=== GIT (Diffview, Lazygit) ======================
--==================================================

map("n", "<leader>dv", ":DiffviewOpen<CR>", { desc = "Diffview öffnen" })
map("n", "<leader>dc", ":DiffviewClose<CR>", { desc = "Diffview schließen" })
map("n", "<leader>dh", ":DiffviewFileHistory<CR>", { desc = "Dateihistorie in Diffview anzeigen" })
-- { "<leader>la", "<cmd>LazyGit<cr>", desc = "LazyGit" }



--==================================================
--=== HARPOON (Schnellnavigation) ==================
--==================================================

map("n", "<leader>h", function() require("harpoon.mark").add_file() end, { desc = "Datei zu Harpoon hinzufügen" })
map("n", "<C-h>", function() require("harpoon.ui").toggle_quick_menu() end, { desc = "Harpoon-Menü umschalten" })



--==================================================
--=== MISC =========================================
--==================================================

--=== Nvimtree =====================================
map("n", "<leader>+", function() vim.cmd("vertical resize +5") end, { desc = "Increase NvimTree width by 5" })
map("n", "<leader>-", function() vim.cmd("vertical resize -5") end, { desc = "Decrease NvimTree width by 5" })


--=== Insert Lines Above Cursor ====================
map("n", "<CR>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))         -- Save the current cursor position
  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { "" })  -- Insert an empty line above the current line
  vim.api.nvim_win_set_cursor(0, { row, col })                    -- Restore the cursor to the original position
end, { desc = "Insert line above without moving the cursor" })

--=== Move Selected Lines ==========================
map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })

--=== Exit Terminal Mode ===========================
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<C-c>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

--==================================================
--=== CUSTOM PLUGINS ===============================
--==================================================

--=== myterm =======================================
local term = require("custom.myterm")
map("n", "<leader>to", ":Floaterminal<CR>", { desc = "Toggle Floating Terminal" })
map("n", "<leader>ts", term.set_command, { desc = "Set terminal command" })
map("n", "<leader>tr", term.run_command, { desc = "Run terminal command" })
map("n", "<leader>tc", term.clear_command, { desc = "Clear terminal command" })

--=== find mappings ================================
local keysearch = require("custom.keymap_search")
map("n", "<leader>fk", keysearch.search_keymaps, { desc = "Finde Keymaps (Telescope)" })
local run = require("custom.run_mappings")
map("n", "<leader>fs", run.find_keymap, { desc = "Keymap-Suche via Bash-Script" })

--=== find files on system =========================
map("n", "<leader>sf", require("custom.system_find").system_find, { desc = "Systemweite Dateisuche mit Endung" })

--=== command history ==============================
map({"n", "v"}, "<leader>hy", require("custom.command_history").show_command_history, { desc = "Zeige Command-History" })