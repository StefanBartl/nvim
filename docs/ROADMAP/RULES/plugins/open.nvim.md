# open.nvim

## Zweck
Ein einziger `:Open [target] [scope]`-Command, der das Ziel unter dem Cursor
(Pfad, URL oder freier Text) an das passende Ziel weiterleitet: Dateimanager,
Browser (auch benannte Browser), GUI-Editor, Terminal, oder einen Neovim-Split.
Kontextbewusst (erkennt Neo-tree/nvim-tree/netrw-Buffer). Zusätzlich `:Open viewer`
(`:UrlView`, `:MDLinksView`) zum Extrahieren und Auflisten von Links/URLs/Markdown-
Links aus Buffer, Range, Verzeichnis oder Projekt, mit Export-Optionen. Baut bewusst
auf `lib.nvim` auf. Quelle: `E:\repos\open.nvim\README.md`.

## Nicht-standard Patterns / Algorithmen
- `lua/open/context.lua:39-53` (`M.with_cache`): Ein manuelles Memoization-Fenster
  um eine ganze `run_open`-Invocation, das per Boolean-Flag (`_cache_active`)
  aktiviert wird, damit verschachtelte `M.resolve()`-Aufrufe, die selbst
  `M.gather()` aufrufen, denselben bereits gelesenen Editor-Zustand wiederverwenden
  statt Cursor/Cfile/Cword/Visual-Selection mehrfach neu abzufragen. Grund laut
  Kommentar: mehrfaches `vim.fn.expand`/`getpos`-Lesen pro Invocation ist unnötig,
  wenn die Signale sich innerhalb eines Aufrufs nicht ändern.
- `lua/open/context.lua:89-103` (`resolve_existing_path`): Prüft einen Kandidaten-
  Pfad zuerst wörtlich, dann relativ zum Verzeichnis des aktuellen Buffers — nicht
  relativ zum cwd. Das deckt den häufigen Fall ab, dass ein relativer Pfad im
  aktuell bearbeiteten File gemeint ist, nicht relativ zum Neovim-Start-Verzeichnis.
- `lua/open/context.lua:126-155` (`resolve_neotree_path`): Versucht zuerst ein
  projektspezifisches `config.neotree.utils.node`-Modul (pcall-geschützt, da es
  außerhalb dieses Plugins liegt) und fällt erst danach auf den generischen
  `state.tree:get_node()`-Pfad zurück — bewusster Kompromiss zwischen einer
  optimierten, aber optionalen Erweiterung und einem robusten Fallback.
- `lua/open/viewer/scan.lua:19-27,151-208` (`from_line`): Markdown-Links werden
  zuerst erkannt und ihre Byte-Spans (`covered`) gemerkt; die anschließende
  Bare-URL-Suche überspringt bereits abgedeckte Spans (`is_covered`), damit eine
  URL innerhalb `[text](https://...)` nicht doppelt als eigenständiger URL-Treffer
  auftaucht. Naive Ansätze (zwei unabhängige Regex-Durchläufe ohne Span-Tracking)
  würden Duplikate erzeugen.
- `lua/open/viewer/scan.lua:114-139` (`resolve_path`): Ein Kandidat gilt nur dann
  als Pfad, wenn er tatsächlich auf der Platte existiert (`filereadable`/
  `isdirectory`-Check) — bewusst teuer (Disk-Stat pro Kandidat), aber nötig, weil
  sonst jedes `a/b` in Prosa oder jeder Methodenaufruf `foo.bar` fälschlich als Pfad
  gemeldet würde (Kommentar im Code benennt genau das). Deshalb ist die
  Pfaderkennung standardmäßig opt-in (`opts.paths`).
- `lua/open/viewer/scan.lua:100-112` (`M.resolve`): Trennt ein Trailing-`#anchor`
  vom Zielpfad ab, *bevor* das Dateisystem geprüft wird — sonst würde
  `file.md#section` nie als existierende Datei erkannt.
- `lua/open/bindings/usrcmds.lua:12-18` (Kommentar zur Routing-Reihenfolge):
  `:Open viewer …` und die flache `:Open [target] [scope]`-Grammatik koexistieren
  nur, weil `viewer` als literale Subroute *vor* der offenen `path = {}`-Root-Route
  matched — mit der expliziten Einschränkung, dass kein Handler jemals unter dem
  Namen `"viewer"` registriert werden darf, da er sonst unerreichbar würde. Das ist
  eine dokumentierte, fragile Namenskollisions-Regel statt eines strukturellen
  Schutzes.
- `lua/open/bindings/usrcmds.lua:178-205` (`run_viewer`): Disambiguiert das erste
  Positional-Argument von `:Open viewer` zur Laufzeit als "kind" oder "scope", je
  nachdem ob es ein bekanntes Kind ist — mit expliziter Warnung statt stillem
  Verwerfen, wenn zwei Argumente da sind aber das erste kein bekanntes Kind ist.
  Bewusste UX-Entscheidung: ein Tippfehler soll sichtbar sein statt lautlos ignoriert
  zu werden.
- `lua/open/platform.lua:1-36`: Cached das Plattform-Ergebnis pro Session in einem
  eigenen Modul-lokalen `_cache`, obwohl die zugrunde liegenden `lib.nvim.cross.
  platform.is_*`-Detektoren laut Kommentar bereits selbst cachen — bewusst
  redundant, um die Rückgabeform (`OpenNvim.Platform`-Tabelle) stabil zu halten,
  nicht um Syscalls zu sparen.

