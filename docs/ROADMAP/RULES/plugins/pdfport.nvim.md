# pdfport.nvim

## Zweck
Extrahiert und zeigt PDF-Inhalte über eine pluggable Backend-/Renderer-Architektur:
mehrere Extraktions-Backends (pdftotext, pdfplumber, marker-pdf, docling, Claude API,
Ollama, tesseract-OCR), mehrere Renderer (Scratch-Buffer, Float, System-App, Terminal-
Bild), mit Page-Range-Picker und persistentem Cross-Session-Cache. Integriert sich in
neo-tree, nvim-tree, netrw, oil.nvim sowie Telescope/fzf-lua. Baut auf `lib.nvim` auf.
Quelle: `E:\repos\pdfport.nvim\README.md`.

## Nicht-standard Patterns / Algorithmen
- `lua/pdfport/util/cache.lua:1-8,26-56`: Cross-Session-Cache, dessen Invalidierung
  nicht über eine TTL läuft, sondern über den mtime der Quelldatei
  (`entry.mtime ~= file_mtime`). Ein unverändertes PDF bleibt beliebig lange gecacht,
  ein geändertes wird transparent neu extrahiert — spart teure Backend-Aufrufe
  (externe Prozesse, teils LLM-APIs) ohne Stale-Cache-Risiko.
- `lua/pdfport/util/cache.lua:17-24` (`cache_key`): Cache-Key kombiniert Pfad,
  Backend-ID und einen "variant"-String (Seitenauswahl) — dieselbe Datei mit
  unterschiedlichem Backend oder unterschiedlicher Page-Range kollidiert nicht im
  selben Cache-Slot.
- `lua/pdfport/core/dispatcher.lua:176-196` (`start_progress`/Callback-Wrapping):
  Statt an jeder Exit-Stelle den Progress-Handle manuell zu schließen, wird
  `callback` selbst einmalig umgebaut (Closure mit `closed`-Guard), sodass jeder
  nachgelagerte Pfad (async Backend-Callback, synchroner Return, Backend-Exception)
  automatisch durch denselben Finalisierungspunkt läuft. Explizit dokumentierter
  Trade-off: kein `on_cancel`, weil `spawn_capture` kein killbares Handle
  zurückgibt — ein `on_cancel` hätte den Indikator geschlossen, während der Prozess
  weiterlief. Der einzige echte Schutz gegen hängende Extraktion ist
  `timeout_ms` pro Backend.
- `lua/pdfport/core/dispatcher.lua:68-78` (`validate_path`): Prüft Existenz *und*
  Dateityp (`stat.type ~= "file"`) bevor überhaupt ein Backend aufgerufen wird —
  verhindert, dass z. B. ein Verzeichnis versehentlich an ein Backend
  durchgereicht wird.
- `lua/pdfport/core/dispatcher.lua:161-164` (`variant`-Berechnung): Baut den
  Cache-Varianten-String aus `extract_opts.pages` (konkrete Seitenliste) oder
  `max_pages` — zwei unterschiedliche Konfigurationswege werden auf einen
  gemeinsamen Cache-Schlüssel-Bestandteil normalisiert.
- `lua/pdfport/util/page_range.lua:12-46` (`M.parse`): Eigener Mini-Parser für
  Page-Range-Syntax (`"1-3,5,7"`) mit Dedupe via `seen`-Set und sortiertem Output —
  bewusst tolerant (ungültige Segmente werden übersprungen statt die ganze Eingabe
  zu verwerfen).
- `lua/pdfport/bindings/keymaps.lua:36-41,57-69` (`VISUAL_ACTIONS` +
  `register_which_key`): Eine explizite Tabelle markiert, welche Actions
  Visual-Mode statt Normal-Mode sind, damit die which-key-Registrierung den
  richtigen Modus je Action wählt, statt anzunehmen alles sei "n".

## Abgeleitete Guidelines
1. Cache-Invalidierung anhand der Quelldatei-mtime statt TTL, wenn die Quelle
   unveränderlich zwischen Edits ist (Dateien) — vermeidet unnötige Re-Berechnung
   bei unveränderten Inputs und stale Daten bei geänderten.
2. Cache-Keys müssen alle Parameter enthalten, die das Ergebnis beeinflussen
   (hier: Pfad + Backend + Seitenauswahl), sonst liefert der Cache falsche
   Ergebnisse für eine andere Konfiguration derselben Datei.
3. Bei asynchronen Operationen mit mehreren möglichen Exit-Pfaden (Erfolg, Fehler,
   Exception, synchroner Cache-Hit): den Callback selbst umschließen statt an
   jeder Exit-Stelle Cleanup-Code zu duplizieren — ein einziger Finalisierungspunkt
   mit einem `closed`-Guard gegen doppeltes Ausführen.
