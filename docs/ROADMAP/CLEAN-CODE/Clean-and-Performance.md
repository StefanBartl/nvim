# Clean Code und Performance bezogene Änderungen

## Table of content

- [Clean Code und Performance bezogene Änderungen](#clean-code-und-performance-bezogene-nderungen)
  - [Syntax](#syntax)
    - [Funktionen, Funktionssignaturen, Methoden](#funktionen-funktionssignaturen-methoden)
  - [Projektstruktur](#projektstruktur)
  - [Cleanup](#cleanup)
    - [`plugins.`](#plugins)
    - [`mappings.`](#mappings)
  - [Optimierungen](#optimierungen)
  - [Dokumentation](#dokumentation)
    - [Update documentation](#update-documentation)
    - [doc/ erstellen](#doc-erstellen)
    - [README](#readme)

---

## Syntax

---

### Funktionen, Funktionssignaturen, Methoden

1. Mehr als 1 optionaler Parameter deutet auf mögliche Anwendung von `varargs` hin. [](Development/wkdbook-Lua/Notes/Funktionen/varargs.md)
2. local funktionen statt exportieren, sofern keine externe Referenz! Alle files durchgehen! Das ist deswegen wichtig, damit man nicht von außen eine FUnktion - zumindest in der Theoprie - requiren und dann neu setzten kann.

--

## Projektstruktur

1. Custom-`lib` implementieren, vor allem:
    - `lib.notify` anstatt `vim.notify()` oder `print()`
    - `lib.map` anstatt `vim.keymap.set`; respektive `lib.usercmd`, `lib.autocmd`, `lib.augroup`
    - `lib.cross_plattform` / `lib.cross`: Alle Module müssen entweder Cross-Plattform sein oder eine alternative innerhalb des Moduls bereitstellen
    - `lib.hover_select`: Ein wrapper der vim.select ersetzt und bei kontinuierlicher Verwendung eine konsequente UI ermöglicht
    - `lib.lazy` ermöglich die Vermeidung unnötiger Ladelast [lib lazy](../../../lua/lib/lazy/README.md)
    - `lib.memo` ermöglicht Standardisierte Memoization
    - uvm...
2. actions.lua für: commands.lua, keymaps.lua in den Modulen
3. mappings.custom erstellen, aus der dann markdown, pathprobe, usw aufgerufen werden, anstatt mappings.markdown, mappings.pathprobe usw..
4. custom.diagnostics erstellen, extra_diagnostice mappings und usrcmds.diagnistcs hinein mergen, dann aus mappings.extra_diagnostics und usrcmds.diagnostics aus ausrufen
5. E:\repos\Notes\MyNotes\Neovim\40_Optimierung\Sauberes-Registrieren-und-Reloaden-von-Events.md implementieren
6. Externe PLugins die usercommands und/oder mappings haben, diese in die `/config/**` verschieben und über die plugin init laden. Am besten ein gemeinsames config/**/actions.lua für Commands, Keymaps und Menüs. [Actions](MyNotes\Neovim\40_Optimierung\Actions_Mappings-Commands-Menu.md)
7. `config.neotree.trash.init.lua`-nmodularisieren - bzw überhaupt alles :-)
8. es ist wrsch beser, die @types immer im modul root zu belassen und nur overall genutzte imt config root

--

## Cleanup

1. überlegen, ob usrcmds nicht eigentlichs usercmds gennant werden sollen
2. Alle mappings, autocmds und usercommand funktionen bei Gelegenheit von `setup()` auf `enable()/attach()` umschreiben
3. `pcall` doppelungen rauscoden
4. `mappings.*` map durch `lib.map` tauschen
5. `<Plug>` in den Mappings verwenden und dabei erlernen wie an sie erstellt
6. `:Recommender -r` einsetzten

---

### `plugins.`

1. Plugin-Logik nach `config.` ausgliedern

---

### `mappings.`

--

## Optimierungen

1. `vim.loader()`- in der init.lua umsetzen -> siehe nvim notes

--

## Dokumentation

### Update documentation

1. (Debugging CONFIGURATION-EXAMPLE update)[../../../lua/debugging/docs/CONFIGURATION-EXAMPLE.md]
2. (Debugging :h update)[../../../lua/debugging/doc/debugging.txt]
3. `usrcmds\migrate\` doc & docs aktulasieren, dass `require("usrcmds.migrate").setup({ opts = enable, notify = true, })` möglich ist;
4. `\usrcmds\migrate\notify` docs und doc aktulasieren, dass ein `:MigrateNotify %/cwd [dest tag]` desc tag übereb wird, der dann in `.create("desc tag")` übergebn wird. AUF ENGLISCH
5. `wkdoptions` readme aktualiseren, module auch readme.md schreiben (deutsch). alußerdem eine doc/
6. `wkddap`: README.md, doc/, docs/, test, Mappings/Usercommands ausbauen usw..

--

### doc/ erstellen

- lua\custom\format\column_align\
- lua\custom\format\filter_lines\a
- lua\custom\format\table\
- lua\custom\format\text_width\
- lua\custom\format\misc
- `custom/filecycle/doc` - muss aktualisert werden

--

### README

- lua\custom\format\filter_lines\
- lua\custom\format\text_width\
- lua\custom\format\misc\

---
