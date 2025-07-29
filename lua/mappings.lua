local map = vim.keymap.set

--==================================================
--=== FZF-LUA (Fuzzy Finder Alternative) ===========
--==================================================

--=== Befehle durchsuchen ==========================
map("n", "<leader>fza", ":FzfLua commands<CR>", { desc = "[FzfLua] Search Commands" })
map("n", "<leader>fhc", ":FzfLua command_history<CR>", { desc = "[FzfLua] Search Command History" })
map("n", "<leader>fb", ":FzfLua builtin<CR>", { desc = "[FzfLua] Show Builtin-Commands" })
map("n", "<leader>fsh", ":FzfLua search_history<CR>", { desc = "[FzfLua] Show Search History" })

--=== Dateien und Buffer ===========================
map("n", "<leader>fze", ":FzfLua files<CR>", { desc = "[FzfLua] Dateien durchsuchen" })
map("n", "<leader>fzn", ":FzfLua quickfix_stack<CR>", { desc = "[FzfLua] Quickfix-Stack anzeigen" })
map("n", "<leader>old", ":FzfLua oldfiles<CR>", { desc = "[FzfLua] Dateiverlauf anzeigen" })

--=== Farben und Schlüsselzuordnungen ==============
map("n", "<leader>color", ":FzfLua colorschemes<CR>", { desc = "[FzfLua] Farbschemata durchsuchen" })
map("n", "<leader>key", ":FzfLua keymaps<CR>", { desc = "[FzfLua] Schlüsselzuordnungen anzeigen" })

--=== Git ==========================================
map("n", "<leader>fgs", ":FzfLua git_status<CR>", { desc = "[FzfLua] Git-Status anzeigen" })
map("n", "<leader>fgc", ":FzfLua git_commits<CR>", { desc = "[FzfLua] Git-Commits durchsuchen" })
map("n", "<leader>fgf", ":FzfLua git_files<CR>", { desc = "[FzfLua] Git-Dateien durchsuchen" })

--=== Diagnosen ====================================
map("n", "<leader>fdo", ":FzfLua diagnostics_document<CR>", { desc = "[FzfLua] Dokumentdiagnosen anzeigen" })
map("n", "<leader>fwo", ":FzfLua diagnostics_workspace<CR>", { desc = "[FzfLua] Workspace-Diagnosen anzeigen" })

--=== LSP ==========================================
map("n", "<leader>fzv", ":FzfLua lsp_code_actions<CR>", { desc = "[FzfLua] Codeaktionen anzeigen" })
map("n", "<leader>fzw", ":FzfLua lsp_document_diagnostics<CR>", { desc = "[FzfLua] Dokumentdiagnosen anzeigen" })
map("n", "<leader>fzx", ":FzfLua lsp_finder<CR>", { desc = "[FzfLua] LSP-Finder" })
map("n", "<leader>fzy", ":FzfLua lsp_references<CR>", { desc = "[FzfLua] Referenzen anzeigen" })
map("n", "<leader>fzz", ":FzfLua lsp_typedefs<CR>", { desc = "[FzfLua] Typdefinitionen anzeigen" })
map("n", "<leader>fz0", ":FzfLua lsp_implementations<CR>", { desc = "[FzfLua] Implementierungen anzeigen" })

--=== Register und Änderungen ======================
map("n", "<", ":FzfLua registers<CR>", { desc = "[FzfLua] Register durchsuchen" })
map("n", "<leader>fzr", ":FzfLua changes<CR>", { desc = "[FzfLua] Änderungen durchsuchen" })

--=== Quickfix und Man-Pages =======================
map("n", "<leader>fqf", ":FzfLua quickfix<CR>", { desc = "[FzfLua] Quickfix-Liste durchsuchen" })
map("n", "<leader>man", ":FzfLua man_pages<CR>", { desc = "[FzfLua] Man-Pages anzeigen" })

--=== Suche ========================================
map("n", "<leader>lgp", ":FzfLua live_grep<CR>", { desc = "[FzfLua] Live-Grep" })
map("n", "<leader>fgp", ":FzfLua grep<CR>", { desc = "[FzfLua] Grep-Historie anzeigen" })
map("n", "<leader>fzb", "<cmd>FzfLua grep_curbuf<CR>",
  { noremap = true, silent = true, desc = "[fzf-lua] Suche im aktuellen Buffer" })
map("n", "<leader>fzl", "<cmd>FzfLua live_grep_curbuf<CR>",
  { noremap = true, silent = true, desc = "[fzf-lua] Live-Suche im aktuellen Buffer" })

--=== Datei-Typen ==================================
map("n", "<leader>fil", ":FzfLua filetypes<CR>", { desc = "[FzfLua] Dateitypen anzeigen" })

