# documentation.nvim

## Zweck
Doxygen-artiges Werkzeug für annotierte Lua-Bäume (und inzwischen JS/TS/TSX):
scannt einen Baum mit `---@module`-Headern, baut eine deterministische IR
(`Documentation.IR`), prüft sie auf Drift zwischen Doku und Code
(`core/check.lua`) und rendert daraus eine interaktive HTML-Karte, ein
Markdown-Overview, ein JSON-Artefakt und optional ein Coverage-Badge. Zusätzlich
gibt es `:DocBrowse`, einen editor-internen Navigator über dieselbe IR (kein
Graph-Rendering im Terminal, sondern Listen mit Drill-down). Ist aus
`lib.nvim.docmap` herausgewachsen und baut weiterhin auf `lib.nvim` auf (`fs`,
`ui.kit`, `usercmd`, `notify`, `map`).

## Nicht-standard Patterns / Algorithmen

- **`lua/documentation/core/lang_registry.lua`** — Sprachunterstützung als
  Registry statt als Fallunterscheidung im Scanner. `scan.lua` fragte früher
  direkt `"%.lua$"` ab und rief `functions.scan_file` hart verdrahtet auf; das
  wurde durch eine Registry ersetzt, bei der jedes Backend sich selbst
  registriert (`M.register(name, backend)` am Dateiende jedes
  `core/lang/*.lua`). Grund laut Header: eine Layer-Regel
  (`documentation.core` darf nicht direkt in `documentation.core.lang.*`
  greifen) sollte technisch durchsetzbar sein, nicht nur dokumentiert. Die
  Registry selbst heißt bewusst *nicht* `lang.init`, weil sie sonst selbst
  gegen die Regel verstoßen würde, die sie durchsetzen soll — sie liegt
  strukturell *neben* der Grenze, nicht dahinter.
- **`lang_registry.lua:120-143` (`M.reset()`)** — re-registriert Backends
  explizit per `require(modname)` + `M.register(backend.name, backend)`
  statt sich auf `ensure_loaded()`s Lazy-Reload zu verlassen. Kommentar
  beschreibt einen echten, beobachteten Bug: `require()` liefert bei bereits
  gecachtem Modul die alte Tabelle zurück, ohne die Datei erneut auszuführen
  — der `register()`-Aufruf am Dateiende feuert dann kein zweites Mal, und
  `for_file()` würde nach einem `reset()` für immer `nil` liefern. Fix:
  Namen von der bereits gecachten Backend-Tabelle lesen (`.name`) statt auf
  Re-Execution zu hoffen.
