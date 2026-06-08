# Verbesserungsliste

> Empfohlene Reihenfolge:
    - zuerst Punkte 3, 4, 8, 10 wegen Sicherheit/Korrektheit
    - danach 1 und 2 für Performance/Struktur
    - danach 6, 7, 11, 12 als nachhaltige Pflegearbeit.

## 1. Autocmds zentralisieren

Viele Module nutzen direkt `vim.api.nvim_create_autocmd`, obwohl `lib.autocmd` existiert. Das betrifft z. B. [options.lua](C:/Users/bartl/AppData/Local/nvim/lua/options.lua:79), [hl_config/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/init.lua:212), [astro/autocmds.lua](C:/Users/bartl/AppData/Local/nvim/lua/lsp/languages/webdev/astro/autocmds.lua:12). Verbesserung: nach und nach auf `lib.autocmd` bzw. den vorhandenen FileType-Dispatcher migrieren, damit Fehlerbehandlung, Gruppen und Reload-Verhalten einheitlich sind.

## 2. High-Frequency-Events budgetieren

Mehrere Features laufen auf `CursorMoved`, `WinScrolled`, `TextChanged`, `BufEnter`. Besonders relevant: [indent_scope.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/features/indent_scope.lua:228), [cword_occurrences/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/cword_occurrences/init.lua:345), [breadcrumbs/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/wkdoptions/hl_config/breadcrumbs/init.lua:91). Verbesserung: gemeinsamer Debounce/Dispatcher pro Eventklasse, Context-Objekt einmal erzeugen, Feature-Handler nur ausführen wenn wirklich sichtbar/aktiv.

## 3. Shell-Kommandos von Strings auf argv umstellen

Es gibt einige String-Shell-Aufrufe mit zusammengesetzten Pfaden, z. B. [sessions/usercmds.lua](C:/Users/bartl/AppData/Local/nvim/lua/sessions/usercmds.lua:74), [line_diff_on_hold.lua](C:/Users/bartl/AppData/Local/nvim/lua/autocmds/git/line_diff_on_hold.lua:99), [astro/autocmds.lua](C:/Users/bartl/AppData/Local/nvim/lua/lsp/languages/webdev/astro/autocmds.lua:69). Verbesserung: `vim.system({ ... })` oder `lib.cross.run[_argv]` verwenden. Das reduziert Quoting-Bugs, Injection-Risiko und Plattformprobleme.

## 4. **Konkreten `pcall`-Bug fixen**
[sessions/usercmds.lua](C:/Users/bartl/AppData/Local/nvim/lua/sessions/usercmds.lua:26) nutzt `pcall(vim.cmd("..."))`; dadurch wird `vim.cmd` vor `pcall` ausgeführt. Verbesserung: als Funktion kapseln. Das ist klein, aber tatsächlich fehlerrelevant.

## 5. **Startup-Phasen konsequenter machen**
In [init.lua](C:/Users/bartl/AppData/Local/nvim/init.lua:80) wird LSP direkt geladen, obwohl der Kommentar noch BufReadPost/Lazy andeutet. Gleichzeitig werden `wkdoptions`, `autocmds`, `custom`, `usrcmds`, `mappings` per Timer geladen. Verbesserung: Startup-Plan als echte Policy dokumentieren und messen: was muss synchron sein, was kann auf `VeryLazy`, `BufReadPost`, `FileType`, `CmdlineEnter`.

## 6. **Direkte `vim.notify`, `print`, `vim.keymap.set` reduzieren**
Die Checklisten wollen `lib.notify`, `lib.map`, `lib.usercmd`. Direkte Treffer gibt es u. a. in [mappings/git.lua](C:/Users/bartl/AppData/Local/nvim/lua/mappings/git.lua:23), [custom/pathprobe/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/custom/pathprobe/init.lua:448), [sessions/usercmds.lua](C:/Users/bartl/AppData/Local/nvim/lua/sessions/usercmds.lua:61). Verbesserung: produktive Module migrieren; Debug-/Testmodule dürfen ggf. separat markiert bleiben.

## 7. **Große Verantwortungsinseln aufsplitten**
Einige Module sind fachlich breit: [config/trouble/spell/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/config/trouble/spell/init.lua:1), [custom/format/table/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/custom/format/table/init.lua:1), [custom/pathprobe/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/custom/pathprobe/init.lua:1). Verbesserung: `state`, `parser`, `actions`, `ui`, `commands`, `keymaps` trennen. Das passt direkt zu SRP und macht Tests leichter.

## 8. **Buffer/Window-Handles in Deferred/Scheduled-Code härten**
Einige Callbacks arbeiten später mit implizit aktuellem Window/Buffer, z. B. [pathprobe/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/custom/pathprobe/init.lua:306), [neotree/commands/clipboard/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/config/neotree/commands/clipboard/init.lua:286). Verbesserung: beim Scheduling `bufnr/winid` snapshotten und vor Nutzung erneut validieren.

## 9. **Filesystem-Operationen stärker vereinheitlichen**
Neo-tree hat Safety/Backup/Trash, aber Clipboard-Copy/Move macht eigene rekursive Logik in [clipboard/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/config/neotree/commands/clipboard/init.lua:43). Verbesserung: gemeinsame FS-Operation-Schicht für copy/move/delete/create mit Dry-run, Backup, Quarantine, Layout-Guard und einheitlichen Rückgaben.

## 10. **Gefährliche Fallbacks beim Trash prüfen**
[trash/platform/init.lua](C:/Users/bartl/AppData/Local/nvim/lua/config/neotree/trash/platform/init.lua:57) nutzt auf Windows als Fallback echtes `Remove-Item`, also nicht mehr Papierkorb. Verbesserung: klar als “destructive fallback” konfigurierbar machen oder deaktivieren, plus deutlichere Fehler-/Recovery-Strategie.

## 11. **Dokumentationsregel realistisch staffeln**
Der Scan zeigt sehr gute `@module`-Abdeckung: 1084 von 1096 Lua-Dateien. Die strengere Regel “jedes `lua/config`-Modul braucht README und doc/help” ist aber breit nicht erfüllt, z. B. [config/neotree](C:/Users/bartl/AppData/Local/nvim/lua/config/neotree), [config/fzf](C:/Users/bartl/AppData/Local/nvim/lua/config/fzf), [config/telescope](C:/Users/bartl/AppData/Local/nvim/lua/config/telescope). Verbesserung: erst für öffentliche/komplexe Module, nicht für jedes kleine Unterverzeichnis.

## 12. **Format-/Tooling-Lücke schließen**
`stylua` war in der Shell nicht verfügbar. Verbesserung: Format/Lint als reproduzierbaren lokalen Command definieren, z. B. über Mason, lazy task oder Repo-Script. Dann kann jede spätere Änderung automatisch gegen Stil und Syntax geprüft werden.

## 13. **Konfig-Duplikate und Altpfade aufräumen**
Es gibt parallele Bereiche wie `config/menu` und `config/menu-update`, außerdem kommentierte Altpläne in [init.lua](C:/Users/bartl/AppData/Local/nvim/init.lua:91). Verbesserung: Altpfade archivieren oder explizit als “experimental/deprecated” markieren, damit Architekturentscheidungen wieder leichter lesbar werden.

## 14. **Low-Level-Module ohne UI-Seiteneffekte halten**
Einige Core-nahe Module melden direkt per Notify, z. B. LSP-Capabilities oder FS-/PDF-Port-Backendbereiche. Verbesserung: Low-Level gibt `{ ok, err }` zurück; UI-Schicht entscheidet über `notify`. Das würde deine Fehlerbehandlung konsistenter machen.

