# runtime-analysis.nvim

## Zweck
In-Editor HTTP-Request-Runner (`:RA request`/`:RA send`, im REST-Client/HTTP-Client-Textformat,
`###`-getrennte Multi-Request-Buffer, GraphQL/Multipart-Support, `{{var}}`-Environments,
Request-History, curl-Import/-Export) plus ein generisches, opt-in Telemetrie-Modul
(`runtime-analysis.telemetry`, aus lib.nvim ausgelagert: Call-Counting, Argument-Fingerprinting,
Reports) und Runtime-Introspection (`:RA provenance`, `:RA inspect`, `:RA usage`). Pendant zu
documentation.nvim: "runtime truth" statt "static truth" (README.md:28-32).

## Nicht-standard Patterns / Algorithmen

- `lua/runtime-analysis/history.lua:83-105` (`M.record`) — Request-History speichert
  bewusst NUR method/url/status/timestamp, nie Header oder Body. Grund explizit
  dokumentiert (Zeile 8-22): ein Header ist oft der Ort des echten Secrets
  (`Authorization: Bearer ...`), ein Response-Body kann groß sein und selbst Secrets
  enthalten. Sicherer Default statt "speichere alles, dokumentiere die Gefahr".

- `lua/runtime-analysis/history.lua:86-93` — Kommentar zur klassischen Lua-Falle
  `a and b or c`: wenn `b` selbst falsy ist (hier `nil` als `note`), gewinnt immer
  der `c`-Zweig unabhängig von `a`. Deshalb explizites `if not status then final_note = note end`
  statt der Kurzform. Laut Kommentar durch einen fehlschlagenden Test entdeckt, nicht durch
  Code-Review — Hinweis, dass dieses Lua-Idiom hier tatsächlich zugeschlagen hat.

- `lua/runtime-analysis/history.lua:29-35` — History-Cap per Count (`MAX_ENTRIES = 200`)
  statt zeitbasiert, weil Einträge klein sind und ein Count-Cap "genauso effektiv, aber
  einfacher" ist als ein Zeitfenster. Gleiche Disziplin wie das Argument-Fingerprinting in
  telemetry (begrenzte Kardinalität).

- `lua/runtime-analysis/history.lua:37-58` (`sanitize`) — Cache-Key wird gegen
  `[^%w%-%._]` whitelist-gefiltert, weil `cache.disk` den Pfad ungeschützt aus
  `dir .. "/" .. namespace .. ".json"` baut und `project_key()` einen absoluten Pfad
  (Slashes, Windows-Laufwerksbuchstaben, Doppelpunkte) liefert, der sonst aus dem
  Cache-Verzeichnis "ausbrechen" oder das Schreiben schlicht zum Scheitern bringen würde.
  Bewusst dupliziert statt aus telemetry importiert — drei Zeilen reiner String-Code,
  ein Cross-Modul-Abhängigkeit wäre teurer als die Duplikation.

- `lua/runtime-analysis/env.lua:169-193` — `{{var}}`-Resolution läuft strikt einmalig,
  unmittelbar bevor der Request an curl geht; der aufrufende Code (`bindings/usrcmds.lua`)
  hält bewusst zwei Kopien (roh vs. resolved) auseinander, damit History und die
  "sending..."-Anzeige den literalen Platzhalter zeigen, nie den aufgelösten Wert
  (Secret-Leak-Vermeidung, gleiche Denke wie bei history.lua).

- `lua/runtime-analysis/env.lua:80-99` (`warn_if_not_gitignored`) — Best-effort-Check
  (String-Suchen des Dateinamens im `.gitignore`-Inhalt statt echtem Gitignore-Parser),
  warnt höchstens einmal pro Session. Explizit als unvollständig dokumentiert (ein
  Wildcard-Pattern würde den Check täuschen), aber als "billige Versicherung" bewusst
  in Kauf genommen statt eine korrekte Gitignore-Engine zu bauen.

- `lua/runtime-analysis/runner.lua:43-69` (`try_pretty_json`) — `vim.json.encode(value,
  {indent=N})` wurde verifiziert NICHT zu funktionieren (fügt den literalen Text von N
  ein statt einzurücken) und durch `lib.lua.json.encode.pretty` ersetzt. Beleg für
  "gegen echtes Verhalten verifizieren, nicht gegen Doku vertrauen".

