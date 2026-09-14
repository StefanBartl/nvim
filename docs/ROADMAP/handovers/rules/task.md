> Mach weiter mit der vollen 277-Regel-Ermessens-Review von `rules.nvim`
> gegen `ui.nvim`, siehe
> `C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/handovers/rules/rules-nvim-on-ui-nvim.md`
> (Teil 1 = Ausgangsbericht, der Schnell-Check darunter ist bereits
> erledigt). Gehe familienweise vor (`ERR`, `LUA`, `UI`, `CMT`, `SEC`,
> `PRIN`, `PERF`), ein Subagent pro Runde (nie mehr als 1 gleichzeitig),
> gegen die volle Regelliste aus
> `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\regeln\` (bzw.
> `:Rules show <id>` pro Regel). Rohdaten aller 281 Einträge (`id`,
> `severity`, `findings`) liegen in
> `nvim\docs\ROADMAP\reports\rules-nvim-on-ui-nvim.json`. Bei echten
> Funden: fixen, luacheck/stylua grün, Tests grün, committen + direkt auf
> `main` pushen, Handover-Datei nach jeder Runde fortschreiben.
