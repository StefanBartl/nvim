# debugging.nvim

## Zweck
`debugging.nvim` bündelt Neovim-Debugging-Werkzeuge hinter einem einzigen `:Debug {category} {action}`
Befehl: Message-/Noice-Views, Buffer/Tab/Window-Reports, Autocmd-Inspektion (Live-View, statischer
Tree-sitter-Quellcode-Audit und ein fusionierter sources-vs-runtime View), Buffer/Window/Tab/Cursor/
Variablen-Inspektion, ein Terminal-Keylogger, Indent-Diagnose, Markdown-Inline-Highlight-Debugging,
UI-Freeze-Diagnose (Blocking-Call-Tracing + externer Prozessbaum-Watcher unter Windows), ein
Startup-Zeit-Benchmark und eine opt-in Neo-Tree-Safety-Bridge. Läuft komplett über `lib.nvim` als
deklarierte, absichtliche Abhängigkeit (`lua/debugging/init.lua:10`, README.md:38).

## Nicht-standard Patterns / Algorithmen

1. **Zwei-stufiger Autocmd-Scanner mit Tree-sitter + Text-Fallback** (`lua/debugging/autocmds/sources.lua:146-275`).
   Statt eines rein regex-basierten Parsers für `nvim_create_autocmd`-Aufrufe wird zuerst per
   `vim.treesitter.get_string_parser(..., "lua")` + Query auf `function_call`-Knoten gesucht
   (`scan_file_ts`, Zeile 187). Fällt der Lua-Parser nicht bereit (kein Treesitter installiert),
   greift ein handgeschriebener Brace-Counter-Textparser (`scan_file_text` + `read_brace_block`,
   Zeile 123-144, 238-261). Grund: der reine Textparser scheitert an mehrzeiligen/verschachtelten
   `nvim_create_autocmd({...})`-Aufrufen (Klammer-Tiefe), was laut Kommentar (Zeile 9-12) der
   ursprüngliche Auslöser für den Tree-sitter-Pfad war.

2. **Per-Root-Memoisierung des gesamten Scan-Pipeline-Ergebnisses, nicht nur des Directory-Walks**
   (`lua/debugging/autocmds/sources.lua:94-98, 328-350`). `scan_cache` wickelt Walk+Parse komplett
   in einen `lib.nvim.cache.memory`-Namespace mit TTL 5s. Kommentar erklärt explizit: das *Parsen*
   ist teuer, nicht nur der Verzeichnis-Walk — daher wird die komplette Pipeline gecached statt nur
   `collect_recursive`. `refresh=true` umgeht den Cache gezielt.

3. **Bewusst kein `lib.nvim.autocmd.group()` für den eigenen Augroup** (`lua/debugging/bindings/autocmds.lua:1-13`,
   `docs/architecture.md:57-60`). Der Augroup wird direkt via `nvim_create_augroup(name, {clear=true})`
   erzeugt statt über den Shared-Helper, weil dieser Gruppen nach Namen cached und den `clear` bei
   Wiederholtem Aufruf überspringt — das würde bei jedem `setup()`-Re-Run doppelte Autocmds
   akkumulieren. Bewusste Abweichung vom "immer die lib-Utility nutzen"-Standard zugunsten von
   Idempotenz beim Config-Reload.

4. **Fenster-Identifikation über Window-Var statt Registry** (`lua/debugging/views/display.lua:1-9`).
   Offene Debug-View-Fenster werden nicht in einer modul-lokalen Tabelle getrackt, sondern über
   `window_tag.find(tag)`/`.get(win)` (eine Window-Variable) gesucht. Kommentar: eine stale Registry
   war früher genau die Ursache dafür, dass `clear_all()` offene Fenster übersah — die
   Tag-basierte Lookup-Strategie eliminiert diese Fehlerklasse strukturell statt sie zu patchen.

5. **`parse_id` unterscheidet "kein Argument" von "ungültiges Argument"** (`lua/debugging/commands.lua:24-43`).
   Ein subtiler Bugfix, im Kommentar dokumentiert: früher fiel ein Tippfehler wie
   `:Debug report win abc` durch dieselbe `nil`-Rückgabe wie "kein Argument" und meldete dadurch
   fälschlich *alle* Fenster statt eines Fehlers. Die Funktion gibt jetzt `nil, false` für ungültige
   und `nil, true` für fehlende Argumente zurück, sodass Aufrufer explizit unterscheiden können.

