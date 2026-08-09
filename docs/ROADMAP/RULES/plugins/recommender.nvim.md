# recommender.nvim

## Zweck
Analysiert den aktuellen Buffer (oder projektweit mit `-c`/`--cwd`) auf häufig
wiederholte "dotted chains" (`vim.api`, `table.insert`, …) in Lua/JS/TS/Python
und schlägt `local`-Alias-Deklarationen in einem interaktiven Floating-Window
vor (`lua/recommender/init.lua:1-9`, README.md:17). Zwei Analyzer-Backends für
Lua: regex (schnell, keine Abhängigkeit) und Tree-sitter (präziser, braucht
Parser). Arbeitet eng mit `replacer.nvim` zusammen (Replace-Mode ruft `:Replace`
auf, siehe `lua/recommender/float/keymaps.lua:104-105`).

## Nicht-standard Patterns / Algorithmen

1. **Prefix-Blacklist statt Exact-Match** — `lua/recommender/blacklist.lua:16-26`:
   `is_blacklisted()` matcht per `starts_with`, damit ein Eintrag `"vim.api"`
   automatisch auch `"vim.api.nvim_buf_get_lines"` blockt. Naiv wäre exaktes
   Chain-Matching, das würde bei jeder neuen Sub-Chain einen neuen
   Blacklist-Eintrag verlangen.

2. **Zwei-Pass Chain-Extraktion (3-Teile vor 2-Teile)** —
   `lua/recommender/analyzers/regex.lua:13-25`: `extract_chains()` sammelt
   zuerst 3-Segment-Ketten (`vim.api.nvim_*`), dann 2-Segment-Ketten, und
   dedupliziert über `lib.lua.tables.dedup_list`. Das verhindert, dass ein
   3-teiliger Match nur als Teilstring seines 2-teiligen Präfixes zählt.

3. **Common-Prefix-Kollabierung im Treesitter-Analyzer** —
   `lua/recommender/analyzers/treesitter.lua:68-94`: `common_prefix()`
   berechnet das längste gemeinsame Präfix (min. Tiefe 2) aller gefundenen
   Ketten und schlägt für zusammenhängende Ketten einen einzigen Alias auf
   dem gemeinsamen Präfix vor, statt pro Chain einen eigenen Alias vorzuschlagen.
   Das ist eine bewusste Abweichung vom naiven "ein Alias pro Chain"-Ansatz,
   um z.B. `vim.api.nvim_buf_get_lines` und `vim.api.nvim_buf_set_lines`
   gemeinsam unter `local api = vim.api` zu bündeln.

4. **pcall-Sandboxing um jeden Tree-sitter-Zugriff** —
   `lua/recommender/analyzers/treesitter.lua:16-18,26,31,39-49`: Parser-Erwerb,
   Parse-Lauf, Query-Parse und Node-Text-Extraktion sind alle einzeln über
   `pcall` abgesichert und geben bei Fehler leere Ergebnisse statt Fehler zu
   werfen — Tree-sitter-APIs können bei fehlendem Parser oder inkonsistentem
   Buffer-State werfen, und der Analyzer soll dann einfach nichts vorschlagen
   statt den ganzen Command abzubrechen.

5. **Synchrones Dateilesen mit stillem Skip bei Fehlern** —
   `lua/recommender/project.lua:11,93-109`: `read_lines()` liest jede Datei via
   `pcall(vim.fn.readfile, p)` und überspringt unlesbare Dateien (Rechte-Fehler,
   Race-Delete) statt den gesamten Scan abzubrechen. Bewusst synchron gehalten,
   weil das Plugin laut Kommentar keine async-Maschinerie hat und ein
   synchroner Scan zum Rest der Codebase passt (Kommentar Zeile 10-11).

6. **Truncation mit Nutzer-Warnung statt harter Grenze** —
   `lua/recommender/project.lua:80-90` + `bindings/usrcmds.lua:120-121`: Scan wird
   bei `cwd_max_files` gekappt, aber der User bekommt explizit eine
   `notify.warn(...capped at %d files...)`-Meldung statt eines stillen Cutoffs.

7. **Ignore-State pro Buffer, nicht global** —
   `lua/recommender/bindings/usrcmds.lua:61,83`: `ignore_by_buf[bufnr]` hält
   ignorierte Chains pro Quell-Buffer, damit `<BS>` (ignorieren) in Buffer A
   nicht Vorschläge in Buffer B unterdrückt.

8. **Fenster-Zielfindung mit Prioritätskette** —
   `lua/recommender/float/keymaps.lua:44-62`: `find_target_window()` probiert
   gespeichertes `source_win` → alternates Fenster (`winnr("#")`) → erstes
   "normales" Fenster (kein Spezial-Buffer, `modifiable`). Defensive Prüfung
   via `is_normal_window()` (Zeile 27-42) gegen ungültige/geschlossene Fenster
   und Spezial-Buffer (quickfix, terminal, etc.), da der Ziel-Buffer für die
   Insertion editierbar sein muss.

## Abgeleitete Guidelines

1. Blacklists/Filter-Listen als Prefix-Match implementieren, wenn Einträge
   natürlicherweise hierarchisch sind (Modul-Pfade, API-Namespaces) — spart dem
   Nutzer, jede Sub-Chain einzeln eintragen zu müssen.