- `lua/runtime-analysis/runner.lua:131-166` (`M.run_async`) — jeder Callback wird
  zwingend durch `vim.schedule` geführt, weil `fetch_raw`'s Completion-Callback in einem
  Fast-Event-Context feuert (verifiziert: ein bare `nvim_create_buf` darin wirft `E5560`).
  Zentral einmal garantiert statt als Caller-Pflicht dokumentiert — vermeidet eine ganze
  Klasse von "vergessen zu schedulen"-Bugs.

- `lua/runtime-analysis/bindings/usrcmds.lua:94-146` — "Cancel" ist ein *logischer*
  Cancel per Pending-Token-Zähler, kein echter Prozess-Kill: `fetch_raw` gibt kein
  `vim.SystemObj` zurück, das killbar wäre. Ein neuer Send erhöht den Token, ein
  ankommender älterer Callback mit veraltetem Token wird stillschweigend zum No-op statt
  eine Queue oder "already in flight"-Ablehnung zu bauen (Zeile 246-260, 319-401).
  Ein *superseded* (durch neueren Send überholter) Request wird trotzdem noch in die
  History geschrieben (Zeile 350-365) — sein reales Ergebnis ist es wert, behalten zu
  werden, obwohl nichts es mehr rendert; ein *cancelled* Request dagegen wurde schon beim
  Cancel selbst aufgezeichnet und würde sonst doppelt erscheinen.

- `lua/runtime-analysis/provenance.lua:28-64` (`resolve_container`) — zwei Strategien
  (Global-Table-Walk dann `require()`) versucht, aber explizit NICHT versucht, tiefer
  zu raten, wo eine Modulgrenze innerhalb eines verschachtelten Pfads (`a.b.c.field`)
  liegt — konsistent mit anderen Stellen im Code (curl.lua, cost_vs_use.lua), die "raten
  wäre die falsche Art von raten" ebenfalls ablehnen.

- `lua/runtime-analysis/telemetry/fingerprint.lua` — Argument-Fingerprinting ist bewusst
  KEIN Serializer: Strings werden bei 40 Zeichen abgeschnitten, Tabellen nur als Shape
  (`<table:#3>`, `<table:map>`, `<table:empty>`) erfasst, nie als Inhalt. Explizit als
  Security-Grenze benannt (Zeile 6-9): "ein Profiler, der echte Werte speichert, ist ein
  Security-Bug mit Feature-Namen." Variadic-Argumente über `MAX_ARGS = 4` werden als
  `…+N` zusammengefasst statt einen Fingerprint pro Arity zu erzeugen (unbegrenzte
  Kardinalität vermeiden).

## Abgeleitete Guidelines

1. Persistente Historien/Logs grundsätzlich minimal-scoped speichern (nur was für den
   Zweck nötig ist), nie "der ganze Request/State" — Secrets landen fast immer in
   Headern/Bodies, nicht in Methode/URL/Status.
2. Platzhalter-Resolution (Variablen, Secrets, Tokens) immer erst unmittelbar vor dem
   externen Aufruf ausführen und alle Log-/History-/UI-Pfade an der rohen, unresolved
   Kopie festhalten lassen.
3. Bei jeder Fast-Event-Context-API (Timer-Callbacks, `vim.uv`-Callbacks, curl-Callbacks)
   zentral einmal durch `vim.schedule` wrappen statt es jedem Aufrufer zu überlassen.
4. `vim.json.encode`'s `indent`-Option nicht blind vertrauen — gegen echtes Verhalten der
   verwendeten Neovim-Version testen, bevor man sich auf Formatierungs-Feature verlässt.
5. Cache-/Dateinamen aus Pfaden (Projekt-Root, Buffer-Namen) immer durch eine
   Whitelist-Sanitize-Funktion schicken, bevor sie Teil eines Dateipfads werden
   (Windows-Laufwerksbuchstaben/Doppelpunkte sind ein realer Stolperstein).
6. "Cancel" bei nicht wirklich abbrechbaren Async-Operationen (kein Handle zum Killen)
   als Token-basiertes logisches Discard implementieren, nicht vortäuschen, der Prozess
   sei gestoppt.