6. **Startup-Benchmark spawnt echten Headless-Subprozess statt In-Process-Messung**
   (`lua/debugging/tools/startup.lua:61-83`). `--startuptime` wird über `vim.fn.system()` in einer
   frischen `nvim --headless`-Instanz mit der realen Config gemessen, das Log geparst und
   gelöscht. Grund: eine In-Process-Messung könnte durch bereits geladene Module/Caches der
   laufenden Session verfälscht sein; der Subprozess-Ansatz misst einen echten Kaltstart und hat
   keinen Nebeneffekt auf die aktuelle Session.

7. **Command-Injection-Fix historisch in lib.nvim hochgezogen** (`lua/debugging/views/capture/clipboard/init.lua:6-13`).
   Kommentar dokumentiert offen: die eigene, plattformspezifische Clipboard-Fallback-Kette hatte
   einen Command-Injection-Bug im Linux-Fallback (Shell-String direkt durch Konkatenation des
   Clipboard-Texts gebaut). Der Fix wurde nach `lib.nvim.cross.copy_to_clipboard` hochgezogen statt
   lokal gepatcht — bewusste Entscheidung, sicherheitsrelevante Fixes im Shared-Modul zu
   zentralisieren statt in einer privaten Kopie zu belassen.

8. **`proc_trace`-Timing-Hinweis zu `local`-Referenzen** (`lua/debugging/tools/proc_trace.lua:11-17`).
   Dokumentierte Limitation: `proc_trace` sieht nur Aufrufe über exakt die API-Tabellen, die es
   wrapped — ein Plugin, das vorher `local system = vim.fn.system` referenziert hat, umgeht das
   Tracing. Empfehlung im Code: so früh wie möglich starten (idealerweise erste Zeile in
   `init.lua`). Kein Code-Pattern im engeren Sinn, aber eine bewusst dokumentierte Grenze eines
   Monkey-Patching-Ansatzes.

9. **Terminal-Keylogger mit rekursivem `vim.schedule`-Loop statt Autocmd** (`lua/debugging/terminals/keylogger.lua:63-97`).
   Tastenerfassung läuft über eine rekursive Kette aus `vim.fn.getcharstr()` (blockierend) +
   `vim.schedule`, nicht über ein `TermEnter`/Keymap-basiertes Muster. Bei jedem Tastendruck wird
   geprüft, ob der aktuelle Buffer noch der Terminal-Buffer ist (`buftype ~= "terminal"`) — verlässt
   der Nutzer den Terminal-Buffer während des Loggens, würde die Rekursionskette sonst still
   sterben und `M.logging` bliebe fälschlich auf `true` hängen; das wird durch einen expliziten
   `M.stop("left the terminal buffer")`-Call abgefangen (Zeile 74-80).

10. **`config/init.lua` mutiert nie `DEFAULTS`** (`lua/debugging/config/init.lua:18-33`). Jeder
    `setup()`-Call arbeitet auf `vim.deepcopy(DEFAULTS)` und merged via `vim.tbl_deep_extend("force", …)`.
    Kein besonders exotisches Pattern, aber konsequent durchgehalten — `DEFAULTS.lua` selbst trägt
    den Kommentar "Single source of truth … never mutated at runtime" (`config/DEFAULTS.lua:4`).

Insgesamt: keine besonders exotischen Datenstrukturen oder Algorithmen jenseits des
Tree-sitter/Text-Dual-Path-Parsers (Punkt 1) — die meisten "besonderen" Stellen sind defensive
Fixes für konkret erlebte Bugs (stale Registry, Command-Injection, Rekursions-Leck), nicht
Performance-Optimierungen im eigentlichen Sinn (außer dem Scan-Cache, Punkt 2).

## Abgeleitete Guidelines

