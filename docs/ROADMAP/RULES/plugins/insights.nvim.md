# insights.nvim

## Zweck
Projekt-Analyse-Plugin für Neovim: kombiniert ripgrep-basierte Symbol-Indizierung, Tree-sitter-
Lua-Scanning, Code-Metriken, Dateibaum-Utilities und Buffer-Info hinter einem einzigen
`:Insights`-Kommando (`E:\repos\insights.nvim\README.md:21-23`). Hängt zwingend von `lib.nvim`
und `rg` (ripgrep) ab.

## Nicht-standard Patterns / Algorithmen

- `E:\repos\insights.nvim\lua\insights\bindings\usrcmds.lua:1-26` — Composer-Routen liefern nur
  das Typ-Schema für Tab-Completion; das eigentliche Dispatching läuft komplett getrennt über
  `handle_*`-Funktionen, die Tokens ordnungsunabhängig parsen (`handle_symbols`,
  Zeile 171-215: die Reihenfolge von `cwd|buffer`, `telescope|fzf|scratch`, `functions|tables|
  strings`, `rebuild` ist beliebig). Grund laut Kommentar (Zeile 19-25): eine feste Positional-
  Grammatik würde diese "beliebige Reihenfolge"-Semantik brechen; stattdessen deklariert die Route
  N identische optionale Slots desselben Typs (`repeated_args`, Zeile 550-562), damit Composer an
  jeder Position dieselben Completion-Kandidaten anbietet.
- `E:\repos\insights.nvim\lua\insights\bindings\usrcmds.lua:104-129` — `reconstruct_metrics_tokens`
  baut aus Composer's gebundenem `ctx.flags`/`ctx.pos` wieder die ursprüngliche flache
  `--flag`/`--flag=value`-Tokenliste zusammen, nur damit der unveränderte `parse_metrics_args`-
  Parser (Zeile 221-269) weiterläuft. Bewusster Umweg statt Neuimplementierung: verhindert, dass
  Parser-Sonderfälle wie `--lua-only`, das zwei Optionsfelder gleichzeitig setzt (Zeile 240-242),
  beim Migrieren auf Composer erneut nachgebildet werden müssten.
- `E:\repos\insights.nvim\lua\insights\imports\graph.lua:42-65` — `build_dot` dedupliziert
  Kanten über einen zusammengesetzten String-Key (`filename .. "\1" .. module`, Zeile 59) mit
  Kontrollzeichen `\1` als Trenner statt z.B. verschachtelter Tabellen — vermeidet Kollisionen,
  falls Dateiname oder Modulname zufällig ein anderes Trennzeichen enthalten.
- `E:\repos\insights.nvim\lua\insights\imports\graph.lua:1-24` — reine Funktion `build_dot`
  bewusst von der Graphviz-Ausführung getrennt: "Pure function — reused directly by the test
  suite, no Graphviz/terminal needed to check it" — Testbarkeit ohne externe Toolchain-Abhängigkeit.

## Abgeleitete Guidelines

1. Für Kommandos mit ordnungsunabhängigen Tokens (Scope/Typ/UI in beliebiger Reihenfolge) eine
   Menge identischer optionaler Positional-Slots deklarieren statt einer starren Grammatik — sonst
   bricht entweder die Reihenfolge-Freiheit oder die Auto-Completion an späteren Positionen.
2. Bei Migration auf eine neue Command-Infrastruktur (hier: composer) den bewährten Parser NICHT
   umschreiben, sondern die Rohdaten aus der neuen Infrastruktur in das alte Format zurückführen —
   reduziert Regressionsrisiko bei komplexer bestehender Flag-Logik.
3. Graph-/Report-Bauer als reine Funktionen (Eingabedaten → Ausgabestring) von der ausführenden
   Seite (externe Tools, Dateisystem, UI) trennen, damit sie ohne die externe Abhängigkeit
   getestet werden können.
4. Deduplizierungs-Keys aus zusammengesetzten Strings mit einem garantiert nicht vorkommenden
   Trennzeichen bilden, wenn ein Tabellen-Key nicht in Frage kommt.

## Keybindings-Audit
Aus `E:\repos\insights.nvim\lua\insights\bindings\keymaps.lua:1-47`, alle optional/config-driven
(deaktivierbar via `false`):

- `cfg.fileinfo.keymap` → `insights.fileinfo.show()` (Float mit `fs.stat`-Infos zum Buffer).
  - Count: n.a. — Toggle einer Info-Anzeige, kein Wiederholungs-sinnvoller Fall.
  - Autocompletion: n.a. (kein Ex-Command-Input).
  - Fehlend: keine Flags nötig für einen reinen Toggle.
- `cfg.keymaps.symbols_telescope` → Symbol-Picker via Telescope (cwd-Scope, `functions`-Typ fix).
  - Count: nein — sinnvoll wäre z.B. `2<leader>ps` für Scope "buffer" statt "cwd", ist aber nicht
    implementiert; die Keymap ruft immer `symbols.get()` ohne Scope-Parameter (Zeile 22-31).
  - Autocompletion: n.a. (Keymap, kein Ex-Command).
  - Fehlend: kein direkter Weg, über die Keymap den Symbol-Typ (tables/strings) oder Scope
    (buffer) zu wählen — nur über `:Insights symbols` möglich.
- `cfg.keymaps.symbols_fzf` — analog zu `symbols_telescope`, nur mit fzf-Picker.
  - Count/Autocompletion/Fehlend: identisch zum Telescope-Pendant.

`:Insights <subcmd>` (`usrcmds.lua`) unterstützt volle Tab-Completion über den lib.nvim-Composer
für alle Subcommands (`symbols`, `metrics`, `imports`, `cache`, `devserver`, …) inkl. typisierter
Flags (`metrics_flag_specs`, Zeile 94-103) — vorbildliche Pflicht-Erfüllung der Autocompletion-
Anforderung, da hier ein Ex-Command direkt betroffen ist.

## Ideen für andere Plugins
- Ein eigenständiges "dependency graph diff"-Tool, das zwei `insights.imports`-Scans (z.B. vor/
  nach einem Refactor) vergleicht und nur die geänderten Kanten rendert — baut direkt auf
  `build_dot`s reiner Edge-Liste auf.
- Ein generisches "Symbol-Type-Picker-Dispatcher" als lib.nvim-Baustein: die drei fast identischen
  `open_symbol_picker`-Verzweigungen (telescope/fzf/scratch) tauchen so oder ähnlich vermutlich in
  mehreren Plugins auf und könnten in `lib.nvim.nvim.ui` wandern.
