# color_my_ascii.nvim

## Zweck
Highlighting-Plugin für ASCII-Art in Markdown-Codeblöcken (```ascii ... ```): automatische
Spracherkennung (31 Sprachen), konfigurierbare Zeichengruppen/Highlights, Farbschemata,
sowie ein `:Fence`-Toolkit für literate-programming-artige Operationen (export, yank, open,
run, format, import, wrap/unwrap) auf beliebigen Fenced Blocks in Markdown. Nutzt Extmarks,
verändert den Buffer nicht (außer explizit über `:Fence`-Befehle). Quelle: README.md,
lua/color_my_ascii/init.lua, lua/color_my_ascii/bindings/*.

## Nicht-standard Patterns / Algorithmen

1. `lua/color_my_ascii/cache_manager.lua:17` — Cache-Tabelle mit `setmetatable({}, { __mode = 'k' })`
   (weak keys). WARUM: Buffer-Nummern als Keys sollen nicht verhindern, dass Lua den Eintrag
   GC'd, falls der Buffer anderweitig verschwindet, ohne dass ein BufDelete-Handler lief —
   defensiv gegen Leaks bei über die Zeit vielen geöffneten Markdown-Buffern.

2. `lua/color_my_ascii/cache_manager.lua:80-109` — Cache-Validität hängt nicht nur an einem
   Timeout, sondern zusätzlich an `changedtick` UND `line_count`. WARUM: `changedtick` allein
   kann bei manchen API-Operationen falsch-positiv/negativ sein; die Kombination aus Tick +
   Zeilenzahl reduziert das Risiko, stale geparste Blöcke nach einer Bearbeitung weiter zu
   nutzen, ohne bei jedem Tastendruck neu zu parsen.

3. `lua/color_my_ascii/cache_manager.lua:170-195` — Eviction bei Erreichen von `max_size`
   sucht linear den ältesten Eintrag (kein LRU mit O(1), sondern O(n)-Scan über alle
   gecachten Buffer). WARUM: bewusster Trade-off — bei max. 50 Buffern ist ein LRU-Ring
   unnötige Komplexität, ein linearer Scan über <=50 Einträge ist billig genug.

4. `lua/color_my_ascii/debounce_manager.lua:82-118` — adaptive Debounce-Delay gestaffelt nach
   Dateigröße (Zeilenzahl), mit linearer Skalierung (`scale_factor`, gedeckelt bei 3x) für
   sehr große Dateien statt fixem Delay. WARUM: Re-Highlighting nach jedem Tastendruck ist bei
   kleinen Dateien billig (kurzer Delay = reaktiv), bei großen Dateien teuer (langer Delay =
   Performance-Schutz) — ein einziger fixer Debounce-Wert wäre für eine der beiden Seiten
   suboptimal.

5. `lua/color_my_ascii/debounce_manager.lua:120-161` — pro Buffer wird ein
   `lib.nvim.debounce`-Handle gecacht und nur neu erzeugt, wenn sich die berechnete Delay-Tier
   ändert (`entry.delay ~= delay`), statt bei jedem Aufruf einen neuen Timer zu bauen. WARUM:
   Timer-Erzeugung/-Zerstörung hat Overhead; Wiederverwendung vermeidet unnötiges
   Timer-Churn, wenn die Datei in derselben Größenklasse bleibt (der Normalfall).

6. `lua/color_my_ascii/language_detector.lua:53-111` — Sprach-Erkennung per Keyword-Scoring
   mit zwei Zählern (`unique`, `total`) statt nur Gesamttreffer: eindeutige Keywords
   (nur in einer Sprache vorkommend) zählen stärker als mehrdeutige, Gesamttreffer dienen nur
   als Tiebreaker, und ein Schwellwert (`language_detection_threshold`) verhindert
   Falscherkennung bei zu wenig Signal. WARUM: naives "meiste Keyword-Treffer gewinnt" würde
   von Sprachen mit vielen generischen Keywords (if/for/return) verzerrt werden, die in fast
   jeder Sprache vorkommen.

7. `lua/color_my_ascii/fence_jump.lua:17-50` — `%`-Override prüft zuerst, ob der Cursor auf
   einer Fence-Delimiter-Zeile steht, und jumpt nur dann; sonst Fallback auf eingebautes
   `normal! %`. WARUM: vermeidet ein hartes Overriding von `%`, das andere `%`-Erweiterungen
   (matchit/vim-matchup) bricht — das Verhalten bleibt für alle Nicht-Fence-Fälle unverändert.

## Abgeleitete Guidelines

1. Caches, die an Buffer-Nummern hängen, sollten `setmetatable({}, {__mode='k'})` (weak keys)
   verwenden, zusätzlich zu explizitem Cleanup bei `BufDelete` — doppelte Absicherung gegen
   Leaks.
2. Cache-Invalidierung nie nur über Timeout — mindestens `changedtick`, ggf. zusätzlich eine
   billige strukturelle Prüfung (Zeilenzahl) kombinieren.
3. Debounce-Delays adaptiv nach Eingabegröße/-kosten staffeln statt eines global fixen Werts,
   wenn die zu debouncende Operation mit der Datengröße skaliert.
4. Debounce-Handles pro Schlüssel (Buffer) wiederverwenden statt pro Aufruf neu erzeugen;
   nur neu bauen, wenn sich der Delay-Parameter tatsächlich ändert.
5. Heuristische Klassifikation (Sprache/Typ-Erkennung) sollte seltene/eindeutige Signale
   höher gewichten als häufige/mehrdeutige, plus einen expliziten Confidence-Schwellwert, um
   Falscherkennung bei schwachem Signal zu vermeiden.
6. Eigene Overrides eingebauter Motions/Keys (`%`, `dd`, etc.) müssen zuerst prüfen, ob der
   Spezialfall vorliegt, und sonst explizit auf das eingebaute Verhalten zurückfallen — nie
   pauschal überschreiben.
7. Keymaps standardmäßig deaktiviert lassen (`keymaps = false`), nur über explizite
   Action-Name→lhs-Tabelle in `setup()` opt-in aktivierbar; Action-Namen von Command-Strings
   trennen (siehe `bindings/keymaps.lua` ACTIONS-Tabelle), damit Nutzer nur benennen statt
   Commands selbst zu kennen.
8. `desc` bei jedem Keymap setzen, damit which-key.nvim ohne separate Registrierung
   funktioniert.
9. Lib.nvim-Funktionen, die eine harte Abhängigkeit sind (z.B. usercmd.composer), direkt
   `require`n; optionale Komfort-Funktionen (z.B. `lib.nvim.map`) weiterhin per `pcall`
   soft-guarden mit Fallback auf Vanilla-API.

## Keybindings-Audit
Alle Keymaps sind opt-in (`keymaps = false` per Default), definiert in
`lua/color_my_ascii/bindings/keymaps.lua`, Action-Liste in docs/BINDINGS.md.

- `highlight` (`:ColorMyAscii`), `toggle`, `schemes`, `ensure_blank_lines`, `show_config`,
  `debug`, `check_fences`, `fence_jump`: alles buffer-globale Ein-Schritt-Aktionen ohne
  Mengen-Semantik.
  - count: n.a. — kein Konzept von "N mal ausführen" ergibt hier Sinn (Toggle ist idempotent,
    Highlight ist Vollbuffer-Operation).
  - Autocompletion: `:ColorMyAscii <Tab>` funktioniert über `lib.nvim.usercmd.composer`
    (subcommand-Vervollständigung, siehe `bindings/usrcmds.lua` Kommentar "Tab completion").
    Für `schemes switch <name>` sind `values = schemes.get_scheme_names()` gesetzt →
    Tab-Completion der Schema-Namen vorhanden. Gut abgedeckt.
  - Fehlende Flags: `:ColorMyAscii toggle` könnte ein `!`-Bang oder Range akzeptieren, um
    mehrere Buffer auf einmal umzuschalten; aktuell nur current buffer.

- `fence_yank`, `fence_open`, `fence_run`, `fence_format`, `fence_select`, `fence_wrap`,
  `fence_unwrap` (`:Fence ...`): Aktionen auf dem Fence-Block unter dem Cursor.
  - count: n.a. für die meisten (yank/open/run/format wirken auf genau einen Block). Für
    `fence_wrap` unterstützt der Ex-Befehl bereits `[range]` (siehe BINDINGS.md:
    `:[range]Fence wrap [lang]`) — das ist die passende Mengen-Semantik für Visual-Mode/Range
    statt count; als reines `n`-Keymap ist ein count aber nicht sinnvoll nutzbar (das
    Keymap-RHS ist `<cmd>Fence wrap<cr>` ohne Range-Übergabe).
  - Autocompletion: `Fence lang <language>` und `Fence import <file>` sind Ex-Commands mit
    Argumenten; ob sie eine `values`/File-Completion analog zu `schemes switch` haben, ist aus
    den gelesenen Dateien nicht ersichtlich (nur bindings/usrcmds.lua für `:ColorMyAscii`
    geprüft, `:Fence`-Registrierung liegt in commands/fence/init.lua, nicht gelesen) —
    unklar/nicht verifiziert.
  - Fehlende Flags: `fence_export` (`:Fence export [path] [--open] [--replace]`) hat kein
    Keymap-Pendant in der ACTIONS-Tabelle (bindings/keymaps.lua) — im Vergleich zu den anderen
    `Fence`-Subcommands eine Lücke.

## Ideen für andere Plugins
1. Ein generisches „Adaptive Debounce"-Modul (Datei-/Eingabegröße → Delay-Tier) als
   eigenständiger Baustein in lib.nvim, falls das Pattern aus `debounce_manager.lua` in
   mehreren Plugins wiederkehrt (color_my_ascii, evtl. github_stats' background fetching).
2. Ein generisches Cache-Statistik-Widget (`:CacheStats`-artiger Befehl), das hit-rate,
   size, evictions über mehrere Plugins hinweg einheitlich anzeigt — das
   `cache_manager.lua`-Stats-Interface hier ist bereits ein gutes Muster dafür.
3. Ein Cross-Plugin "Fence"-Interface analog zur bereits erwähnten "Public Fence API"
   (`require("color_my_ascii").fences`), das auch von gopath.nvim/anderen Plugins für
   Codeblock-Erkennung in Markdown genutzt werden könnte (Vermeidung von Doppel-Parsing).