2. Jeden Tree-sitter-API-Call einzeln mit `pcall` absichern und bei Fehler
   einen leeren/neutralen Wert zurückgeben statt zu werfen — Parser-Verfügbarkeit
   und Buffer-State sind nicht garantiert.
3. Bei synchronem Massen-Datei-Lesen (`vim.fn.readfile` über viele Pfade) immer
   eine `max_files`-Grenze konfigurierbar machen UND bei Truncation aktiv
   informieren (`notify.warn`), nicht still kappen.
4. Ignore-/Ausschluss-State im Plugin-State pro Buffer/Kontext halten, nicht in
   einem globalen Tisch, sonst bluten Interaktionen zwischen Buffern durch.
5. Wiederverwendbares "finde ein sinnvolles Zielfenster"-Muster: gespeichertes
   Fenster → Alternate-Fenster → erstes normales Fenster, mit
   `is_normal_window()`-Guard (kein Spezial-Buftype, `modifiable`). Für jedes
   Plugin nützlich, das Text in "das Fenster, aus dem der User kam" einfügen will.
6. Analyzer-Module cachen (`_analyzer_cache` in `bindings/usrcmds.lua:40-58`) und
   nur bei erstem Bedarf per `pcall(require, ...)` laden, mit sprechender
   Fehlermeldung inkl. gültiger Optionen bei unbekanntem Namen.
7. Ex-Commands über `lib.nvim.usercmd.composer` mit deklarativen `routes`,
   `args` (mit `values`-Whitelist für Positional-Args) und `flags`
   (inkl. `short`-Alias) definieren statt manuellem Parsen — spart Boilerplate
   und gibt Autocompletion "for free" (siehe Composer-Kommentar in
   `bindings/usrcmds.lua:9-16`).
8. `setup()` idempotent machen mit einem simplen `_setup_done`-Guard
   (`lua/recommender/init.lua:11,16-19`).

## Keybindings-Audit

Globale Keymaps aus `lua/recommender/bindings/keymaps.lua:16-23` (nur wenn
`config.keymaps ~= false`):

- `<leader>lr` → `:Recommender` (Standard-Analyzer/Threshold)
- `<leader>lR` → `:Recommender -r` (Replace-Mode)
- `<leader>lrr` → `:Recommender regex`
- `<leader>lrt` → `:Recommender treesitter`
- `<leader>lrj` → `:Recommender javascript`
- `<leader>lrp` → `:Recommender python`
- `<leader>lrh` → `:Recommender regex 5` (hoher Threshold, hart kodiert 5)
- `<leader>lrc` → `:Recommender -c` (projektweit/cwd)

Alle sind reine `<cmd>...<cr>`-Wrapper ohne Argumentübergabe zur Laufzeit.

- **Count-Unterstützung**: Keins dieser Keymaps interpretiert `v:count`.
  Sinnvoll wäre z.B. `N<leader>lr` → Threshold `N` direkt setzen (aktuell nur
  über den hart kodierten `<leader>lrh` mit Threshold 5 möglich). Nicht
  implementiert — potentielle Lücke.
- **Ex-Command-Autocompletion**: `:Recommender` wird über
  `lib.nvim.usercmd.composer` mit `args[].values = ANALYZER_NAMES` registriert
  (`bindings/usrcmds.lua:178-179`), das liefert vermutlich Completion für die
  Analyzer-Namen als Positional-Arg. Für den Threshold (zweiter Positional-Arg)
  gibt es keine sinnvolle Completion-Liste (Zahl), was in Ordnung ist.
- **Fehlende Flags/Optionen**: kein Weg, den Threshold direkt als Flag
  (`--threshold=N`) statt als unbenannten zweiten Positional-Arg zu setzen —
  bei Nutzung mit Analyzer-Namen an Position 1 wird der Threshold zu Position 2,
  was für Command-Line-User uneindeutig ist, wenn sie nur den Threshold ändern
  wollen, ohne den Analyzer zu nennen (aktuell over `tonumber(pos_args[2]) or
  tonumber(pos_args[1])`, Zeile 74, funktioniert nur als Fallback-Kette, kein
  explizites Flag).

## Ideen für andere Plugins

- **Generisches "Common-Prefix-Kollabierung"-Modul**: Der Treesitter-Analyzer-
  Algorithmus (längstes gemeinsames Präfix über eine Liste von Strings, dann
  Alias-Vorschlag auf dem Präfix) ist unabhängig von Lua-Chains — ließe sich als
  eigenständiges `lib.nvim`-Utility für andere Code-Analyse-Plugins extrahieren
  (z.B. für Import-Konsolidierung in JS/TS).
- **Ein "Dead Blacklist Entry"-Checker**: Ein kleines Tool, das für ein Projekt
  prüft, welche Blacklist-/Ignore-Einträge in `custom_aliases`/`blacklist` nie
  greifen (weil die Chain nie im Code vorkommt) — Wartungshilfe für Config-Dateien.
- **Generischer "Insert into best target window"-Helper** als eigenes
  `lib.nvim`-Modul, da das Muster (source_win → alternate → erstes normales
  Fenster) in mehreren Plugins mit Floating-UI wahrscheinlich wiederkehrt
  (siehe auch pickers.nvim/reposcope.nvim, die ähnliche Fenster-Logik brauchen
  könnten).