map("n", "<leader>do", ":FzfLua diagnostics_document<CR>", { desc = "[FzfLua] Show document diagnose" })
map("n", "<leader>wo", ":FzfLua diagnostics_workspace<CR>", { desc = "[FzfLua] Show workspace diagnose" })

--==================================================
--=== LSP (Language Server Protocol) ===============
--==================================================

vim.keymap.set("n", "<leader>xw", function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    require("workspace-diagnostics").populate_workspace_diagnostics(client, 0)
  end
end, { desc = "[LSP] Populate workspace diagnostics" })
map("n", "grn", "<cmd>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true, desc = "[LSP] Rename Symbol" })
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Code Action" })
map("n", "gra", "<cmd>lua vim.lsp.buf.code_action()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Code Action" })
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Code Action" })
map("n", "grr", "<cmd>lua vim.lsp.buf.references()<CR>", { silent = true, noremap = true, desc = "[LSP] Vim References" })
map("n", "gri", "<cmd>lua vim.lsp.buf.implementation()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Implementations" })
map("n", "gO", "<cmd>lua vim.lsp.buf.document_symbol()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Document Symbols" })
map("n", "gq", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Format Line" })
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Go to Definition" })
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Go to Declaration" })
map("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Type Definition" })
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Previous Diagnostic" })
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Next Diagnostic" })
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Show Diagnostic Popup" })
map("n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Set Location List" })
map("n", "<leader>f", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Format Document" })
map("i", "<C-s>", "<cmd>lua vim.lsp.buf.signature_help()<CR>",
  { silent = true, noremap = true, desc = "[LSP] Vim Signature Help" })

map("n", "<leader>ds", function()
  vim.diagnostic.setloclist()
  vim.cmd("lopen")
end, { desc = "[LSP] Vim diagnostic loclist (open)" })


--==================================================
--=== TROUBLE (Diagnostics und Lists) ==============
--==================================================

--=== Diagnostics ==================================
map("n", "<leader>xt", "<cmd>Trouble diagnostics toggle<cr>", { desc = "[Trouble] Toggle diagnostics" })
map("n", "<leader>xx", "<cmd>Trouble diagnostics<cr>", { desc = "[Trouble] All diagnostics" })
map("n", "<leader>xw", "<cmd>Trouble diagnostics filter.buf=nil<cr>", { desc = "[Trouble] Workspace diagnostics" })
map("n", "<leader>xd", "<cmd>Trouble diagnostics filter.buf=0<cr>",
  { desc = "[Trouble] Diagnostics from current buffer" })

--=== LSP: Referenzen, Definitionen, Implementierungen, Symbole
map("n", "<leader>xlr", "<cmd>Trouble lsp_references<cr>", { desc = "[Trouble] LSP References" })
map("n", "<leader>xld", "<cmd>Trouble lsp_definitions<cr>", { desc = "[Trouble] LSP Definitions" })
map("n", "<leader>xlt", "<cmd>Trouble lsp_type_definitions<cr>", { desc = "[Trouble] LSP Type Definitions" })
map("n", "<leader>xli", "<cmd>Trouble lsp_implementations<cr>", { desc = "[Trouble] LSP Implementations" })
map("n", "<leader>xls", "<cmd>Trouble lsp_document_symbols<cr>", { desc = "[Trouble] LSP Document Symbols" })

--=== Location List & Quickfix List ================
map("n", "<leader>xl", "<cmd>Trouble loclist<cr>", { desc = "[Trouble] Location List" })
map("n", "<leader>xq", "<cmd>Trouble qflist<cr>", { desc = "[Trouble] Quickfix List" })

--=== Navigation innerhalb von Listen ==============
map("n", "[q", "<cmd>cprevious<cr>", { desc = "[Trouble] Previous Quickfix Item" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "[Trouble] Next Quickfix Item" })
map("n", "[l", "<cmd>lprevious<cr>", { desc = "[Trouble] Previous Location Item" })
map("n", "]l", "<cmd>lnext<cr>", { desc = "[Trouble] Next Location Item" })

--=== Telescope Integration ========================
map("n", "<leader>tf", "<cmd>Trouble telescope_files<cr>", { desc = "[Trouble] Telescope Files in Trouble" })
map("n", "<leader>tt", "<cmd>Trouble telescope<cr>", { desc = "[Trouble] Telescope Results in Trouble" })


--==================================================
--=== TELESCOPE (Fuzzy Finder) =====================
--==================================================

map("n", "<leader>ts", ":Telescope<CR>", { desc = "[Telescope] Start UI" })
map("n", "<leader>ff", function() require("telescope.builtin").find_files() end, { desc = "[Telescope] Find Files" })
map("n", "<leader>gs", function() require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") }) end,
  { desc = "[Telescope] Grep" })
map("n", "<leader>git", function() require("telescope.builtin").git_files() end,
  { desc = "[Telescope] Search Git files" })
map("n", "<leader>hp", function() require("telescope.builtin").help_tags() end, { desc = "[Telescope] Search Help Tags" })
map("n", "<leader>com", function() require("telescope.builtin").git_commits() end,
  { desc = "[Telescope] Show Git-Commits" })
map("i", "<M-p>", function() require("telescope.builtin").find_files() end, { desc = "[Telescope] Previous category" })
map("i", "<M-n>", function() require("telescope.builtin").find_files() end, { desc = "[Telescope] Next category" })


--==================================================
--=== UTILS (Clipboard, Counter) ===================
--==================================================

map({ "n", "i", "v", "t" }, "<C-s>", "<cmd>w<CR>", { desc = "[General] Save file" })
map({ "i", "v", "t" }, "jk", "<Esc>", {
  desc = "[General] Exit to normal mode",
  noremap = true,
  silent = true,
})

map("n", "<leader>uz", ":echo len(join(getline(1, '$'), ''))<CR>", { desc = "[Text] Count chars" })
map("n", "<leader>uw", ":echo len(split(join(getline(1, '$'), ''), '\\s\\+'))<CR>", { desc = "[Text] Count words" })
map("n", "copyz", ':let @+=getline(".")<CR>:echo "Copy current line to clipboard"<CR>',
  { desc = "[Text] Copy current line to clipboard" })
map("n", "cpe", ':.,$y+<CR>:echo "Copied from cursor to EOF to clipboard"<CR>',
  { desc = "[Text] Copy from cursor to EOF to clipboard" })
map("n", "cpf", ':%y+<CR>:echo "Copied entire file to clipboard"<CR>',
  { desc = "[Text] Copy entire file to clipboard" })
map("v", "cps", '"+y<CR>:echo "Copied selected text to clipboard"<CR>',
  { desc = "[Text] Copied selected text to clipboard" })


--==================================================
--=== BUFFER / WINDOW / TAB MANAGEMENT =============
--==================================================

map("n", "<leader>del", ":lua confirm_delete()<CR>", { desc = "[General] Delete current selected file w. confirmation" })
map("n", "<leader>d!!", ":call DeleteFile()<CR>",
  { desc = "[General] Delete current selected file wo. confirmation and close buffer" })

--==================================================
--=== GIT (Diffview, Lazygit) ======================
--==================================================

map("n", "<leader>dv", ":DiffviewOpen<CR>", { desc = "[Diffview] open" })
map("n", "<leader>dc", ":DiffviewClose<CR>", { desc = "[Diffview] close" })
map("n", "<leader>dh", ":DiffviewFileHistory<CR>", { desc = "[Diffview] show file history" })

--==================================================
--=== HARPOON (Schnellnavigation) ==================
--==================================================

map("n", "<leader>h", function() require("harpoon.mark").add_file() end, { desc = "[Harpoon] Add file" })
map("n", "<C-h>", function() require("harpoon.ui").toggle_quick_menu() end, { desc = "[Harpoon] toggle ui" })

--==================================================
--=== MISC =========================================
--==================================================

map("n", "<leader>+", function() vim.cmd("vertical resize +5") end, { desc = "[NvimTree] Increase width by 5" })
map("n", "<leader>-", function() vim.cmd("vertical resize -5") end, { desc = "[NvimTree] Decrease width by 5" })

map("n", "<CR>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))        -- Save the current cursor position
  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { "" }) -- Insert an empty line above the current line
  vim.api.nvim_win_set_cursor(0, { row, col })                   -- Restore the cursor to the original position
end, { desc = "[Text] Insert line above without moving the cursor" })