7. Bei zusammengesetzten Ex-Commands (`:RA <verb>`) sowohl bewusst benannte Sub-Args
   registrieren (`RA_ENV_NAME`, `RA_LOADED_MODULE`) mit live-lesender `complete`-Funktion,
   die den aktuellen Zustand (nicht den Zustand von `setup()`-Zeit) widerspiegelt.
8. Argument-/Daten-Profiling in Telemetrie-artigen Features strikt auf Shape statt
   Inhalt beschränken (Länge/Typ/Count), nie Rohwerte persistieren.
9. Count-basierte Caps für kleine, häufige Einträge sind einfacher und genauso wirksam
   wie zeitbasierte Caps — nicht automatisch zur komplexeren Lösung greifen.

## Keybindings-Audit

Keine eigenen Keymaps — laut README.md:122-123 und `bindings/usrcmds.lua:45-50`
bewusste Design-Entscheidung: "every entry point is a command... a request buffer's
own edits are what drive this plugin, not a keybinding." Alle Einstiegspunkte laufen
über `:RA <verb>` (Ex-Commands via `lib.nvim.usercmd.composer`).

Ex-Command-Autocompletion-Bewertung:
- `:RA env [name]` — `<Tab>`-Completion vorhanden, live gegen `env.list_names()`
  (`bindings/usrcmds.lua:60-70`). Gut.
- `:RA inspect <module>` — `<Tab>`-Completion vorhanden, live gegen `package.loaded`
  (`bindings/usrcmds.lua:76-90`). Gut.
- `:RA provenance <path>` — Typ `STRING`, KEINE Completion (`bindings/usrcmds.lua:766-772`).
  Fehlende Idee: Completion gegen bekannte `vim.*`-APIs oder gegen `package.loaded`-Felder
  wäre möglich, ist aber laut Code nicht trivial (dotted path mit Container+Field-Split).
- `:RA import` unterstützt Range (`'<,'>RA import`) — sinnvoll für Visual-Selection;
  kein `count`-Konzept anwendbar (n.a., da kein wiederholbarer Einzel-Vorgang mit
  Mengen-Semantik, sondern "importiere genau eine curl-Zeile/-Selektion").
- `count` generell: n.a. für alle `:RA`-Subcommands — keins hat eine "N-mal wiederholen"
  Semantik, die von einem vorangestellten count sinnvoll profitieren würde.
- Fehlende Flags/Optionen (Ideen): `:RA history` könnte einen Flag für "nur Fehler"/
  "nur Status >= 400" gebrauchen; `:RA send` könnte ein `!`-Bang für "auch ohne
  gitignore-Warnung senden" bekommen, wenn `warn_if_not_gitignored` irgendwann blockierend
  würde (aktuell ist es nur eine Notify, also kein echter Bedarf).

## Ideen für andere Plugins

- **Generisches Secret-Redaction-Modul** für lib.nvim: eine Funktion, die Header-Namen
  gegen eine bekannte Sensitive-Liste (`Authorization`, `Cookie`, `X-Api-Key`, ...) matcht
  und deren Werte in jeder History/jedem Log automatisch maskiert — verallgemeinert das
  Pattern aus `history.lua`, aktuell hart als "gar nicht speichern" gelöst.
- **Fast-Event-Context-Linter**: ein kleines Statik-Tool/Runtime-Assert, das erkennt, wenn
  eine `nvim_*`-API aus einem nicht-geschedulten Callback (Timer, `vim.uv`, `vim.system`)
  aufgerufen wird, und früh mit einem klaren Hinweis statt `E5560` failt.
  `runtime-analysis.runner.run_async`'s zentrales `vim.schedule` ist der Präzedenzfall.
- **Token-basierte Supersession-Bibliothek**: das Pending-Token-Pattern aus
  `bindings/usrcmds.lua` (neuester Request gewinnt, ältere Callbacks werden No-op) taucht
  vermutlich in jedem Plugin mit überlappenden Async-Requests wieder auf (Picker-Previews,
  LSP-Requests, Search) — lohnt sich als generischer `lib.nvim.async.latest_wins(token)`
  Helper.
