# gopath.nvim

## Zweck
Resolviert Datei-/Import-/Symbol-Referenzen unter dem Cursor (Pfade, Stack-Traces,
truncated paths, Lua `require`, Go/Java/Python/Rust/C-Imports, LSP-Symbole) und öffnet sie
im gewünschten Fenster-Modus. Enthält eine eigene Filesystem-Cache-Schicht für
"truncated"/verkürzte Pfade (z.B. aus abgeschnittenen Log-Ausgaben) und ein
Alternate-File-Switching-Feature. Quelle: docs/README.md, docs/BINDINGS.md,
lua/gopath/truncated/cache.lua, lua/gopath/resolvers/common/tailsearch.lua,
lua/gopath/bindings/keymaps.lua.

## Nicht-standard Patterns / Algorithmen

1. `lua/gopath/truncated/cache.lua:136-199` (`scan_roots_bounded`) — asynchroner
   Filesystem-Scan über mehrere Roots mit einer Arbeits-Queue (`{dir, depth}`-Items) und
   fest begrenzter Nebenläufigkeit (`config.max_concurrency = 16`). Statt sofort rekursiv in
   Unterverzeichnisse zu descend, werden sie zurück in die Queue gelegt und erst verarbeitet,
   wenn ein Concurrency-Slot frei wird (`pump()`). WARUM (explizit im Kommentar): unbegrenzte
   parallele `fs_scandir`-Aufrufe auf großen Verzeichnisbäumen können EMFILE
   (zu viele offene Handles) oder eine Erschöpfung des libuv-Threadpools verursachen — die
   Queue hält die Zahl gleichzeitig offener Handles konstant unabhängig von der Baumgröße.
   Der Read-Cursor (`qhead`) statt `table.remove(queue,1)` vermeidet zusätzlich O(n)
   Element-Shifts bei jeder Queue-Entnahme.

2. `lua/gopath/truncated/cache.lua:33-67` — konservative Auto-Erkennung der Scan-Roots
   (cwd, nvim config/data/cache stdpath, git-root) statt eines ganzen Laufwerks/Home-Verzeichnisses.
   WARUM (explizit im Kommentar): Indexierung eines ganzen Laufwerks bis `max_depth` beim
   Start wäre riesig und langsam; die Default-Roots decken nur Verzeichnisse ab, die
   tatsächlich in diesem Editor geöffnete Dateien enthalten.

3. `lua/gopath/truncated/cache.lua:361-392` — periodischer Hintergrund-Refresh nur, wenn
   `needs_refresh()` UND nicht bereits `state.building` — verhindert überlappende
   Cache-Builds, auch wenn der Timer öfter feuert als der Build dauert.

4. `lua/gopath/resolvers/common/tailsearch.lua:178-197` (`cache_lookup`) — probiert
   Pfad-Suffixe längster-zuerst (`suffix_candidates`, längster zuerst) und bricht beim ersten
   Treffer ab, statt alle Suffixe zu sammeln. WARUM: verhindert, dass ein kurzer, generischer
   Suffix (z.B. nur der Dateiname `c.lua`) einen unspezifischen Treffer liefert, wenn ein
   längerer, spezifischerer Suffix (`b/c.lua`) bereits eindeutig matcht — Präzision vor
   Vollständigkeit.

5. `lua/gopath/resolvers/common/tailsearch.lua:264-296` (`resolve_sync`) — dreistufige
   Fallback-Kaskade: (1) In-Memory-Cache (instant, kein Blocking), (2) `vim.fs.find` pro
   Suffix-Kandidat mit sofortigem Return bei genau einem eindeutigen Treffer ("unambiguous
   hit"), (3) Sammlung aller Treffer über alle Suffixe mit `pick_best` (kürzester = spezifischster
   Pfad) als letzter Ausweg. Jede Stufe liefert eine andere Confidence (0.85 für eindeutig via
   Cache, 0.72 für mehrdeutig). WARUM: die Konfidenzwerte kommunizieren den nachgelagerten
   Aufrufern, wie sicher die Auflösung ist, ohne dass jeder Aufrufer die Heuristik selbst
   kennen muss.

