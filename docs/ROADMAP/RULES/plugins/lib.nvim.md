# lib.nvim

## Zweck
`lib.nvim` ist Stefan Bartls geteilte Standardbibliothek für seine eigenen Neovim-Plugins
(`E:\repos\lib.nvim\README.md:21-25`). Sie hat keine Drittanbieter-Abhängigkeiten, nur `vim`
und sich selbst, und ist strikt in drei Namespaces gegliedert: `lib.lua.*` (editor-unabhängige
Lua-Helfer), `lib.nvim.*` (Neovim-API-Adapter) und `lib.vim.*` (klassische-Vim-kompatible
Spiegelung von `lib.nvim.*`, siehe `E:\repos\lib.nvim\docs\architecture.md:3-11`). Sie bündelt
u.a. Diffing, Memoization/LRU, Debounce, Caching (Memory + Disk), Dateisystem-Utilities mit
Windows-Sharing-Retry, User-Command-Composer mit Auto-Completion, UI-Kit-Primitiven, Dependency-
Management und Logging — der "Werkzeugkasten", den insights.nvim, language.nvim und
learn-cli.nvim alle als Pflicht-Dependency einbinden.

## Nicht-standard Patterns / Algorithmen

- `E:\repos\lib.nvim\lua\lib\lua\diff\myers.lua:1-77` — Line-Diff über klassische O(n·m)-DP-LCS-
  Tabelle + Backtracking statt des eigentlich benannten Myers-O(ND)-Algorithmus. Bewusste
  Abweichung: laut Kommentar ist die DP-Variante "simpler to get right and perfectly adequate
  for typical buffer/line-array sizes" — Korrektheit vor asymptotischer Eleganz, wenn n/m klein
  bleiben (Puffergrößen, nicht Repo-große Diffs).
- `E:\repos\lib.nvim\lua\lib\lua\memo\lru.lua:1-113` — klassische O(1)-LRU via Hashmap +
  doppelt verkettete Liste, sauber von Grund auf implementiert (kein Vendoring einer Fremdbib).
- `E:\repos\lib.nvim\lua\lib\nvim\cross\fs\mutate\init.lua:1-99` — Datei-Mutationen (delete/
  copy/rename/mkdir) laufen über `M.retry` mit Backoff `50ms · 2^(attempt-1)`, aber **nur unter
  Windows** (`attempts = is_windows() and 3 or 1`, Zeile 54). Grund: Windows liefert für einen
  kurzzeitig durch Such-Indexer/AV/OneDrive geöffneten Handle `EPERM`/`EACCES`/`EBUSY`, obwohl
  die Datei Millisekunden später problemlos löschbar ist; unter POSIX bedeuten dieselben Codes
  tatsächlich "nicht möglich", Retry würde dort nur Zeit verschwenden. Zusätzlich bewusst
  `vim.wait` statt `uv.sleep` (Zeile 64-65) — nur `vim.wait` hält den Event-Loop am Laufen,
  wodurch pending libuv-Handle-Close-Callbacks tatsächlich abschließen und den blockierenden
  Handle freigeben können.
