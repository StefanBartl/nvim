# cmdlog.nvim

## Zweck
Interaktives Picker-Interface (Telescope oder fzf-lua) für `:`-Kommando-Historie und Shell-History,
mit Favoriten, Tags, projektbezogener History, Nutzungsstatistik, "known-error"-Highlighting und
Erkennung riskanter Kommandos (`rm -rf`, `git push --force`, …). Laut README noch Beta-Status
("Expect bugs, especially with the history feature on windows systems").

## Nicht-standard Patterns / Algorithmen

- `lua/cmdlog/core/shell.lua:88-158` (`get_shell_name`) — mehrstufige Shell-Erkennung: zuerst
  `$SHELL` (POSIX), dann — weil `$SHELL` unter Windows typischerweise fehlt — ein Sondieren
  bekannter History-Datei-Pfade in plattformabhängiger Präferenzreihenfolge (PowerShell zuerst
  unter Windows). Reagiert damit auf eine reale Plattformlücke statt sich blind auf eine
  Environment-Variable zu verlassen, die auf einem der Zielsysteme gar nicht existiert.
- `lua/cmdlog/core/shell.lua:234-293` (`get_shell_history`) — pro Shell ein eigener Parser
  (zsh: `: <ts>:<dur>;cmd`, fish: YAML-artige `- cmd: '...'` mit JSON-Decode-Trick zum Entschärfen
  von Escape-Sequenzen, bash/ksh/csh: Klartext mit `#<timestamp>`-Kommentarzeilen-Filter). Der
  JSON-Decode-Trick (`vim.fn.json_decode('"' .. cmd .. '"')`) missbraucht den JSON-String-Parser,
  um Fish-eigene Escape-Sequenzen korrekt zu dekodieren, statt einen eigenen Escape-Parser zu
  schreiben — pragmatische Wiederverwendung eines vorhandenen, korrekten Parsers.
- `lua/cmdlog/core/shell.lua:295-317` (`line_matches_command`) — beim Löschen eines Eintrags wird
  dieselbe Parse-Logik wie beim Lesen dupliziert (statt sie zu teilen), aber explizit als "Mirrors
  the per-shell parsing" dokumentiert; Risiko: Parser-Änderungen müssen synchron an zwei Stellen
  gepflegt werden — im Code selbst als Wartungslast markiert, nicht versteckt.
- `lua/cmdlog/core/shell.lua:319-382` (`delete_entry`) — Löschen eines History-Eintrags schreibt
  die komplette Datei neu (`kept`-Liste ohne Treffer), aber nur nach explizite Bestätigung
  (`kit.confirm`), weil es eine destruktive Datei-Operation auf potenziell nicht von cmdlog
  verwaltete Dateien ist (die Shell könnte parallel in dieselbe Datei schreiben) — bewusste
  Sicherheitsbremse statt stillem Rewrite.
