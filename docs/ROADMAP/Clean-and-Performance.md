# clean code und performance bezogene önderungen

1. local funktionen statt exporieren wenn keine externe Referenz! Alle files durchgehen!
2. explizit coden -> `return nil` statt `return` als Beispiel

## Cleanup

1. `init.lua`: Statusline ausgliedern
2. mappings.custom erstellen, aus der dann markdown, pathprobe, usw aufgerufen werden, anstatt mappings.markdown, mappings.pathprobe usw..
3. custom.diagnostics erstellen, extra_diagnostice mappings und usrcmds.diagnistcs hinein mergen, dann aus mappings.extra_diagnostics und usrcmds.diagnostics aus ausrufen
4. Überlegen, ob usrcmds nicht eigentlichs usercmds gennant werden sollen
5. Alle mappings, autocmds und usercommand funktionen bei Gelegenheit von `setup()` auf `enable()/attach()` umschreiben
6. `pcall` doppelungen rauscoden