- `E:\repos\lib.nvim\lua\lib\nvim\cross\fs\lock\init.lua:1-240` — diagnostiziert, welcher
  Windows-Prozess eine Datei blockiert, über die Windows Restart Manager API (`rstrtmgr.dll`)
  via dynamisch kompiliertem C#-Shim (`Add-Type`) in einem PowerShell-Unterprozess. Das PowerShell-
  Skript wird als Datei statt Inline-`-Command`-String übergeben (Zeile 28-30: "full of quotes
  that would otherwise need escaping through two layers"). `M.probe` (Zeile 122-152) testet den
  Lock live via echtem Rename-Versuch (nicht Öffnen) und macht ihn sofort rückgängig — bewusst
  gewählt, weil ein reiner Lese-Lock ein Rename nie bräche, ein "Open"-Test also False Positives
  produzieren würde; ein fehlgeschlagenes Rückgängigmachen wird explizit als eigener Fehlerfall
  behandelt (Zeile 141-150), um die Datei nicht dauerhaft unter dem Probe-Namen liegen zu lassen.
- `E:\repos\lib.nvim\lua\lib\nvim\cache\memory.lua:1-278` — In-Memory-Cache-Namespaces mit TTL
  UND optionaler `changedtick`-Validierung pro Buffer (Zeile 93-100): ein Eintrag gilt als
  ungültig, sobald sich der gebundene Puffer geändert hat, unabhängig vom TTL. Backing-Store ist
  `setmetatable({}, {__mode = "k"})` (Zeile 46, 61) — schwache Keys, damit ein Namespace, dessen
  Aufrufer die Referenz fallen lässt, vom GC eingesammelt werden kann. `clear()` leert die Tabelle
  in-place statt sie zu ersetzen (Zeile 121-133) — explizit kommentiert: ein Tabellenaustausch
  wäre nur über diese eine Closure sichtbar und würde andere Aufrufer derselben Namespace-Kennung
  (inkl. der Auto-Invalidation-Sweep) still auf einen veralteten Stand einfrieren.
- `E:\repos\lib.nvim\lua\lib\nvim\debounce\init.lua:1-106` — generisches Debounce-Primitiv über
  `vim.uv`-Timer; Callback läuft immer `vim.schedule`-gewrappt, weil libuv-Timer-Callbacks
  außerhalb des Main-Loops laufen und direkte `vim.api.*`-Zugriffe dort unsicher sind (Zeile 7-8).
  `M.new_with_counter` (Zeile 73-103) zählt zusätzlich überschriebene/verworfene Calls für
  "N updates coalesced"-UI-Feedback — laut Kommentar aus reposcope.nvim hochgezogen.
- `E:\repos\lib.nvim\lua\lib\nvim\usercmd\composer\complete.lua:1-132` — Tab-Completion wird
  vollständig aus dem Route-Baum abgeleitet statt pro Kommando hand-geschrieben zu werden: an
  jedem Knoten werden entweder die Subcommand-Literale oder — sobald diese erschöpft sind — der
  Completer des aktuellen Positionsarguments angeboten. Ein neuer Route/Argtyp erweitert `<Tab>`
  automatisch, ohne dass ein Plugin-Autor eine eigene `complete`-Funktion schreiben muss.
- `E:\repos\lib.nvim\lua\lib\nvim\fs\scan_cached\init.lua:1-61` — Re-Namespacing des Memory-Caches
  bei jedem Aufruf statt Modul-weitem Memoize (Zeile 41-44), explizit damit unterschiedliche
  Aufrufer denselben Scan-Cache mit unterschiedlichen TTLs nutzen können, ohne dass ein Aufrufer
  die TTL für alle anderen stillschweigend bestimmt.

## Abgeleitete Guidelines

1. Bibliotheks-Code strikt nach "braucht `vim`-API oder nicht" trennen (`lib.lua.*` vs.
   `lib.nvim.*`) — macht die generischen Teile unabhängig testbar und potenziell auslagerbar.
2. Plattformabhängige Fehlerbehandlung (z.B. Retry-Strategien) an der tatsächlichen Fehlerquelle
   festmachen (Windows-Sharing-Violations), nicht pauschal überall Retries einbauen — auf POSIX
   ist ein Retry hier nachweislich sinnlos.
3. Bei Timer-/Async-Callbacks aus `vim.uv` immer `vim.schedule` wrappen, bevor `vim.api.*`
   berührt wird.
4. In-Memory-Caches mit `__mode = "k"` (schwache Keys) bauen, wenn Aufrufer-Referenzen die
   Lebensdauer bestimmen sollen — verhindert Leaks durch vergessene Cache-Namespaces.
5. Cache-`clear()`/Reset-Operationen immer in-place durchführen, wenn mehrere Aufrufer dieselbe
   Referenz teilen könnten — ein Tabellenaustausch bricht stillschweigend jede andere Referenz.
6. Completion-Logik aus einer deklarativen Route-/Schema-Struktur ableiten statt pro Kommando
   von Hand zu pflegen — ein neues Kommando bekommt Tab-Completion "gratis".
7. Bei riskanten Operationen (Datei umbenennen zum Lock-Test) den Rückgängig-Fehlerfall separat
   behandeln und laut melden, statt die Datei in einem unklaren Zwischenzustand zurückzulassen.
8. Reine, seiteneffektfreie Kernfunktionen (z.B. `build_dot` in insights.nvim, hier analog
   `M.diff`) von I/O-Aufrufern trennen, damit sie ohne Neovim-Instanz testbar sind.

## Keybindings-Audit
Keine eigenen Keymaps — lib.nvim ist eine reine Bibliothek ohne UI-Bindings. Es stellt aber
`lib.nvim.usercmd.composer` bereit, über das andere Plugins ihre `:Verb`-Kommandos inkl.
Auto-Completion registrieren (siehe `docs/ROADMAP/RULES/plugins/insights.nvim.md` und
`language.nvim.md` für die Verwendung). Die Composer-Completion (`complete.lua`) unterstützt
sowohl Subcommand-Literale als auch typisierte Positional-Args und `--flag`/`key=value`-Syntax
vollautomatisch — das ist selbst die generische Infrastruktur für "Pflicht-Einschätzung:
Autocompletion vorhanden" bei den anderen Plugins.

## Ideen für andere Plugins
- Ein generisches "Windows file-lock diagnose"-Kommando (`:LibWhoLocks <path>`), das
  `lib.nvim.cross.fs.lock.report` direkt exponiert — nützlich für jedes Plugin, das auf
  Windows destruktive Dateioperationen durchführt und aktuell nur einen kryptischen `EBUSY`
  anzeigt.
- Ein UI-Kit-Beispiel-Katalog als eigenständiges "Playground"-Plugin, das jede
  `lib.nvim.ui.kit`-Primitive (confirm/form/input/menu/picker/toast/…) interaktiv vorführt —
  aktuell existieren die Beispiele nur als statische `.lua`-Dateien unter `docs/EXAMPLES/`.