- `lua/cmdlog/core/risky.lua` — Highlighting gefährlicher Kommandos ist rein Pattern-basiert
  (`cmd:find(pattern)`) und komplett vom "known-error"-Mechanismus (`core/errors.lua`) getrennt;
  `ui/picker_utils.lua:43-74` kombiniert beide bewusst als unabhängige Signale ("failed when you
  ran it" vs. "destructive by nature") statt sie zu einer Kategorie zu verschmelzen — der Kommentar
  im Code macht diese Designentscheidung explizit.
- `lua/cmdlog/core/tracker.lua` — GENAU EIN `CmdlineLeave`-Autocmd speist `project_history`,
  `stats` und `errors` gemeinsam, statt dass jedes Feature-Modul sein eigenes Autocmd registriert.
  Grund laut Kommentar: alle Konsumenten sollen exakt dieselbe Menge ausgeführter Kommandos sehen
  (keine Divergenz durch leicht unterschiedliche Autocmd-Bedingungen an mehreren Stellen).
  Für die Fehlererkennung wird zusätzlich `vim.v.errmsg` vor und (via `vim.schedule`) nach dem
  Kommando verglichen, um zu erkennen, ob das Kommando einen NEUEN Fehler gesetzt hat.
- `lua/cmdlog/core/store.lua` — JSON-Persistenz bewusst ohne `plenary.path`, komplett über
  lib.nvim-Dateisystem-Helper (`fs.write.to_file` legt fehlende Parent-Verzeichnisse inkl.
  Windows/Unix-Sonderfällen selbst an). Kommentar verweist explizit darauf, dass eine
  plenary-Abhängigkeit hier bewusst entfernt wurde.
- `lua/cmdlog/bindings/keymaps.lua:20-34` — der Katalog mappbarer Subcommands wird aus
  `bindings.usrcmds.catalog` abgeleitet statt als zweite, separat gepflegte Liste dupliziert zu
  werden — verhindert, dass ein neues Subcommand für Keymap-Registrierung "vergessen" wird.
  Ein Tippfehler im Config-Key führt zu einer expliziten `notify.warn` statt eines still toten
  Keymaps (Zeile 52-56).

## Abgeleitete Guidelines

1. Plattform-/Environment-Erkennung nie auf eine einzelne Variable verlassen, wenn bekannt ist,
   dass sie auf einer Zielplattform typischerweise fehlt (`$SHELL` unter Windows) — stattdessen
   mit einer geordneten Fallback-Kette aus Datei-/Pfad-Sonden arbeiten.
2. Destruktive Dateioperationen (History-Datei umschreiben, o.ä.) grundsätzlich hinter einer
   expliziten Bestätigung (`kit.confirm` o.ä.) verstecken, auch wenn `skip_confirm` für
   Automatisierung angeboten wird — nie stillschweigend überschreiben.
3. Wenn dieselbe Parse-/Match-Logik an zwei Stellen (Lesen vs. Löschen/Suchen) gebraucht wird,
   entweder wirklich teilen oder — falls das aus strukturellen Gründen nicht geht — die Duplikation
   im Docstring explizit als "Mirrors X" kennzeichnen, damit zukünftige Änderungen synchron bleiben.
4. Mehrere unabhängige Konsumenten desselben Events (hier: History-Tracking für drei Features)
   über EIN zentrales Autocmd speisen statt mehrere leicht unterschiedliche Autocmds zu
   registrieren — vermeidet Divergenz zwischen den Konsumenten.
5. Unabhängige Klassifikations-Dimensionen (hier: "riskant" vs. "zuletzt fehlgeschlagen") nicht
   zu einer Kategorie verschmelzen, wenn sie tatsächlich unabhängige Aussagen treffen — beide
   Signale getrennt berechnen und im UI kombinieren.
6. Dateisystem-I/O grundsätzlich über die zentrale lib.nvim-fs-Schicht statt über plenary.nvim
   oder eigene Mkdir-Reimplementierungen — Cross-Platform-Edge-Cases sind dort bereits gelöst.
7. Konfigurierbare Keymap-Kataloge aus der bereits vorhandenen Command-Registrierung ableiten
   statt separat zu pflegen; bei unbekannten Konfigurationsschlüsseln explizit warnen statt
   still zu ignorieren.
8. Bei Soft-Dependencies auf mehrere UI-Backends (Telescope/fzf-lua) Feature-Unterschiede (z.B.
   "Preview nur bei Telescope") in Doku und Code klar benennen, statt eine einheitliche API
   vorzutäuschen, die es nicht gibt.

## Keybindings-Audit

Eigene Plugin-Keymaps: laut README/`bindings/keymaps.lua` KEINE festen Default-Keymaps außerhalb
der Picker — normalmodale Entry-Point-Keymaps sind vollständig optional und werden erst über
`setup({ keymaps = {...} })` aktiv (`keymaps = { [""] = "<leader>hc", favorites = "<leader>hf" }`).

Picker-interne Shortcuts (aus README "Shortcuts (inside pickers)"):
- `<CR>` — Kommando in `:` einfügen (nicht ausführen). Count n/a (Selektion).
- `<Tab>` — Favorit umschalten. Count n/a.
- `<C-r>` — Picker refresh. Count n/a.
- `<C-t>` / `ctrl-t` (nur Telescope, nur Favorites-Picker) — Tag hinzufügen. Count n/a.
- `<C-x>` (konfigurierbar) — einzelnen History-Eintrag löschen (mit Bestätigung bei Shell-History).
  Count n/a — Aktion bezieht sich auf genau den selektierten Eintrag.
- `<C-f>` (laut Feature-Liste) — Favorit umschalten in bestimmten Picker-Kontexten.

Da alle Aktionen auf der aktuell selektierten Picker-Zeile arbeiten, ist `count`-Unterstützung
durchgehend nicht anwendbar (n/a) — das Konzept passt nicht zu einer Fuzzy-Picker-UI.

Autocompletion:
- `:Cmdlog [subcommand]` hat `<Tab>`-Completion über `lib.nvim.usercmd.composer` (laut README) —
  vorhanden und sinnvoll, da alle sieben vormals separaten Picker-Commands jetzt unter einem
  Verb zusammengefasst sind.
- Innerhalb der Picker selbst ist "Autocompletion" durch Fuzzy-Search (Telescope generic_sorter /
  fzf) ersetzt, was für diesen Anwendungsfall angemessen ist.

Fehlende Flags/Optionen (Ideen):
- Kein Multi-Select/Batch-Delete für History-Einträge (nur Einzel-Löschung via `<C-x>`).
- `risky_patterns` ist eine reine Lua-Pattern-Liste ohne Vorschau, welches Pattern konkret
  gematcht hat — für Debugging/Tuning der eigenen Patterns könnte ein `:Cmdlog risky test <cmd>`
  helfen.
- Shell-History-Parser für zsh/fish/bash sind hart codiert; kein Escape-Hatch für exotische
  History-Formate (z.B. benutzerdefinierte `HISTTIMEFORMAT`).

## Ideen für andere Plugins

- Das "ein zentrales Autocmd speist mehrere unabhängige Feature-Module"-Muster
  (`core/tracker.lua`) ist ein gutes generisches Vorbild für jedes Plugin, das mehrere Analysen
  auf demselben Event fahren will (z.B. project-insight.nvim: ein `BufWritePost` für Linting,
  Indexierung und Stats statt drei einzelne Autocmds).
- Die plattformabhängige Fallback-Sondierung für Shell-/Environment-Erkennung
  (`core/shell.lua:M.get_shell_name`) wäre als generisches lib.nvim-Modul
  ("cross.shell.detect") wertvoll — mehrere Plugins (cmdlog, evtl. zukünftige Terminal-Helfer)
  brauchen plattformrobuste Shell-Erkennung und würden sonst denselben Code erneut schreiben.
- Die getrennte "riskant" vs. "bekannt fehlgeschlagen" Klassifikation von Kommandos liesse sich zu
  einem eigenständigen Mini-Plugin "safeguard.nvim" verallgemeinern: ein generischer Kommando-
  Interceptor, der vor Ausführung eines als riskant markierten `:`- oder Shell-Kommandos
  (konfigurierbare Pattern-Liste) eine Bestätigung einfordert — nicht nur retroaktiv im Picker
  highlighten, sondern proaktiv vor der ersten Ausführung warnen.