6. `lua/gopath/resolvers/common/tailsearch.lua:307-357` (`resolve_cached` vs.
   `resolve_async`) — bewusste Trennung zwischen einer garantiert nicht-blockierenden
   Cache-only-Variante (sicher synchron innerhalb einer Resolve-Pipeline aufrufbar) und einer
   asynchronen Variante, die bei Cache-Miss auf einen echten (potenziell mehrsekündigen)
   `vim.fs.find`-Walk zurückfällt, mit optionalem `on_live_start`-Callback, der nur feuert,
   wenn der langsame Pfad tatsächlich beginnt (damit UI nur bei Bedarf einen
   Progress-Hinweis zeigt). WARUM (Kommentar explizit): verhindert einen "multi-second
   freeze" im UI-Thread, wenn die Resolve-Pipeline synchron aus einem Keymap-Handler
   aufgerufen wird.

7. `docs/BINDINGS.md:41-64` (Create-on-missing) — wenn ein resolvter Pfad nicht existiert,
   bietet das Plugin einen Dialog zum Anlegen der Datei (inkl. `mkdir -p` für Parent-Dirs)
   an, plus optional "Open in filetree" als Alternative, wenn eine existierende
   Ancestor-Directory gefunden wird und filetree.nvim installiert ist. WARUM: ein
   File-Handle kann eine Datei öffnen, aber kein Verzeichnis — der Dialog gibt dem Nutzer
   eine sinnvolle Handlungsoption statt nur "File not found".

8. `docs/BINDINGS.md:110-127` (Autocommands) — `BufWritePost` invalidiert eine
   Verzeichnislistungs-Cache (`gopath.util.path`), die pro Suchwurzel eine Directory-Listing
   cached, "so that `gF` does not stat the filesystem on every keypress". WARUM: Trade-off
   zwischen Aktualität (Cache kann stale werden, wenn Dateien außerhalb Neovims entstehen)
   und Performance (kein Filesystem-Stat bei jedem Tastendruck) — Invalidierung bei
   `BufWritePost` deckt den häufigsten Fall ab (neue Datei entsteht durch Speichern in
   Neovim), ohne bei jedem Keypress zu prüfen.

## Abgeleitete Guidelines

1. Asynchrone Filesystem-Scans über potenziell große Bäume immer mit einer
   Work-Queue + fester Concurrency-Obergrenze implementieren (nicht naiv rekursiv parallel),
   um EMFILE/Threadpool-Erschöpfung zu vermeiden.
2. Queue-Verarbeitung mit Read-Cursor statt `table.remove(t,1)` implementieren, wenn die
   Queue groß werden kann — vermeidet O(n) Shifts pro Dequeue.
3. Auto-erkannte Scan-/Root-Verzeichnisse konservativ wählen (Projekt-relevante Pfade),
   nie pauschal ganze Laufwerke/Home — explizite Opt-in-Erweiterung für mehr.
4. Hintergrund-Rebuild-Timer immer gegen einen `building`-Flag absichern, damit sich
   überlappende Builds nicht gegenseitig stören.
5. Bei mehrdeutigen Fuzzy-/Suffix-Matches: spezifischere (längere) Kandidaten zuerst
   probieren und bei einem eindeutigen Treffer sofort abbrechen, statt immer alle
   Kandidaten zu sammeln.
6. Resolve-Pipelines, die aus synchronen Kontexten (Keymap-Handler) aufgerufen werden,
   brauchen eine explizite "cache-only, garantiert non-blocking"-Variante getrennt von der
   vollen asynchronen Variante mit Live-Filesystem-Fallback — Kommentar/Contract im Code
   festhalten, welche Variante wo sicher ist.
7. Zeitaufwendigen Fallback-Pfaden (Live-Suche) einen optionalen "started"-Callback geben,
   damit UI-Feedback (Progress-Meldung) nur erscheint, wenn er wirklich gebraucht wird.
8. Konfidenzwerte/Scores bei mehrstufigen Resolve-Strategien mitliefern, statt nur ein
   Ergebnis zurückzugeben — Aufrufer können dann selbst entscheiden, ob sie bei niedriger
   Konfidenz nachfragen (vim.ui.select) oder blind übernehmen.