1. **Ein zentraler Dispatcher, dünne Leaf-Module.** `commands.lua` besitzt die komplette
   Category→Action-Registry inkl. Feature-Gating; `bindings/usercmds.lua` registriert nur den
   einen `nvim_create_user_command` und baut daraus eine Completion-Route-Tree. Leaf-Module
   (`actions/*`, `tools/*`, `views/*`) exponieren reine Funktionen ohne eigene Command-Registrierung
   (`docs/architecture.md:48-49`). Für neue Plugins: **genau eine Stelle**, die User-Commands
   registriert; Logik bleibt in aufrufbaren, testbaren Funktionen.

2. **Feature-Flags als einzige Gating-Quelle, mit generischem statt spezifischem Fehler bei
   deaktivierten Kategorien in der Completion.** `config.features.*` steuert, was in `<Tab>`-Completion
   auftaucht UND was `dispatch()` überhaupt akzeptiert (`commands.lua:307-315`, `config/DEFAULTS.lua:10-22`).
   Ein deaktiviertes Feature ist unsichtbar in der Completion, aber bei explizitem Tippen bekommt
   der Nutzer eine klare Meldung ("category %q is disabled (enable features.%s)"), keinen stillen
   No-op. Abweichungen (z.B. composer-Pfad) werden im Code offen als Tradeoff dokumentiert
   (`bindings/usercmds.lua:18-26`).

3. **Injectable statt hartcodierte Integration für nutzerspezifische/private Module.** Die
   Neo-Tree-Bridge (`actions/neotree_safety.lua`) verlangt keine feste Modul-Struktur, sondern
   nimmt Modulnamen-Strings ODER bereits geladene Tabellen aus der Config entgegen
   (`config/DEFAULTS.lua:34-41`) und degradiert bei fehlendem Ziel mit einer klaren Notify statt
   einem Error. Guideline: private/Config-spezifische Integrationen NIE hart verdrahten, sondern
   injizierbar machen — das Plugin bleibt so auch ohne die private Config lauffähig.

4. **`pcall` um jeden `require` eines optionalen/fremden Moduls, kombiniert mit klarer
   Fehlermeldung.** Durchgängiges Muster in `health.lua` (`check_require`), `neotree_safety.lua`
   (`need()`), `proc_trace.lua` (jede Funktion pcallt `require("lib.nvim.system.proc_trace")`),
   `which_key.lua` (`pcall(require, "which-key")`). Guideline: jeder Soft-Dependency-Zugriff läuft
   über `pcall` + eigene Notify-Kategorie (info/warn/error je nach Kritikalität), nie über einen
   ungeschützten `require`, der beim Fehlen die ganze Chain crasht.

5. **`:checkhealth` deckt wirklich jede externe Abhängigkeit ab, nicht nur "installiert ja/nein".**
   `health.lua` prüft pro Feature-Kategorie sowohl die lib.nvim-Submodule als auch externe Programme
   (Clipboard-Provider, PowerShell/pwsh auf Windows, Tree-sitter, Noice, which-key) und
   Schreibrechte im State-Dir. Guideline: Health-Check sollte 1:1 die Menge der optionalen
   Abhängigkeiten abbilden, die im Code tatsächlich per `pcall(require, …)` referenziert werden —
   sonst driften Code und Health-Check auseinander.

6. **Konfig-Merge deep-copy + `tbl_deep_extend("force", …)`, nie Mutation der Defaults.**
   `config/init.lua:23` — Standardmuster, das für jedes Plugin mit `setup(opts)` übernommen werden
   sollte, inklusive des expliziten Kommentars "Single source of truth … never mutated at runtime"
   in `DEFAULTS.lua`.

7. **Dispatch-Funktionen geben Status zurück statt selbst zu notifien, wenn es mehrere Call-Sites
   gibt.** `views/capture/init.lua:capture_messages()` gibt `ok, content, detail` zurück und notifiziert
   NICHT selbst — der Kommentar erklärt das explizit: die zwei Call-Sites (Dispatcher-Action und
   Keymap) entscheiden selbst, wie sie das Ergebnis präsentieren (`capture/init.lua:321-328`).
   Guideline: Funktionen, die von mehreren UI-Einstiegspunkten aus aufgerufen werden, sollten
   Status zurückgeben statt selbst zu notifizieren — Notify gehört an die "Blätter" der Aufruferkette.