map({ "n", "i", "v" }, "<A-CR>", "o<Esc>^", {
  desc = "[Text] Insert line below and move cursor to beginning",
  noremap = true,
  silent = true,
})

map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "[Text] Move selected lines up" })
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "[Text] Move selected lines down" })

map("t", "<Esc>", "<C-\\><C-n>", { desc = "[Terminals] Exit terminal mode" })
map("t", "<C-c>", "<C-\\><C-n>", { desc = "[Terminals] Exit terminal mode" })
map("t", "<C-t>", function() require("floaterm").toggle() end, { desc = "Floaterm UI toggle" })

--=== NOICE ===

vim.keymap.set({ "n", "i", "s" }, "<c-f>", function()
  if not require("noice.lsp").scroll(4) then
    return "<c-f>"
  end
end, { silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

vim.keymap.set({ "n", "i", "s" }, "<c-b>", function()
  if not require("noice.lsp").scroll(-4) then
    return "<c-b>"
  end
end, { silent = true, expr = true, desc = "[Noice] LSP scroll back" })

vim.keymap.set({ "n", "i" }, "<C-x>", function()
  require("noice").cmd("dismiss")
end, { silent = true, desc = "[Noice] Dismiss UI" })

--==================================================
--=== CUSTOM PLUGINS ===============================
--==================================================

map("n", "<leader>fk", require("custom.mappings_search").search_keymaps,
  { desc = "[Telescope] Find Keymaps (Custom Telescope)" })

map("n", "<leader>fs", require("custom.system_find").system_find,
  { desc = "[Custom] Systemwide filesearch w. extension" })

map("n", "<leader>cd", "<cmd>CompressDir<CR>", { desc = "[Custom] Compress and copy current directory to ~/temp" })

local function copy_current_path()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  print("Copied path to clipboard")
end

vim.keymap.set("n", "<leader>cp", copy_current_path, { desc = "[General] Copy file path to clipboard" })


vim.keymap.set("n", "<C-Esc>", ":qa!<CR>", { noremap = true, silent = true, desc = "[General] Force quit all" })

vim.keymap.set("n", "<leader>dd", function()
  if vim.fn.confirm("Delete all lines in buffer?", "&Yes\n&No", 2) == 1 then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  end
end, { desc = "[Buffers] Delete all lines in curr buffer w confirm" })

map("n", "<leader>tr", ":lua require('base46').toggle_transparency()<CR>",
  { noremap = true, silent = true, desc = "[Color & Theme] Toggle background transparency (buggy!)" })

vim.keymap.set("n", "<leader>bx", function()
  local current = vim.api.nvim_get_current_buf()
  vim.cmd("bnext")
  vim.cmd("bd " .. current)
end, { desc = "[Buffers] Close current, go to next" })

-- === Navigation ===

vim.schedule(function()
  pcall(vim.keymap.del, "i", "<A-h>")
  vim.keymap.set("i", "<A-h>", "<Left>",
    { silent = true, noremap = true, desc = "[Navigation] Move left in insert mode" })
end)


--==================================================
--=== nvchad mapings ===============================
--==================================================

-- GENERAL
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "[General] Clear highlights" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "[General] Save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "[General] Copy whole file" })
map("n", "<leader>ln", "<cmd>set nu!<CR>", { desc = "[General] Toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "[General] Toggle relative number" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "[General] Toggle nvcheatsheet" })
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "[General] Format file" })
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "[General] Whichkey all Keymaps" })
map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
end, { desc = "[General] Whichkey query Lookup" })