9. Wenn ein resolvter Pfad nicht existiert, dem Nutzer eine aktive Handlungsoption geben
   (Datei anlegen inkl. Parent-Dirs, oder Alternative anbieten) statt nur einen Fehler zu
   werfen.
10. Verzeichnislistungs-Caches an die Events koppeln, die typischerweise neue Dateien
    erzeugen (`BufWritePost`), statt bei jedem Zugriff zu stat'en.
11. Jeder Keymap-Actionname sollte einzeln per Config-Key deaktivierbar sein (`false`) und
    zusätzlich einen globalen Master-Switch (`mappings = false`) haben; lhs darf ein
    einzelner String oder eine Liste von Strings sein (mehrere Bindings pro Aktion).

## Keybindings-Audit
Aus docs/BINDINGS.md und lua/gopath/bindings/keymaps.lua:

- `gP` open_here, `g\|` open_split, `g\` open_vsplit, `g}` open_tab, `gY` copy_location,
  `g?` debug, `gC` check:
  - count: n.a. — alle wirken auf "den Pfad unter dem Cursor", ein count hat hier keine
    natürliche Bedeutung (nicht wie Motions).
  - Autocompletion: n.a. für die Keymaps selbst (kein Argument-Prompt). Für das
    Ex-Command-Pendant `:Gopath open [edit|split|vsplit|tab]` ist laut BINDINGS.md
    Tab-Completion vorhanden ("tab-completion works at every level" über
    `lib.nvim.usercmd.composer`).
  - Fehlende Flags: keine ersichtlich.

- `<leader>pp` (n+v) probe: Suffix-Suche unter Cursor/Selektion.
  - count: n.a. — Suchoperation, kein Wiederholungskonzept.
  - Autocompletion: bei Mehrdeutigkeit öffnet `vim.ui.select`/`lib.nvim.ui.kit.select` einen
    Picker mit allen Treffern (`finish()` in tailsearch.lua) — funktional äquivalent zu
    Autocompletion für den unklaren Fall. Gut gelöst.
  - Fehlende Flags: keine ersichtlich.

- `:GopathProbe[!]` — Bang-Modifier (`!` = split) als kompakte Variante statt eines
  Arguments; interessantes, wenig verbreitetes Muster für binäre Modus-Wahl.

- `:Gopath cache add-root <dir>`:
  - Autocompletion: nicht dokumentiert in BINDINGS.md, ob `<dir>` File-Completion hat;
    nicht verifiziert (Registrierung liegt in `bindings/usrcmds.lua`, nicht im Detail
    gelesen) — offene Frage/potenzielle Lücke, falls keine Pfad-Completion vorhanden ist.

- Visual-mode `probe`: Mapping feedet zuerst `<Esc>` (um `'<`/`'>`-Marks zu setzen), dann
  `vim.schedule`, bevor `commands.probe_selection(..., selection=true)` aufgerufen wird —
  ein spezifisches, dokumentiertes Workaround-Pattern für Visual-Mode-Handling (siehe
  Kommentar in keymaps.lua Zeile 108-112), kein Bug.

## Ideen für andere Plugins
1. Ein generisches "Bounded-Concurrency Filesystem Scanner"-Modul in lib.nvim, das das
   Work-Queue-Pattern aus `truncated/cache.lua:scan_roots_bounded` kapselt — direkt
   wiederverwendbar für jedes Plugin, das große Verzeichnisbäume async indizieren muss
   (z.B. images.nvim's scan.lua/orphans.lua könnten das brauchen, falls sie ähnliches tun).
2. Ein generisches "Cache-only vs. Live-Fallback Resolve"-Interface (`resolve_cached` /
   `resolve_async` / `resolve_sync` als benanntes Trio) als Konvention für alle
   Resolver-artigen Module in lib.nvim, mit einheitlicher Confidence-Score-Konvention.
3. Ein eigenständiges kleines Plugin/Modul "create-on-missing dialog" (Datei anlegen +
   Parent-Dirs + optional Alternative wie "open in filetree") als generisches lib.nvim-Utility,
   das jedes datei-öffnende Plugin (auch images.nvim beim Einfügen von Pfaden) nutzen könnte.