8. **Docs sind maschinenlesbar synchron zum Code zu halten, mit explizitem Verweis auf die
   Source-of-Truth-Datei.** `docs/BINDINGS.md:1-11` verlinkt jede Tabelle direkt auf die
   Quelldatei ("keymaps — lua/debugging/bindings/keymaps.lua") und vermerkt "Any change there must
   be reflected here." Guideline: Cheatsheet-Dokus sollten den Sourcepfad je Abschnitt nennen, damit
   Drift bei Refactorings auffällt.

9. **Defensive Handle-Validierung vor jedem API-Zugriff in Deferred-Callbacks.**
   `views/utils.lua` prüft vor JEDER `nvim_win_*`/`nvim_buf_*`-Operation explizit
   `nvim_win_is_valid`/`nvim_buf_is_valid` und gibt `false`/früh zurück statt zu werfen — mit dem
   Kommentar, dass Callbacks aus `vim.defer_fn` laufen, wo das Handle in der Zwischenzeit sterben
   kann (Zeile 10-12). Guideline: alles, was über `vim.defer_fn`/`vim.schedule` verzögert läuft,
   MUSS seine Fenster-/Buffer-Handles am Ausführungszeitpunkt neu validieren, nicht nur beim
   Erfassen des Callbacks.

10. **Kategorien/Actions als geordnete Tabellen mit `actions`-Array**, nicht nur als `run`-Map
    (`commands.lua:52-65` etc.) — das `actions`-Array bestimmt sowohl Completion-Reihenfolge als
    auch die Overview-Anzeige (`:Debug` ohne Argumente). Guideline: bei mehreren Sub-Aktionen pro
    Kategorie Reihenfolge explizit als Array pflegen statt sich auf `pairs()`-Iterationsreihenfolge
    einer Map zu verlassen (in Lua nicht deterministisch).

## Keybindings-Audit

Eigene Keymaps kommen ausschließlich aus dem Views-Subsystem (`lua/debugging/bindings/keymaps.lua`),
gated durch `config.views.keymaps.enable`, Standard-Prefix `<lt>` (das literale `<`-Zeichen). Der
`:Debug`-Befehl selbst ist kein Keymap, sondern ein Ex-Command.

| lhs | mode | Zweck | count sinnvoll? | Autocompletion nötig? | Fehlende Flags (Ideen) |
|---|---|---|---|---|---|
| `<lt>m` | n | `:messages`-View öffnen/refreshen | Nein — Toggle-artige Aktion, kein Bereichsziel; `count` hätte keine sinnvolle Semantik | n/a (kein Ex-Command-Input) | — |
| `<lt>n` | n | Noice-all-View | Nein, aus demselben Grund | n/a | — |
| `<lt>e` | n | `:Noice errors` | Nein | n/a | — |
| `<lt>c` | n | Capture `:messages` → Datei+Clipboard | Nein | n/a | Kein Flag, um nur Datei ODER nur Clipboard über das Keymap zu wählen (nur über `:Debug messages capture` mit Lua-API-Call möglich, nicht über das Keymap selbst) |
| `<lt>x` | n | Alle Debug-Fenster schließen | Nein | n/a | — |

Für den `:Debug`-Ex-Command selbst (kein Keymap, aber Completion-relevant):
- **Autocompletion ist vorhanden und mehrstufig** über `lib.nvim.usercmd.composer`
  (`commands.lua:M.complete`, `bindings/usercmds.lua`): Kategorie → Aktion → freie `key=value`-Argumente
  für `autocmds sources`/`all` (`event=`, `sort=`, `impl=`, `summary=`, `freq=`, `root=`, `refresh=`,
  `qf=`), inkl. dynamischer `event=Buf<Tab>`-Vervollständigung gegen bekannte Event-Namen. Das ist
  vorbildlich vollständig — Pflicht-Einschätzung: **ja, für jeden Ex-Command mit mehr als einer
  Handvoll Subcommands/Argumenten sollte kontextsensitive Completion wie hier Standard sein.**
