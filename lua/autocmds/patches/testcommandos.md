" Status leeren (für Fresh-Start)
:lua require("autocmds.patches").clear_status()

" 2. Verbose-Mode aktivieren
 :lua require("autocmds.patches").setup({ verbose = true })

" Alle Patches anwenden (mit neuer Normalisierung)
:lua require("autocmds.patches").apply_all_async()

" Status prüfen
:lua vim.print(require("autocmds.patches").get_status())

" Logs anschauen (DEBUG-Meldungen zur Normalisierung)
:lua require("autocmds.patches").show_logs_buffer()