4. Wenn ein Prozess-Handle nicht killbar ist, keinen `on_cancel`-Hook anbieten, der
   das vortäuscht — stattdessen einen `timeout_ms` als einzige echte Bremse
   dokumentieren. Nicht-einlösbare Abbruch-Fähigkeit ist schlimmer als keine.
5. Vor jedem externen Aufruf (Backend/Prozess) Pfad-Existenz *und* Dateityp
   validieren, nicht nur Existenz.
6. Für Keymap-Defaults, die teils Normal- teils Visual-Mode sind: eine explizite
   Ausnahme-Tabelle (`VISUAL_ACTIONS`) statt stillschweigender Annahme "alles ist
   Normal-Mode" — macht die which-key-Integration und jede weitere
   Modus-abhängige Logik korrekt und wartbar.
7. Datei-Tree-Integrationen (neo-tree, nvim-tree, netrw, oil.nvim) über eine
   gemeinsame Default-Keymap-Tabelle (`M.DEFAULTS`) mit `M.resolve(opts)`
   auflösen, die `nil` (Default) von `false` (deaktiviert) unterscheidet.

## Keybindings-Audit
Quelle: `lua/pdfport/bindings/keymaps.lua`, `docs/BINDINGS.md`.

- `<leader>po` (n, `open`, Mode-Picker): buffer-lokal in Tree-Buffern.
  - Count: **n. a.** — öffnet interaktiven Picker für die Datei unter dem Cursor;
    ein Count hat keine sinnvolle Bedeutung für "einen Picker öffnen".
  - Autocompletion: n. a. (kein Text-Input beim Keymap selbst; der zugehörige
    `:PdfPort`-Command hat laut BINDINGS.md `<Tab>`-Completion via
    `lib.nvim.usercmd.composer`, Details nicht in den gelesenen Dateien geprüft).
  - Idee: keine offensichtliche Lücke.
- `<leader>pt` (n, `open_text`, Extract to buffer): analog, kein Count-Bedarf.
- `<leader>ps` (n, `open_system`): analog.
- `<leader>pi` (n, `open_terminal`, Terminal-Bild-Preview): löst laut
  `docs/BINDINGS.md` einen Page-Range-Prompt aus (`page_range.lua`).
  - Count sinnvoll? **Möglich, aber ungenutzt.** Ein Count könnte z. B. "zeige
    Seite N" bedeuten, aber die Implementierung fragt stattdessen interaktiv per
    `vim.ui`-Input nach dem Range-String — kein Count-Handling vorhanden.
- `<leader>pb` (v, `open_batch`, Batch-Open): einzige Visual-Mode-Aktion, iteriert
  über die Zeilen der Selektion und öffnet jede gefundene PDF-Datei
  (`lua/pdfport/util/batch.lua`, laut BINDINGS.md).
  - Count: n. a. (Visual-Range ersetzt die Funktion eines Counts hier bereits).
  - Autocompletion: n. a.
  - Idee: Ein Fortschritts-/Zusammenfassungs-Feedback nach Batch-Open (X von Y
    PDFs geöffnet, Z Fehler) wäre eine naheliegende Ergänzung — aus den gelesenen
    Dateien nicht ersichtlich, ob das existiert (`batch.lua` selbst wurde nicht
    gelesen).

`:PdfPort [subcommand] [path]`-Command (laut `docs/BINDINGS.md`, Datei
`usrcmds.lua` nicht gelesen): hat laut Doku Tab-Completion via
`lib.nvim.usercmd.composer`; Subcommands `text`, `float`, `system`, `terminal`,
`backends`, `health` — `float`/`terminal` fragen interaktiv nach Page-Range statt
sie als Flag zu akzeptieren, was Scripting/Automation dieser Pfade erschwert
(Idee: `pages=`-kv-Flag zusätzlich zum interaktiven Prompt anbieten).

## Ideen für andere Plugins
- Das mtime-basierte Cross-Session-Disk-Cache-Pattern (`util/cache.lua`) als
  generisches `lib.nvim.cache.disk`-Wrapper-Rezept dokumentieren/extrahieren, damit
  andere teure Extraktions-Plugins (z. B. Video-Transkription, OCR anderer
  Formate) es direkt wiederverwenden statt neu zu erfinden.
- Ein generischer "Range-Parser" (`page_range.lua`-Muster: `"1-3,5,7"` → sortierte,
  deduplizierte Zahlenliste) als `lib.nvim`-Utility, wiederverwendbar für jede
  Seiten-/Zeilen-/Commit-Range-Eingabe in anderen Plugins.
- Ein "Progress-Wrapping-Callback"-Helper in `lib.nvim.progress`, der das in
  `dispatcher.lua` demonstrierte Closure-Pattern (ein Finalisierungspunkt für
  mehrere Exit-Pfade, `closed`-Guard) als fertige Funktion anbietet, statt dass
  jedes Plugin es selbst nachbaut.