- Auffallend fehlend: `:Debug report win <id>` / `:Debug inspect buffer|window <id>` bieten KEINE
  Completion für die ID selbst (z.B. Liste offener Fenster-IDs) — laut Kommentar in
  `bindings/usercmds.lua:78-84` bewusst so belassen ("matches the original, which also offered
  nothing past the first arg"), aber als Verbesserungsidee festgehalten.
- `:Debug keylogger start [path]` bietet keine Datei-Pfad-Completion (z.B. `getcompletion(..., "file")`).

**Fazit Keybindings:** Alle fünf Keymaps sind reine Ein-Zweck-Toggles ohne Bereichsargument — `count`
ist hier durchgängig nicht anwendbar, das ist korrekt so und keine Lücke. Die eigentliche
Konfigurationsfläche (Kategorie/Aktion/Argumente) läuft komplett über den Ex-Command, dort ist
Completion vorbildlich implementiert, mit zwei benannten Lücken bei ID-/Pfad-Completion.

## Ideen für andere Plugins

1. **Eigenständiges "Static-vs-Runtime-Audit"-Framework**: Das Muster aus `autocmds/sources.lua`
   (Tree-sitter-Scan von API-Call-Sites im Quellcode + Live-API-Abfrage + Diff/Fusion beider Sichten,
   siehe `M.all()`) ist generisch genug für andere Neovim-APIs mit Registrierungs-Charakter —
   z.B. `nvim_create_user_command`-Aufrufe, `vim.keymap.set`-Aufrufe, oder `vim.diagnostic`-Handler.
   Ein generisches "wo im Quellcode wird X registriert, und was ist zur Laufzeit tatsächlich aktiv"
   -Werkzeug (config/keymap-audit.nvim?) könnte den Scanner aus `sources.lua` als Kern
   wiederverwenden statt ihn zu duplizieren.

2. **Standalone "Proc-Watch"-Plugin für Windows**: `tools/proc_trace.lua` + das gebündelte
   `scripts/watch-nvim-procs.ps1` sind bereits fast eigenständig — ein separates, sehr kleines
   Plugin, das ausschließlich UI-Freeze-Diagnose (Blocking-Call-Tracing + externer Prozessbaum-Watcher)
   anbietet, könnte in andere Configs eingebunden werden, ohne den Rest von debugging.nvim
   mitzuziehen (Stichwort: der User hat bereits mehrere kleine, fokussierte Plugins statt Monolithen).

3. **Reusable "Tagged-Scratch-Window"-Modul**: Das Tag-basierte Fenster-Tracking aus
   `views/display.lua`/`views/utils.lua` (Fenster über eine Window-Var statt Registry finden,
   Fokus-und-Scroll-zu-Ende mit begrenzten Retries, defensive Handle-Validierung überall) ist ein
   generisches "Singleton-Log-Fenster"-Pattern, das in jedem Plugin auftaucht, das ein
   auto-refreshendes Log-Fenster braucht (z.B. LSP-Log-Viewer, Test-Runner-Output). Lohnt sich als
   eigenes `lib.nvim`-Modul, falls es das nicht schon gibt (aktuell scheint nur `window.tag`,
   `window.make_scratch` in lib.nvim zu existieren, nicht das volle Refresh/Focus-Verhalten).

4. **Konfigurierbarer Command-Registry-Composer als eigenständiges lib.nvim-Pattern**: Der Split
   zwischen `commands.lua` (Logik/Registry/Dispatch) und `bindings/usercmds.lua` (reine
   Composer-Route-Registrierung) ist ein sauberes, wiederverwendbares Muster für jedes Plugin mit
   einem einzigen Dach-Command über viele Unterbefehle (ähnlich `:Git`, `:Telescope`). Könnte als
   Vorlage/Doku-Snippet für zukünftige "ein Command, viele Subcommands"-Plugins dienen.

5. **Keylogger-Pattern als eigenständiges Lern-/Debug-Werkzeug**: Der rekursive
   `getcharstr`+`vim.schedule`-Loop mit Buftype-Ausstiegsprüfung (`terminals/keylogger.lua`) ließe
   sich verallgemeinern zu einem generischen "Input-Recorder" — z.B. für Macro-Aufzeichnung mit
   Zeitstempeln (nicht nur Terminal-Buffer), falls für andere geplante Plugins (z.B. etwas in
   Richtung Vim-Macro-Tooling) relevant.
