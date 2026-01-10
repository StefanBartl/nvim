# clean code und performance bezogene Änderungen

## Table of content

  - [Syntax](#syntax)
  - [Cleanup](#cleanup)
    - [`mappings.`](#mappings)
  - [Update documentation](#update-documentation)

---

## Syntax

1. [lib lazy](../../../lua/lib/lazy/README.md) implementieren
2. local funktionen statt exportieren, sofern keine externe Referenz! Alle files durchgehen! Das ist deswegen wichtig, damit man nicht von außen eine FUnktion - zumindest in der Theoprie - requiren und dann neu setzten kann.
3. namespace von typen explizit einschränken: `recommender -r` nutzen
4. notify-lib implementieren.
5. explizit coden -> `return nil` statt `return` als Beispiel
6. Wenn möglich auf `local M` verzichten und einen benannten Export table erstellen
7. alle Module die etwas exportieren das exportierende Table typisieren
8. Typisierung UsrCmds, Cfg. ...
9. Externe PLugins die usercommands und/oder mappings haben, diese in die `/config/**` verschieben und über die plugin init laden. Am besten ein gemeinsames config/**/actions.lua für Commands, Keymaps und Menüs. [Actions](MyNotes\Neovim\40_Optimierung\Actions_Mappings-Commands-Menu.md)
10. actions.lua für: commands.lua, keymaps.lua in den Modulen
11. `config.neotree.actions.**`: `M`-Tables typisieren

---

## Cleanup

1. `init.lua`: Statusline ausgliedern
2. custom.diagnostics erstellen, extra_diagnostice mappings und usrcmds.diagnistcs hinein mergen, dann aus mappings.extra_diagnostics und usrcmds.diagnostics aus ausrufen
3. Überlegen, ob usrcmds nicht eigentlichs usercmds gennant werden sollen
4. Alle mappings, autocmds und usercommand funktionen bei Gelegenheit von `setup()` auf `enable()/attach()` umschreiben
5. `pcall` doppelungen rauscoden
6. `mappings.*` map durch `lib.map` tauschen
7. `ui.stl_module` auf custom statusline ändern und modularisieren
8. `<Plug>` in den Mappings verwenden und dabei erlernen wie an sie erstellt
9. E:\repos\Notes\MyNotes\Neovim\40_Optimierung\Sauberes-Registrieren-und-Reloaden-von-Events.md

### `plugins.`

1. Logik nach `config.` ausgliedern

### `mappings.`

1. mappings.custom erstellen, aus der dann markdown, pathprobe, usw aufgerufen werden, anstatt mappings.markdown, mappings.pathprobe usw..

---

## Optimierungen

---

## Update documentation

1. (Debugging CONFIGURATION-EXAMPLE update)[../../../lua/debugging/docs/CONFIGURATION-EXAMPLE.md]
2. (Debugging :h update)[../../../lua/debugging/doc/debugging.txt]

## doc/

- lua\custom\format\column_align\
- lua\custom\format\filter_lines\a
- lua\custom\format\table\
- lua\custom\format\text_width\
- lua\custom\format\misc\

--

## README

- lua\custom\format\filter_lines\a
- lua\custom\format\text_width\
- lua\custom\format\misc\

---