## Abgeleitete Guidelines
1. Editor-Zustand (Cursor, Selection, cfile/cword), der innerhalb einer einzelnen
   Command-Invocation mehrfach gebraucht wird, über ein explizites
   Cache-Fenster (`with_cache`) memoizen statt jedes Mal neu von der API zu lesen.
2. Relative Pfadauflösung standardmäßig relativ zum Verzeichnis des aktuellen
   Buffers versuchen, nicht nur relativ zum cwd — das deckt den häufigeren
   Nutzungsfall ab.
3. Bei Text-Extraktion (Links, URLs, Pfade) aus derselben Textquelle: bereits
   erkannte Treffer als Byte-Spans merken und in weiteren Erkennungsläufen
   überspringen, um Duplikate zu vermeiden.
4. Teure Existenzprüfungen (Disk-Stat pro Kandidat) nur opt-in anbieten, nicht als
   Default — sonst False-Positives bei jedem pfadähnlichen Wort in Prosa/Code.
5. Wenn eine literale Subroute und eine offene "catch-all"-Route im selben Command
   koexistieren müssen, die Namenskollisions-Regel explizit dokumentieren (im Code
   *und* in BINDINGS.md), damit sie nicht versehentlich verletzt wird.
6. Mehrdeutige Positional-Argumente (kann A oder B sein) zur Laufzeit anhand
   bekannter Werte disambiguieren, aber bei Unklarheit eine Warnung ausgeben statt
   still zu raten.
7. Für jeden Handler-Registry-Namespace (hier: `HANDLER_MODULES`) eine zentrale
   Lookup-Tabelle pflegen statt verstreuter `require`-Aufrufe — erleichtert
   Erweiterung um neue Handler.
8. Eigene Ex-Commands sollen dynamische Tab-Completion für Handler-/Kind-Namen aus
   der Registry ziehen (`reg.list_keys()`), nicht hartkodierte Listen — bleibt
   automatisch synchron mit tatsächlich registrierten Handlern.

## Keybindings-Audit
Standardmäßig **keine** Keymaps; optional über `setup({ keymaps = {...} })`.
Quelle: `lua/open/bindings/keymaps.lua`, `docs/BINDINGS.md`.

- `keymaps.open_default` (n, optional, z. B. `<leader>oo`): führt `:Open` (ohne
  Argumente) aus.
  - Count sinnvoll? **Nein / n. a.** — feste `<Cmd>...<CR>`-Zuordnung ohne
    Count-Auswertung; `:Open` selbst ist kontextabhängig (Cursor-Ziel), ein Count
    hätte keine offensichtliche Bedeutung.
  - Autocompletion für den zugrunde liegenden Command: **ja, vorbildlich** —
    `OPEN_TARGET`/`OPEN_SCOPE`-Completion-Typen ziehen Handler-Keys live aus der
    Registry, plus `path=`-Datei-Completion und benannte Scope-Keywords
    (`usrcmds.lua:58-113`).
  - Fehlende Flags/Ideen: keine offensichtlichen Lücken; Scope-Token-Set ist
    bereits umfangreich (`%`, `cfile`, `cwd`, `git`, `path=`, Keywords).
- `keymaps.open_browser` / `keymaps.open_manager` (n, optional): fest verdrahtete
  Kurzformen für `:Open browser` / `:Open filemanager`.
  - Count: n. a. aus denselben Gründen.
  - Autocompletion: n. a. (kein Text-Input, feste Invocation).
  - Idee: analoge Kurz-Keymaps für `:Open split`/`:Open terminal` wären eine
    naheliegende Ergänzung, fehlen aber (nur browser/manager sind vordefiniert).

Picker (`open/picker.lua`, nicht vollständig gelesen) und Viewer-Ex-Commands
(`:Open viewer`, `:UrlView`, `:MDLinksView`) haben keine eigenen Keymaps, nur
Command-Flags (`--paths`, `--anchors`, `--dupes`, `--flat`, `sort=`, `out=`) mit
vollständiger Tab-Completion (`usrcmds.lua:228-249`, `docs/BINDINGS.md:34-41`).

## Ideen für andere Plugins
- Das `with_cache`-Memoization-Pattern für "mehrere Signale aus dem Editor-Zustand,
  einmal pro Command-Invocation" als generisches `lib.nvim`-Utility anbieten, damit
  nicht jedes Plugin eine eigene Cache-Flag-Variable erfindet.
- Ein eigenständiges "Link-Harvester"-Plugin (Kern von `open/viewer/scan.lua`)
  losgelöst von open.nvim: URLs/Markdown-Links/Pfade aus beliebigen Quellen
  extrahieren, mit Span-Dedupe und optionaler Pfad-Validierung — heute schon fast
  eigenständig genug für ein eigenes Modul in `lib.nvim`.
- Eine generische "Disambiguierendes-Positional-Argument"-Hilfsfunktion für
  `lib.nvim.usercmd.composer` (Muster aus `run_viewer`), die bekannte Enum-Werte
  gegen ein Freitext-Argument matched und bei Unsicherheit warnt — würde
  wiederkehrenden Code in mehreren `*.nvim`-Repos ersetzen (replacer.nvim hat laut
  Kommentar ein ähnliches `:Replace`/`:Replacer`-Muster).