- **`lua/documentation/core/duplicates.lua`** — Duplikaterkennung über
  Baumstruktur (`fn.shape`, ein Hash über Treesitter-Node-*Typen*, nie über
  Text) statt über Byte-Vergleich. Damit matchen umbenannte Kopien, was laut
  Kommentar der eigentliche Zweck ist ("a copy-paste gets renamed on the way
  in"). `MIN_SIZE = 40` ist eine hart codierte Untergrenze, empirisch
  ermittelt ("no floor reports 5 groups, a floor of 40 reports 2, both real"),
  bewusst kein Runtime-Option, weil "ein Knopf, den niemand einzustellen weiß,
  schlimmer ist als ein dokumentierter Default".
- **`lua/documentation/core/luals.lua:41-102` (`M.run`)** — `lua-language-server
  --doc` läuft blockierend für den Aufrufer, ist aber intern async gebaut
  (`spawn_capture` + `vim.wait` mit Timeout-Marge von +3000ms über den
  Prozess-Timeout hinaus), damit ein hängender LS-Prozess nicht den Editor
  einfriert. Enrichment-Fehler degradieren zu einem info-severity Finding
  statt den ganzen Scan abzubrechen (`init.lua:145-170`).
- **`luals.lua:104-127` (`referenced_classes`)** — Type-Referenzen aus rohen
  LuaCATS-Typstrings (`"table<string, Documentation.Node>"`) werden per
  Substring-Scan statt echtem Typ-Parser extrahiert. Bewusst so belassen,
  weil Klassennamen immer gepunktet/namespaced sind und daher nicht mit
  generischer Typ-Syntax (`table<`, `string[]`, `fun(...)`) kollidieren
  können — ein einfacher Regex reicht, ein echter Parser wäre unnötiger
  Aufwand.
- **`luals.lua:242-340`** — Type- und Extends-Edges werden getrennt gesammelt,
  sortiert und *am Ende* an `ir.edges` angehängt, statt sie direkt
  hineinzuschreiben. Grund: `ir.edges` trägt auch Require-/Call-Edges mit
  anderen optionalen Feldern; ein gemeinsamer Comparator müsste jeden
  Edge-Typ kennen. Jeder Producer sortiert seinen eigenen Block — Determinismus
  bleibt erhalten (wichtig, weil `--check` byte-vergleicht), ohne einen
  Comparator zu bauen, der `nil`-Felder über Edge-Typen hinweg vergleichen muss.
- **`lua/documentation/bindings/usrcmds/init.lua:126-166` (`buffer_root`)** —
  Root-Auflösung erfolgt bei *jedem* Kommandoaufruf frisch aus dem aktuellen
  Buffer (`vim.fs.root(bufname, markers)`), nicht einmalig in `setup()` und
  nicht über `getcwd()`. Kommentar beschreibt einen tatsächlich reproduzierten
  Bug: da das Plugin `cmd`-lazy ist, band "einmal" praktisch an den ersten
  `:DocMap`-Aufruf der Session, wonach jeder weitere Aufruf stillschweigend
  das erste Repo neu schrieb, unabhängig vom aktuell offenen Buffer. Auch
  `getcwd()` wurde verworfen, weil `:e` in ein Nachbar-Repo dem Arbeitsverzeichnis
  nicht folgt. Bewusst `vim.fs.root` statt `lib.nvim`s
  `polymorphic_rootresolver`, weil letzteres Roots unter `stdpath("config")`
  auf das Config-Verzeichnis kollabiert — falsch für ein Git-Worktree, das
  *innerhalb* der Config liegt, aber ein eigenständiges Repo ist.
- **`lua/documentation/editor/serve.lua`** (laut `docs/SECURITY.md`) —
  lokaler HTTP-Server bindet ausschließlich `127.0.0.1`, Port `0` (OS wählt
  freien Port), stirbt per `VimLeavePre`-Autocmd mit dem Editor. Zwei Routen
  mit expliziten Shape-Validatoren: `safe_sha` akzeptiert nur `^%x%x%x%x%x%x%x+$`
  bis 40 Zeichen (selbst `HEAD` wird abgelehnt — "a whitelist that starts
  making exceptions stops being one"), `safe_static_name` lehnt Pfadtrenner
  und `..`-Segmente ab. Motivation: Der Wert geht als Argument an `git`, und
  eine reine Shape-Prüfung ist laut Kommentar die einzige sichere Antwort auf
  "ist das eine SHA".
- **Subprozess-Ausführung durchgängig via `vim.system` mit argv-Array** (nie
  `io.popen`/`os.execute`/Shell) — macht `:DocMap diff <ref>` etc. sicher
  gegen Argument-Injection, weil es keine Shell gibt, die z. B. `; rm -rf ~`
  interpretieren könnte; ein solcher String wird `git` als ein einziges
  literales Argument übergeben und von git selbst als ungültige Revision
  zurückgewiesen (`docs/SECURITY.md`).
- **`lua/documentation/bindings/keymaps.lua`** — Override-Resolution
  (`M.resolve`) gibt immer eine *frische* Liste zurück statt die Default-Tabelle
  zu mutieren, weil zwei gleichzeitig geöffnete Browser mit unterschiedlichen
  Optionen sich sonst gegenseitig die Bindings überschreiben würden (module-level
  Tabelle wäre sonst prozessweit "vergiftet" durch den ersten Caller).
  Unbekannte Override-IDs werden per `notify.warn` gemeldet statt still
  ignoriert — "a silently dropped override is the worst outcome here".
- **`lua/documentation/editor/browse/init.lua:319-323` (`CLEAR`-Sentinel)** —
  Ein `setmetatable({}, {__tostring=...})`-Sentinel-Wert wird verwendet, um
  in einem Patch-Table explizit "dieses Feld löschen" von "dieses Feld nicht
  anfassen" zu unterscheiden, weil `pairs()` niemals einen Key mit `nil`-Wert
  liefert (`{sha = nil}` ist äquivalent zur leeren Tabelle). Kommentar nennt
  den konkret beobachteten Bug: `-` aus einem geöffneten Commit heraus
  zeichnete dieselbe Funktionsliste neu, weil `go()` de facto nichts
  übergeben bekam.
- **`browse/init.lua:337-383` (`go`) / Undo-History-Modell** — Die
  Navigations-History speichert die *aktuelle* Position mit (nicht nur
  vergangene), `hindex` zeigt darauf. Kommentar erklärt explizit, dass die
  erste Implementierung nur vergangene Positionen speicherte und dabei
  strukturell kaputt war (`<C-o>` sprang beim ersten Aufruf zu weit).
- **`browse/init.lua:99-129` (`load_commits`)** — `git log`-Ausgabe wird mit
  Unit/Record-Separatoren (`%x1e`, `%x1f`) statt druckbaren Trennzeichen
  geparst, weil ein Commit-Subject theoretisch jedes "sicher aussehende"
  Zeichen enthalten kann.
- **`browse/init.lua:140-152` (`load_impact`)** — `git show` schließt
  `out_dir` explizit per Pathspec aus (`:(exclude)%s`), weil der Diff eines
  Commits sonst laut Messung 4.8 MB groß wäre, wovon nur ~16 KB nicht die
  regenerierte Karte selbst betrifft.
- **`lua/documentation/init.lua:240-320` (`M.to_json`)** — Eigene, manuelle
  JSON-Serialisierung (String-Konkatenation über `json.encode` pro Feld) statt
  `vim.json.encode` auf der ganzen Struktur, weil Key-Reihenfolge bei
  `vim.json.encode` unspezifiziert ist, das Artefakt aber byte-deterministisch
  sein muss (`--check` vergleicht Bytes).

## Abgeleitete Guidelines

1. **Öffentliche Grenze explizit validieren, intern nicht.** `init.lua`s
   `assert_opts` prüft `opts.root` nur an publizierten Einstiegspunkten
   (`scan_full`, `generate`, `install`, `write_artifacts`), nicht auf jeder
   der ~270 internen Funktionen — dort greift ohnehin LuaLS. Assertions lohnen
   sich nur dort, wo ein *externer* Aufrufer (Plugin, Skript, `:lua`-Zeile)
   eine falsche Form übergeben kann, nicht als Rauschen überall.
2. **Sprachspezifisches Wissen hinter einer Registry verstecken, nicht in der
   Walk-Logik verteilen.** Wenn ein Modul mehrere Backends/Formate/Adapter
   unterstützen soll, ist die Liste der konkreten Modulnamen an *einer* Stelle
   zu halten (`lang_registry.KNOWN_BACKENDS`), nirgendwo sonst darf ein
   konkreter Backend-Name auftauchen.
3. **Layer-Regeln durch Modulplatzierung erzwingen, nicht nur per Konvention.**
   Ein Modul, das legitim eine Schichtgrenze überschreiten muss, gehört
   strukturell *neben* die Grenze (eigener Namespace), nicht hinter eine
   Ausnahme in der Regel selbst.
4. **Root/Kontext pro Aufruf aus dem aktuellen Buffer auflösen, nie einmalig
   cachen**, wenn ein Kommando `cmd`-lazy registriert wird und mehrere
   Projekte im selben Prozess vorkommen können. `getcwd()` ist ebenfalls
   falsch, weil es `:e` in ein anderes Repo nicht folgt.
5. **Empirisch ermittelte Konstanten (Schwellwerte, Timeouts) als benannte
   Modulfelder mit Begründung im Kommentar**, nicht als konfigurierbare
   Optionen, wenn niemand realistisch weiß, wie man sie einstellen sollte.
6. **Deterministisches Output-Artefakt ⇒ jede Quelle von `pairs()`-Iteration
   nachträglich explizit sortieren**, inklusive Tie-Breaks bis zum letzten
   Feld. Sobald ein Artefakt committed und byte-verglichen wird
   (`--check`), ist jede Stelle mit unspezifizierter Reihenfolge ein Bug in
   Wartestellung.
7. **Subprozesse ausschließlich mit argv-Array (`vim.system`), nie über eine
   Shell.** Das ist die einzige Absicherung gegen Argument-Injection bei
   nutzergegebenen Strings (Git-Refs, Ranges), die an externe Programme
   weitergereicht werden.
8. **Server-artige Oberflächen defensiv eng validieren, mit Whitelist statt
   Blacklist**, und dokumentieren, was *nicht* verteidigt wird (siehe
   `docs/SECURITY.md`s "What this does not defend against"-Abschnitt — sehr
   nachahmenswertes Muster: ehrliche Grenzen explizit aufschreiben statt
   impliziten Schutz zu suggerieren).
9. **Config-Merge: Kopie der Defaults pro Aufruf, nie die geteilte
   Default-Tabelle selbst mutieren** (`config/init.lua:75`, `keymaps.lua:39`
   im selben Muster) — sonst "vergiftet" der erste Aufrufer alle folgenden im
   selben Prozess.
10. **Ein Sentinel-Wert für "explizit löschen" in Patch/Merge-Strukturen**,
    wenn `nil` in Lua-Tabellen mit `pairs()` nicht von "Feld nicht gesetzt"
    unterscheidbar ist.
11. **Ein Options-Objekt geht immer durch eine zentrale `config.build()`**,
    die Repo-übliche Defaults ableitet (hier: Source-Verzeichnis-Erkennung),
    statt dass jeder Downstream-Konsument eigene `opts.x or default`-Fallbacks
    wiederholt.
12. **Autocmds/Usercmds als deklaratives Manifest führen** (`bindings/autocmds.lua`),
    das nicht der Ort der Erzeugung ist, sondern ein durchsuchbares Verzeichnis
    ("Account", nicht "Home") mit `owner`/`lifetime`/`why` pro Eintrag — erlaubt
    generierte Doku (`docs/BINDINGS.md`) und `:checkhealth`-Introspektion ohne
    Grep durch den Code.
13. **Ein Keymap-Table ist die einzige Quelle für Binding UND Cheatsheet-Text**
    (`browse/init.lua`s `KEYS`), damit Hilfe-Overlay und tatsächliches
    Verhalten nie auseinanderlaufen — genau die Art von Drift, die dieses
    Plugin selbst bei fremdem Code aufspürt.
14. **Soft-Dependencies über `pcall(require, ...)` zur Laufzeit prüfen, nicht
    beim Laden cachen** (`send_request` prüft `runtime-analysis.nvim` bei
    jedem Tastendruck neu, nicht einmalig beim Start).

## Keybindings-Audit

Das Plugin setzt **keine globalen Keymaps**. Alle Bindings sind buffer-lokal
auf dem von `:DocBrowse` erzeugten Scratch-Buffer (`bindings/keymaps.lua:17-20`,
`editor/browse/init.lua`). Die maßgebliche Liste ist `KEYS` in
`editor/browse/init.lua:1018-1176`, komplett override-/deaktivierbar über
`opts.keys` (Action-IDs, nicht die LHS).

Relevante Einträge:

- **`j`/`k`** (native, kein eigenes Handler) — `count` funktioniert automatisch,
  weil bewusst *nicht* re-implementiert wurde ("j/k stay native so counts and
  scrolloff behave"). Vorbildlich: kein Grund, native Cursorbewegung
  nachzubauen.
- **`-`/`<BS>` (up)** und **`<C-o>`/`<C-i>` (history back/forward)** — nutzen
  explizit `vim.v.count1`, also `3-` geht drei Ebenen hoch, `5<C-o>` fünf
  Schritte zurück. Sinnvoll umgesetzt.
- **`+`/`_` (depth inc/dec, nur im `deps`-Modus)** — nutzt ebenfalls
  `vim.v.count1` und clamped auf `[1,9]`. Gut: Ungültige Counts führen nicht
  zu Out-of-range-Werten.
- **`gd`/`gq`/`gI`/`gO`/`gD`/`gs`** (goto source, quickfix, impact, open page,
  commit diff, send request) — kein `count` sinnvoll anwendbar (einmalige
  Aktionen auf der aktuellen Selektion), korrekt ohne Count-Handling.
- **`p`/`d`** (pin/unpin) — Toggle auf der aktuellen Zeile, kein `count`
  sinnvoll.
- **`1`–`9`** (Modus-Wahl `structure`/`deps`/`calls`/… ) — feste Zifferntasten
  als Modus-Auswahl statt `count`+Taste. Das ist eine bewusste Design-Wahl
  (Zahlen sind hier keine Counts, sondern direkte Modusnummern), aber sie
  kollidiert mit `vim.v.count`-Eingabe für andere Bindings in derselben
  Session (z. B. `3<C-o>` funktioniert, weil `3` vor `<C-o>` als Count
  interpretiert wird, aber ein alleinstehendes `3` wählt Modus 3). Kein Bug,
  aber erwähnenswert als potentielle Verwirrung.
- **`f` (filter)**, **`/` (fuzzy search)**, **`S`/`L`/`X`** (trail save/load/delete)
  — öffnen `kit.input`/`kit.select`-Prompts. Für `L`/`X` (Liste gespeicherter
  Trail-Namen) gibt es Fuzzy-Matching via `kit.picker` nur für die
  `/`-Suche; `L`/`X` selbst sind einfache `kit.select`-Listen ohne
  Live-Filterung des Namensfelds — bei vielen gespeicherten Trails könnte das
  unhandlich werden (kleinere fehlende Komfort-Idee).

Autocompletion für Ex-Commands (`:DocMap`, `:DocBrowse` in
`bindings/usrcmds/init.lua:250-318`): **vorhanden und mehrstufig** — Ebene 1
vervollständigt Aktionsnamen (`graph|why|dot|...`), Ebene 2 vervollständigt
tatsächlich vorhandene Modulnamen aus der IR (nur wenn die Root schon
gescannt wurde, um einen Tab-Trigger-Vollscan zu vermeiden), Ebene 3 für
`:DocMap graph`/`dot` vervollständigt `deps|calls`. Das ist ein Pflicht-Niveau,
das andere Plugins mit Free-Text-Argumenten kopieren sollten.

Fehlende Flags/Optionen, die beim Lesen auffielen:
- `:DocMap churn [range]` und `:DocMap diff [ref]` bekommen keine
  Completion für Git-Refs/Ranges (im Gegensatz zu Modulnamen) — nachvollziehbar
  angesichts der Git-Ref-Vielfalt, aber `git branch`/`git tag`-basierte
  Vorschläge wären möglich.
- Keine `<Plug>`-Mappings für die `DocBrowse`-Keys — wer einzelne Aktionen
  (z. B. `goto_source`) aus einem anderen Kontext heraus binden möchte, muss
  über `opts.keys` konfigurieren, es gibt keinen direkten API-Call für
  einzelne Handler außerhalb einer offenen Browser-Instanz.

## Ideen für andere Plugins

- **Generischer `Registry`-Baustein für "wer ist zuständig für X"**, ausgelagert
  aus `lang_registry.lua`s Muster (Registrierung per Selbst-Require, deterministische
  Reihenfolge, `reset()` für Tests) — direkt wiederverwendbar für jedes Plugin,
  das mehrere Backends/Filetypes/Adapter unterstützen soll (z. B. eine
  generische `lib.nvim.registry`-Utility).
- **Ein `bindings/keymaps.resolve()`-artiges generisches Override-Modul** in
  `lib.nvim`: nimmt `defaults: {id, keys}[]` + `overrides` + `notify` und
  liefert eine validierte, aufgelöste Liste — jedes Plugin mit
  konfigurierbaren Buffer-Keymaps (browse.nvim, picker-artige Plugins) könnte
  das statt eigener Ad-hoc-Logik nutzen.
- **Ein eigenständiges "Doku-Drift-Checker"-Konzept für andere Ökosysteme**
  (siehe `docs/FRAMEWORK_CONVENTIONS.md`): Layer-1-Sprachparser + Layer-2
  "Ecosystem Convention Recognizer" (lazy.nvim-Specs, Next.js-Routing) als
  generisches Zwei-Schichten-Muster — ließe sich auf andere Analyse-Tools
  übertragen (z. B. ein eigenes Plugin, das nvim-Config-Strukturen selbst
  nach Konventionen scannt, unabhängig von documentation.nvim).
- **Ein eigenständiges "structural duplicate finder"-Miniplugin**, das nur
  `fn.shape`-Hashing über Treesitter-Subtrees macht und als generisches
  CPD-Tool (nicht an documentation.nvim gebunden) für beliebige Lua-Bäume
  läuft — der Algorithmus in `duplicates.lua` ist klein, klar abgegrenzt und
  ließe sich als eigenständiges `dedupe.nvim` extrahieren.
- **Ein generischer "lokaler Loopback-Server mit `VimLeavePre`-Lifecycle
  und Shape-validierten Routen"-Baustein**, abgeleitet aus `editor/serve.lua` +
  `docs/SECURITY.md`s Prinzipien (127.0.0.1-only, Port 0, strikte
  Input-Validatoren) — als wiederverwendbares `lib.nvim`-Utility für jedes
  Plugin, das eine `file://`-Seite mit dem Editor verbinden will.
- **Ein "Undo/History-Stack mit Sentinel-Clear"-Pattern** als generisches
  `lib.nvim.ui.kit`-Utility, abgeleitet aus `browse/init.lua`s `go`/`CLEAR`/
  `history_step` — jedes Plugin mit browser-artiger Navigation (Back/Forward,
  Filter-Persistenz über Sprünge hinweg) müsste dieses Muster sonst neu
  erfinden.

Anmerkung zur Tiefe des Repos: Der Kern (`core/`, `bindings/`, `editor/browse/`)
ist ungewöhnlich gut dokumentiert — praktisch jede nicht-triviale Entscheidung
trägt einen Kommentar mit begründetem "warum nicht naiv". `docs/FRAMEWORK_CONVENTIONS.md`
ist explizit als unverifizierter Vorschlag markiert ("Nothing below has that
[verified] treatment") und selbst als "nicht jetzt, nicht geplant" eingestuft
— ehrlich als Ideen-Dokument, nicht als Architektur-Commitment.
