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

" Prüfe Status VOR clear
:lua vim.print(require("autocmds.patches.status").get_all())

" Clear
:PatchClear

" Prüfe Status NACH clear
:lua vim.print(require("autocmds.patches.status").get_all())

" Preprocessing deaktivieren (Fallback zu Original-Patches)
:lua require("autocmds.patches.preprocessor").create_temp_patch = function(patch, target) return patch, nil end

" Autocommand temporär deaktivieren
:autocmd! LocalPluginPatches

" Manuelle Anwendung ohne System
:lua vim.fn.system("patch -p0 -i path/to/patch target/file")


" Status zurücksetzen USERPMMAND?
:lua require("autocmds.patches").clear_status()

" Einzelner Patch mit Verbose-Logging
:PatchVerbose on
:lua require("autocmds.patches").apply_async({ keys = { "noice-lsp-signature" } })

" Alle Patches (neuer Command)
:PatchApplyAll

" Status prüfen
:lua vim.print(require("autocmdlua require("autocmds.patches").clear_status()s.patches").get_status({ status_filter = { "failed" } }))

" Logs anschauen
:PatchLogs
