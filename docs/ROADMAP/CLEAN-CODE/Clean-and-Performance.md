# clean code und performance bezogene Änderungen

## Table of content

  - [Syntax](#syntax)
  - [Cleanup](#cleanup)

---

## Syntax

1. [lib lazy](.\lua\lib\lazy\README.md) implementieren
2. local funktionen statt exportieren, sofern keine externe Referenz! Alle files durchgehen!
3. namespace von typen explizit einschränken: `recommender -r` nutzen
4. notify-lib implementieren.
5. explizit coden -> `return nil` statt `return` als Beispiel
6. Wenn möglich auf `local M` verzichten und einen benannten Export table erstellen
7. alle Module die etwas exportieren das exportierende Table typisieren
8. Typisierung UsrCmds, Cfg. ...
9. Externe PLugins die usercommands und/oder mappings haben, diese in die `/config/**` verschieben und über die plugin init laden. Am besten ein gemeinsames config/**/actions.lua für Commands, Keymaps und Menüs. [Actions](MyNotes\Neovim\40_Optimierung\Actions_Mappings-Commands-Menu.md)

actions.lua, commands.lua, keymaps.lua

---

## Cleanup

1. `init.lua`: Statusline ausgliedern
2. custom.diagnostics erstellen, extra_diagnostice mappings und usrcmds.diagnistcs hinein mergen, dann aus mappings.extra_diagnostics und usrcmds.diagnostics aus ausrufen
3. Überlegen, ob usrcmds nicht eigentlichs usercmds gennant werden sollen
4. Alle mappings, autocmds und usercommand funktionen bei Gelegenheit von `setup()` auf `enable()/attach()` umschreiben
5. `pcall` doppelungen rauscoden

### `mappings.`

1. mappings.custom erstellen, aus der dann markdown, pathprobe, usw aufgerufen werden, anstatt mappings.markdown, mappings.pathprobe usw..

---