-- WINDOW
map("n", "<C-h>", "<C-w>h", { desc = "[Window] Switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "[Window] Switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "[Window] Switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "[Window] Switch window up" })

-- BUFFER
map("n", "xleader>bn", "<cmd>enew<CR>", { desc = "[Buffers] New" })
map("n", "<tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "[Buffers] Goto next" })
map("n", "<S-tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "[Buffers] Goto prev" })
map("n", "<leader>bc", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "[Buffers] Close" })

-- TEXT
map("i", "<C-b>", "<ESC>^i", { desc = "[Text] Move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "[Text] Move end of line" })
map("i", "<C-h>", "<Left>", { desc = "[Text] Move left" })
map("i", "<C-l>", "<Right>", { desc = "[Text] Move right" })
map("i", "<C-j>", "<Down>", { desc = "[Text] Move down" })
map("i", "<C-k>", "<Up>", { desc = "[Text] Move up" })
map("n", "<leader>/", "gcc", { desc = "[Text] Toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "[Text] Toggle comment", remap = true })

-- NVIMTREE
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "[Nvimtree] Toggle window" })

-- LSP
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "[LSP] Diagnostic loclist" })

-- TELESCOPE
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "[Telescope] Live Grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "[Telescope] Find Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "[Telescope] Help Page" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "[Telescope] Find Marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "[Telescope] Find Oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "[Telescope] Find in Current Buffer" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "[Telescope] Git Commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "[Telescope] Git Status" })
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "[Telescope] Pick Hidden Terminal" })
map("n", "<leader>th", function()
  require("nvchad.themes").open()
end, { desc = "[Telescope] NvChad Themes" })
map("n", "<leader>ffn", "<cmd>Telescope find_files<cr>", { desc = "[Telescope] Find Files" })
map("n", "<leader>ffa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "[Telescope] Find All Files" })

-- Terminals
map("t", "<C-x>", "<C-\\><C-N>", { desc = "[Terminals] Escape Terminal Mode" })
map("n", "<leader>tz", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "[Terminals] New horizontal (NvChad)" })
map("n", "<leader>tv", function()
  require("nvchad.term").new { pos = "vsp" }
end, { desc = "[Terminals] New vertical (NvChad)" })
map({ "n", "t" }, "<A-v>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "[Terminals] Toggleable vertical (NvChad)" })
map({ "n", "t" }, "<A-h>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "[Terminals] Toggleable horizontal (NvChad)" })
map({ "n", "t" }, "<A-i>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "[Terminals] Toggle floating (NvChad)" })
