require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")


-- Treesitter
-- Normal mode keymaps
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
-- Visual mode keymaps
map("x", "af", "@function.outer", { desc = "Äußere Funktion im visuellen Modus auswählen" })
map("x", "if", "@function.inner", { desc = "Innere Funktion im visuellen Modus auswählen" })
map("x", "ac", "@class.outer", { desc = "Äußere Klasse im visuellen Modus auswählen" })
map("x", "ic", "@class.inner", { desc = "Innere Klasse im visuellen Modus auswählen" })

-- Telescope
-- Normal mode keymaps
map("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "Find Files" })
map("n", "<leader>fg", function()
require("telescope.builtin").live_grep()
end, { desc = "Live Grep" })
map("n", "<leader><leader>", "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", { desc = "Find all" })
map("n", "<leader>git", "<cmd> Telescope git_files <CR>", { desc = "Öffne Git-Dateien" })
map("n", "<Space>gf", "<cmd> Telescope live_grep <CR>", { desc = "Live-Grep" })
map("n", "<Space>fh", "<cmd> Telescope help_tags <CR>", { desc = "Hilfe-Tags durchsuchen" })
map("n", "<leader>pf", "<cmd> Telescope find_files <CR>", { desc = "Dateien finden" })
map("n", "<Space>comm", "<cmd> Telescope git_commits <CR>", { desc = "Git-Commits anzeigen" })
map("n", "<leader>gs", function()
require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep-Suche" })
map("n", "<leader>tu", ":Telescope<CR>", { desc = "Telescope UI starten" })
-- Insert mode keymaps
map("i", "<M-p>", "<Cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Vorherige Suchkategorie" })
map("i", "<M-n>", "<Cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Nächste Suchkategorie" })

-- Harpoon
-- Normal mode keymaps
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

-- Fugitive
-- Normal mode keymaps
map("n", "<leader>gf", ":Git<CR>", { desc = "Git-Status anzeigen (Fugitive)" })
map("n", "<leader>gk", ":Git commit<CR>", { desc = "Git-Commit erstellen (Fugitive)" })
map("n", "<leader>gi", ":Gdiffsplit<CR>", { desc = "Git-Diff im Split anzeigen (Fugitive)" })
map("n", "<leader>gb", ":Git blame<CR>", { desc = "Git-Blame anzeigen (Fugitive)" })
map("n", "<leader>gs", ":Gstatus<CR>", { desc = "Git: Zeige den Git-Status" })
map("n", "<leader>gd", ":Gdiff<CR>", { desc = "Git: Zeige die Unterschiede" })
map("n", "<leader>gc", ":Gcommit<CR>", { desc = "Git: Führe einen Git-Commit durch" })
map("n", "<leader>gl", ":Glog<CR>", { desc = "Git: Zeige das Git-Log" })
map("n", "<leader>gp", ":Gpush<CR>", { desc = "Git: Pushe Änderungen zum Remote-Repository" })
map("n", "<leader>gu", ":Gpull<CR>", { desc = "Git: Hole die neuesten Änderungen" })





-- Normal mode keymaps
-- Allgemeine Docker-Befehle
map("n", "<leader>dp", ":DockerToolsOpen<CR>", { desc = "Show Docker containers" })
map("n", "<leader>di", ":DockerImages<CR>", { desc = "Show Docker images" })
-- DockerTools Panel
map("n", "<leader>do", ":DockerToolsOpen<CR>", { desc = "Open DockerTools Panel" })
map("n", "<leader>dc", ":DockerToolsClose<CR>", { desc = "Close DockerTools Panel" })
map("n", "<leader>dt", ":DockerToolsToggle<CR>", { desc = "Toggle DockerTools Panel" })
-- Container-Befehle
map("n", "<leader>cs", ":ContainerStart ", { desc = "Start a Docker container" })
map("n", "<leader>cp", ":ContainerStop ", { desc = "Stop a Docker container" })
map("n", "<leader>cr", ":ContainerRemove ", { desc = "Remove a Docker container" })
map("n", "<leader>cl", ":ContainerLogs ", { desc = "Show logs for Docker container" })
-- Benutzerdefinierte Docker-Befehle
vim.api.nvim_create_user_command("DockerLogs", function(opts)
  vim.cmd("split | term docker logs " .. opts.args)
end, { nargs = 1, desc = "Show Docker logs for a container" })

vim.api.nvim_create_user_command("DockerExec", function(opts)
  vim.cmd("split | term docker exec -it " .. opts.args)
end, { nargs = 1, desc = "Execute command in a Docker container" })

vim.api.nvim_create_user_command("DockerRm", function(opts)
  vim.cmd("split | term docker rm " .. opts.args)
end, { nargs = 1, desc = "Remove a Docker container" })
-- Keymaps für benutzerdefinierte Docker-Befehle
map("n", "<leader>dl", ":DockerLogs ", { desc = "Show Docker logs (type container name)" })
map("n", "<leader>de", ":DockerExec ", { desc = "Execute command in Docker container" })
map("n", "<leader>dr", ":DockerRm ", { desc = "Remove Docker container (type name)" })
