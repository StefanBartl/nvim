# Handover — CDX-Kommentar-Sweep über nvim-config + alle Plugins

## Table of content

  - [Ziel](#ziel)
  - [Vorgehen (User-Entscheidungen)](#vorgehen-user-entscheidungen)
  - [Der `--- CDX:`-Tag](#der----cdx-tag)
  - [Wohin welches Wissen](#wohin-welches-wissen)
  - [Fortschritt](#fortschritt)
  - [Relocation-Log](#relocation-log)
  - [Wiederkehrende Fund-Muster](#wiederkehrende-fund-muster)

---

## Ziel

Jede Datei in der nvim-config und in allen 31 Plugin-Repos durchgehen. Im
Source-Code soll in den Kommentaren **nur stehen, was für genau diesen Platz
wichtig ist**. Alles andere:

- **Auffällig, aber Urteilssache** → `--- CDX:`-Tag setzen (nicht sofort fixen)
- **Klarer Fehler / Redundanz / Sprachverstoß** → direkt fixen
- **Wichtiges Wissen, das nicht in den Source gehört** (Design-Begründung,
  Messwerte, Neovim-/Lua-Mechanik) → **direkt umziehen** in Plugin-`docs/`
  bzw. WKDBooks, dann im Code nur ein Ein-Zeilen-Pointer

## Vorgehen (User-Entscheidungen)

- **Kalibrier-Häppchen zuerst:** ein Bereich komplett nach meinem Urteil, dann
  User-Review + Kalibrierung, dann Rest. Erstes Häppchen: `lua/autocmds/`.
- **Direkt umziehen:** Wissen wandert gleich in die Ziel-Datei, Commit/Push
  auch in die WKDBooks. Handover verweist dann nur noch drauf.
- Nie mehr als 1 Agent gleichzeitig. Antworten deutsch, Code/Kommentare englisch.
- Nach jedem Häppchen: stylua/luacheck (falls vorhanden), commit, push auf `main`.
- Keine Claude-Co-Authorschaft in Commits.

## Der `--- CDX:`-Tag

Format: `--- CDX: <kurze Beschreibung des Funds>` (englisch, drei Striche =
LuaLS-Doc-Kommentar), an der auffälligen Stelle.

**User-Kalibrierung (nach Häppchen 1):**
- **`--- CDX:` einheitlich** — bestehende eigene Marker (`-- FIX:`, `-- AUDIT:`,
  `-- SUPERSEDED:`) werden zu `--- CDX:` umbenannt **und** ins Englische
  übersetzt. Ausnahme: `SUPERSEDED:` bleibt sinnvoll wo es echt „ersetzt durch
  X" heißt — dann `--- CDX: SUPERSEDED …`.
- **Trimm-Härte: moderat** — klare Redundanz/Doppelung/Sprachverstöße fixen,
  überlange Rationale kürzen aber Substanz behalten, USAGE-Blöcke zu
  Parameter-Listen eindampfen, Zweifelsfälle taggen.
- **Toter Code: gleich löschen wenn eindeutig** (kein Aufrufer im ganzen Repo,
  keine externe API). Zweifel → taggen. Im Commit vermerken.
- **Redundante Kommentarzeilen entfernen** wenn sie nichts über Nachbar-Zeilen
  (Sektionskopf, `desc`, Funktionsname) hinaus sagen.

## Wohin welches Wissen

Alle drei WKDBooks-Ziele liegen im **selben Repo** `StefanBartl/WKDBooks`
(`E:/repos/WKDBooks/`), ein Commit deckt alle ab.

| Wissensart | Ziel |
| --- | --- |
| Plugin-spezifische Design-Begründung, Messwerte, „warum so gebaut" | `E:/repos/WKDBooks/Development/wkdbook-myplugins/<plugin>.nvim/NOTES/` **oder** das Plugin-eigene `docs/` |
| Neovim-Mechanik (Event-Timing, API-Eigenheiten, `on_key`, `:split`-Semantik …) | `E:/repos/WKDBooks/Development/wkdbook-Neovim/MyNotes/` |
| Lua-/LuaLS-Mechanik | `E:/repos/WKDBooks/Development/wkdbook-Lua/` (passende Unterordner: `LuaLanguageServer/`, `Async/`, …) |
| Nicht-`vim.health`-relevante Config-Interna | nvim-config `docs/` |

wkdbook-Neovim/MyNotes-Stil: deutsch, informell, Emoji-Header erlaubt,
verknüpft das Allgemeinwissen mit dem konkreten Auslöser-Fall.

---

## Fortschritt

> **Häppchen 1–33 sind abgeschlossen und archiviert.** Die vollständigen
> Fund-Protokolle (Details, Datei-Listen, jede `--- CDX:`-Begründung, alle
> Commit-Hashes) liegen in
> [`cdx-comments-docs.md`](../personal/All/FINISH/ERLEDIGT/cdx-comments-docs.md).
> Hier nur ein Ein-Zeiler pro Häppchen, damit dieses Handover schlank bleibt.
> Laufende Arbeit (aktuell lib.nvim, Häppchen 34) steht wie gewohnt unten in
> voller Länge, solange sie nicht abgeschlossen ist.

**Standing-Reminder (aus dem früheren „Danach offen"-Zwischenstand):** bei
jedem Plugin-Repo-Häppchen die which-key/machine-readable-Phrasen in
`keymaps.md`/`README.md`/`FEATURES/*`/`doc/*.txt` mitprüfen — der
`BINDINGS.md`-Cleanup selbst war zum Zeitpunkt von Häppchen 25 für alle
14 relevanten Repos bereits erledigt.

1. **`lua/autocmds/`** (16 Dateien) — AUDIT/FIX-Marker vereinheitlicht;
   nach User-Kalibrierung 1 toter Fn gelöscht (`snorm_pattern`).
2. **`lua/bindings/mappings/`** (23 Dateien) — toter auskommentierter Code
   an 6 Stellen gelöscht, Deutsch→Englisch an user-sichtbaren Stellen.
3. **`lua/bindings/usrcmds/bindings_explorer/`** (13 Dateien, außer
   `drift.lua`) — komplett Deutsch→Englisch (−72 Z.); 1 toter Pfad getaggt
   (`BND-05`, Funktionsentscheid offen).
4. **`lua/bindings/usrcmds/case/`** (39 Dateien, 11.295 Z., casedesk) —
   alle noch deutschen Code-Kommentare übersetzt; deutsche User-Strings/
   Datenmaps/„Paket N"-Referenzen bewusst behalten.
5. **`drift.lua`** (2812 Z., reiner Prosa-Trim) — Header 210→46 Z., Rest
   2665→2558 Z., keine `--- CDX:`-Tags nötig.
6. **`usrcmds/`-Rest + `telemetry.lua`** (6 Ziele) — Deutsch→Englisch, 2
   stale Doc-Refs gefixt (falsche Präzisionswerte, toter Link).
7. **`usrcmds/plugin_repos/`** (3 Dateien) — Header dedupliziert,
   `M.enable()`-Docstring fehlten 6 von 10 Subcommands (gefixt).
   **`lua/bindings/` damit komplett durch (87/87 Dateien, 22.774 Z.).**
8. **`lua/config/` kleine Ordner + `ui_open.lua`** (16 Ziele) — **echter
   Funktionsbug getaggt, nicht gefixt:** eine noice-catch-all-Route killt
   alle nachfolgenden Routes; 3 KI-Assistent-Configs bestätigt verwaist
   (bewusst auskommentiert); 3 Wissens-Umzüge nach WKDBooks.
9. **`lua/config/harpoon/`** (12 Dateien) — `HardeningState`-Typ fehlten 2
   reale Felder (gefixt), 1 toter Typ gelöscht, 1 Tuning-Doku nach
   `docs/NOTES/Harpoon.md` ausgelagert.
10. **`lua/config/neotest/`** (21 Dateien) — **2 echte Laufzeitbugs
    getaggt, nicht gefixt** (crasht bei `<leader>ntS`; TS-Root-Detection
    läuft nie). Adapter-Split-Brain war bereits als Plan dokumentiert, nur
    eine Lücke ergänzt.
11. **`lua/config/neotree/`** (29 Dateien) — 2 tote Module gelöscht, 2
    `@types`-Fixes (Methoden fälschlich als `boolean`-Felder typisiert),
    `event_handlers/README.md` komplett neu geschrieben (beschrieb 4
    Handler, nur 1 existiert noch). **`lua/config/` damit komplett durch.**
12. **`lua/plugins/` Top-Level + 3 kleine Ordner** (22 Dateien) —
    doppelter `setup()`-Call entfernt (`neotest.lua`), toter
    auskommentierter Code entfernt, 1 Wissens-Umzug nach WKDBooks.
13. **`lua/plugins/personal/` + `lua/plugins/ai/`** (8 Dateien) — größter
    Fund: 95-zeiliger deutscher Duplikat-Kommentar (hover.nvim-Spec) auf
    20 Z. gekürzt; falscher `require`-Pfad in `avante.lua` gefixt.
    **`lua/plugins/` damit komplett durch.**
14. **`lua/wkdoptions/` ohne `hl_config/`** (26 Dateien) — 2 tote Module
    gelöscht (eines bereits in `Merged_Finished.md` als Redundanz
    dokumentiert, nie physisch entfernt), 1 echter `@types`-Fix.
15. **`lua/wkdoptions/hl_config/`** (38 Dateien, ~4940 Z.) — ~150 Z. toter
    „Pre-compiled Pattern System"-Code gelöscht, mehrere `@types`-Fixes,
    **2 echte Bugs getaggt** (Regex-Capture-Verwechslung in
    `extract_lua_field_key`, nie gesetztes `cfg._base_symbol`).
    **`lua/wkdoptions/` damit komplett durch.**
16. **`lua/wkdnvchad/`** (41 Dateien, ~4470 Z., Statusline/Tabufline/
    Theme-Switcher) — **3 echte Bugs getaggt, nicht gefixt** (totes
    lspbased-Statusline-Modul; kaputter `custom/`-Subtree; eager-`require`
    macht einen Lazy-Load-Kommentar falsch). **`lua/wkdnvchad/` damit
    komplett durch.**
17. **Kleinteile** (`startup/`, `themes/`, `nvchad/`, `@types/`, `after/`,
    root `init.lua`, `scripts/`) — winzige Fixes. **Gesamter `lua/`-Baum
    der nvim-config damit durch.**
18. **recommender.nvim** (Repo 1/31) — 8 Dateien geändert, 3 `--- CDX:`
    (u.a. Telescope-only-Limitierung bricht mit replacer.nvims
    fzf-Backend), 2 Doc-Staleness-Fixes.
19. **sessions.nvim** (Repo 2/31) — 7 Dateien geändert, 1 `--- CDX:`
    (Dirty-Tracking nur aktiv wenn `autosave = true`).
20. **dap.nvim** (Repo 3/31) — 1 toter Fn gelöscht, 4 `--- CDX:` (u.a.
    Browser/JS-Config-Ladereihenfolge-Abhängigkeit, tote
    Session-Tracking-API), Doc-Staleness (`which_key.lua` gelöscht, Docs
    nicht nachgezogen).
21. **cmdlog.nvim** (Repo 4/31) — 24 Dateien geändert, mehrere
    „N statt N+1"-Doc-Fixes, mehrfach duplizierte Rationale gestrafft.
22. **emojis.nvim** (Repo 5/31) — ~3625 Z. Lua, sauber durchgegangen.
23. **diff.nvim** (Repo 6/31) — ~2400 Z. Lua, sauber durchgegangen.
24. **fileops.nvim** (Repo 7/31) — ~4940 Z. Lua, sauber durchgegangen.
25. **open.nvim** (Repo 8/31) — Agent während der Apply-Phase gestoppt,
    seine 13 Änderungen verifiziert + committet, danach vollständiger
    Nachcheck (24 Dateien). **Vollständig abgeschlossen.**
26. **debugging.nvim** (Repo 9/31) — *[Ausnahme-Session: 2×3 parallele
    Agents]* tote Typfamilie gelöscht, 2 `--- CDX:` (u.a.
    `if considered_relevant or true` = wirkungslose Prüfung).
27. **filetree.nvim** (Repo 10/31) — 130 Lua-Dateien geprüft, **3 echte
    Funktionsbugs gefixt** (u.a. „Enter committet Suche als Filter"
    funktionierte nie); Liste 1 (`NVIM_CFG_CLEANUP`) für filetree.nvim
    damit inhaltlich abgeschlossen.
28. **github_stats.nvim** (Repo 11/31) — **1 echter Bug gefixt**
    (Fehlerhandler zeigte immer „nil"); komplette tote
    Dashboard-Architektur (88 Z.) + ein zweites totes
    Last-Fetch-Tracking-System gelöscht.
29. **hover.nvim** (Repo 13/31) — außergewöhnlich sauberes Repo, nur
    Doc-Staleness-Fixes (u.a. „Two ways" → tatsächlich drei seit einem
    alten Fix-Commit, der die Doku-Zeile nie nachzog).
30. **gopath.nvim** (Repo 12/31) — ergiebigstes Häppchen der
    Ausnahme-Session: **6 echte Bugs gefixt** (u.a. nie greifende
    Glob-Pattern-Root-Marker, Cache unter Literal-Key `0` statt echter
    Buffer-Nr., Off-by-one bei Cursor-Spalte); 1 totes Modul komplett
    gelöscht. *Ausnahme-Session (2×3 parallele Agents) damit
    abgeschlossen, zurück zu 1 Agent gleichzeitig.*
31. **images.nvim** (Repo 14/31) — ungewöhnlich gut gepflegt, kleiner
    Ertrag; 1 echter Fund (stale Tool-Dependency in `docs/install.json`).
32. **insights.nvim** (Repo 15/31) — Vorgänger-Agent brach am
    Sitzungslimit ab, 13 unkommittete Dateien verifiziert + 1
    Agentenfehler korrigiert (Java-Regex-Pattern) + verbucht. Doku-Nachzug:
    13 statt „fünf Tools".
33. **language.nvim** (Repo 16/31) — Build ist fertig; Hauptertrag waren
    stehengebliebene „Phase-N"-Bauzeit-Notizen, die dem fertigen Code
    widersprachen. 2 `--- CDX:` (immer-konstante Debounce-Ternaries).

### Häppchen 34 — lib.nvim (Plugin-Repo 17/31) — **SUB-HÄPPCHEN 1–4/8 erledigt, PAUSIERT**

lib.nvim ist mit **283 Quell-Dateien** (+ 49 Tests, 51 Docs) das größte Repo.
Wird wie `lua/bindings/` in Sub-Häppchen abgearbeitet, je 1 Agent. **Sweep
pausiert nach Sub 4 (User-Ansage) — Fortsetzung bei Sub 5.** Plan:
1. ✅ `lua/lib/lua/` + Top-Level/@types/config/nvim_usrcmds/strategies
2. ✅ `lua/lib/nvim/bindings/` (composer)
3. ✅ `lua/lib/nvim/cross/`
4. ✅ `lua/lib/nvim/fs/`
5. `lua/lib/nvim/buf_win_tab/` + `window/` + `buffer/`  ← **HIER WEITER**
6. `lua/lib/nvim/ui/` (kit, 20 Dateien)
7. `lua/lib/nvim/` Rest (deps, logger, system, harvest, progress, notify, …)
8. `TESTS/` + `doc/` + `docs/`

**Sub-Häppchen 4 — erledigt** (`lua/lib/nvim/fs/`, Commit `95e9be5`,
gepusht, `pull --ff-only` sauber). Größter Teilbaum (52 Dateien gelesen, 13
geändert), wieder überdurchschnittlich sauber. Kein toter Code gelöscht.

- **`@types`-Fixes:** „sucess"/„in cade of"-Tippfehler; `write.lua` fehlte
  `---@meta` (alle Schwester-`@types` haben es); Klasse hieß `Lib.FS.Write`
  statt `Lib.Fs.Write` (Casing bricht Konvention) → umbenannt + Feldverweis
  mitgezogen.
- **Changelog-Narrative in Headern gekürzt** (das Muster hier): `is_subpath`
  („an earlier version used `package.config`… returned false for every
  subpath on Windows"), `is_valid_filename` („to close a gap in
  create_entry…"), `collect_recursive` (`====`-Banner mit
  „plenary/libuv research this was born from", „used to live here as a
  private copy"), `watch` (neo-tree-Archäologie). Jeweils die echte
  Invariante / der Async-Close-Grund behalten.
- `is_readable_file` — irreführendes `-- Ensure the path is valid` (prüft nur
  Lesbarkeit) → echter Doc + Hinweis „true auch für Verzeichnis".
- `path_shorten` — `strlen`-Doc behauptete utf8-Fallback, Rumpf ist `return #s`
  → auf Bytelänge korrigiert (Breiten-Budget ist byte-basiert).

**`--- CDX:` gesetzt:**
- **`fs/ignore/list/init.lua:62` — echter Logikbug:** Pattern
  `package%.lock.json` matcht „package.lock.json", npm's Lockfile heißt aber
  `package-lock.json` → Regel feuert nie. Gemeint war `package%-lock%.json`.
- **`fs/write/async/init.lua` — Verhaltens-Bug:** hängt kein abschließendes
  Newline an, obwohl das synchrone „counterpart" `to_file` (und `append`) es
  tun; `write/batch` erbt die Lücke. Angesichts der „counterpart"-Formulierung
  wohl unbeabsichtigt.
- `fs/@types/{init,query,transform}.lua` — veraltetes Scaffolding
  (`Lib.Fs`/`Lib.Fs.ALL`/`Lib.Fs.Query`/`Lib.Fs.Transform`): es gibt kein
  `lib.nvim.fs`-Aggregatmodul, die Gruppierung path/query/transform/write ist
  fiktiv; `Lib.Fs.ALL.dedup` benennt kein Modul. Echte flache Oberfläche:
  `all_functions.lua`. Analog `Lib.Cross.ALL` (Sub 3) getaggt statt gelöscht.
  Die real referenzierten `Lib.Fs.*Opts`/`Lib.Fs.Path`-Klassen bleiben.
- `fs/polymorphic_rootresolver/@types` — `RootResolverCfg` ohne `Lib.Fs.`-
  Präfix (bricht Konvention), aber public in `docs/API/filesystem.md` →
  Rename mit Rippeleffekt, nur markiert.

**Memory-Subtlety geprüft:** `polymorphic_rootresolver` löst Root **pro
Aufruf** aus `arg` auf, cwd nur als Fallback — kein Kommentar behauptet
Gegenteiliges, nichts zu flaggen.

**Für Sub-Häppchen 8:** `docs/API/filesystem.md` — `polymorphic_rootresolver`
erwähnt `cfg.markers` aber nicht `cfg.resolve`; „28 submodules"-Zahl in Z.1
verifizieren; falls `RootResolverCfg`-Rename je kommt, Z.88 mitziehen.

**Für einen späteren WKDBooks-Pass** (Agent hat nichts committet, nur notiert —
ortsunabhängige Mechanik, die in Headern anfällt): `vim.fn.*`→`E5560` in
Fast-Event-Kontexten; Windows-8.3-Kurznamen (`STEFAN~1`) brechen
`vim.fn.glob`; `io.open` „w"/„r" ist Text-Modus (CRLF-Wandlung) vs. libuv
`fs_write` byte-exakt; `fs_event` feuert mehrfach pro Save + Handle-Close ist
async.

stylua ok, luacheck 0/0 (31 Dateien), `LIB_TESTS_OK`. Ohne Co-Authored-By.

**Sub-Häppchen 3 — erledigt** (`lua/lib/nvim/cross/`, Commit `cc21351`,
gepusht, `pull --ff-only` sauber). 29 Dateien. Bestätigt das Muster: die
Arbeit steckt fast nur in `@types` + alten AI-Boilerplate-Headern; der
Ausführungscode ist praktisch kommentar-rein.

- **`@types/init.lua` — Signaturen wichen vom Code ab:** `Lib.Cross` fehlten
  `is_windows/is_wsl/is_macos/is_linux/is/executable` komplett, veraltetes
  `clipboard`-Feld drin (existiert nicht). `Lib.Cross.Uv`: `spawn_command`
  gibt `{ spawn_project_command = … }` zurück (nicht `fun(argv)`),
  `spawn_shell_command` nimmt `(cmd, args, opts)`, `wait_until` fehlte der
  `cb`-Param. Alle korrigiert.
- `spawn_capture/@types` — `stdin?`-Feld fehlte in der `@class` (war inline da).
- `uv/spawn_command.lua` — ~30-Zeilen-`Features:`/`Design decisions:`-
  Boilerplate-Header eingedampft, `SECURITY:`-Block erhalten. `spawn_shell_command`
  „Usage example" raus.
- `fs/separators/normalize/init.lua` — falscher Assert-Modul-Tag
  `[lib.nvim.normalize.os_sep]` → korrekter Pfad.
- `run/init.lua` — `-- FIX: Optimize, doc`-Marker raus (Modul ist dokumentiert),
  Header zu echter `---`-Doc.
- `fs/expand_path` — Header nannte nur `$VAR`, Code macht auch `${VAR}`.
- `fs/_cwd`, `uv/fs` — plain `--` → `---`; `uv/fs` dokumentiert jetzt, dass es
  `fs._cwd` bewusst dupliziert.

**`--- CDX:` gesetzt:**
- `@types/init.lua` `Lib.Cross.ALL` — unreferenziert, listet `run_blocking`
  **zweimal** (zweiter Eintrag ist eigentlich `run_argv.run_blocking`,
  Copy-Paste), abgelöst durch `Lib` in `all_functions.lua`.
- `@types/clipboard.lua` `Lib.Cross.Clipboard` — unreferenziert, es gibt keine
  `cross.clipboard`-Tabelle (Modul ist `cross.copy_to_clipboard`, nackte Fn).
- `fs/separators/normalize/init.lua:14` — eigene Windows-Erkennung statt
  `cross.platform.is_windows`, prüft `os_uname().version` statt `sysname` —
  inkonsistent mit dem Rest von `cross/`.

Keine echten Logik-Bugs (Spawn/Retry/Timeout-Pfade sind sorgfältig).

**Für Sub-Häppchen 8:**
- `run/init.lua` `run_detached`-Doc und `reveal_in_fm/init.lua`
  `spawn_helper`-Doc enthalten denselben ~10-Zeilen-Text zu libuv
  `DETACHED_PROCESS` / Konsole-vs-GUI (load-bearing Windows-Wissen, aber über
  2 Dateien dupliziert) → in ein Docs-File auslagern + Pointer.
- `docs/API/cross-platform.md` unvollständig: `fs.mutate` fehlen `symlink`/
  `hardlink`; `run.env` fehlt `M.array(vars?)`.

stylua ok, luacheck 0/0 (29 Dateien), `LIB_TESTS_OK`. Ohne Co-Authored-By.

**Sub-Häppchen 2 — erledigt** (`lua/lib/nvim/bindings/`, Commit `1dd5f36`,
gepusht, `pull --ff-only` sauber). 28 Dateien, überdurchschnittlich sauber.

- **`@types`-Enumerationen unvollständig** (das Kernmuster hier): `Lib.AutoCmd`
  fehlten `registered`/`by_event`/`docs`; `Lib.UserCmd.Composer.Handle` fehlten
  die Fluent-Builder-Methoden `:count`/`:buffer`; `DocsOpts`/argtype-Alias
  hatten doppelte Beschreibungszeilen. → alle gegen die reale `M`-Tabelle
  abgeglichen. **Für die restlichen lib.nvim-Sub-Häppchen: jede `Lib.*`-
  `@class` gegen das Modul-`M` prüfen.**
- **`====`-Banner-Header** in `autocmd/init.lua`, `keymap/set.lua` → `---@module`;
  `autocmd/augroup.lua` hat noch einen (trivial, fürs Aufräum-Häppchen).
- Fehlplatzierte Rationale-Blöcke in `autocmd/init.lua` an die richtige
  Funktion (`M.group`/`M.get_augroup`) verschoben; doppelter aus `augroup.lua`
  kopierter Block ersetzt.
- `autocmd/dispatcher/init.lua` — Inline-Mikrobenchmark-Zahlen (`~30us` etc. +
  Pfad zum Bench-Skript) → auf die Schlussfolgerung + README-Verweis eingedampft.
- Toter auskommentierter `---@param`-Block in `keymap/set.lua` gelöscht.
- Stale Changelog-Notizen in Kommentaren: „`WINDOW` … missing from this list"
  (steht drin), „pre-Phase-6 behavior" → entfernt.
- **Struktur:** Inline-`---@class Lib.UserCmd.Composer.Node` aus `tree.lua`
  nach `composer/@types/` verschoben (Konvention `conventions.md`).

**`--- CDX:` gesetzt:**
- `keymap/modifier/init.lua` `capture()` — konsultiert nur Tier-1-
  Deklarationen unter Modus `"n"`, obwohl `M.declare(mode, …)` beliebige Modi
  annimmt und speichert. Ganzes Feature ist normal-mode-only (`resolve_target`/
  `setup` hardcoden `"n"`), also matcht `declare("i"/"x", …)` still nie —
  latenter Bug / toter Parameter.

**Nicht angefasst:** `format.lua` `arg_token` (redundanter `if/else`-Zweig,
identisches Ergebnis — Code-Logik, kein Kommentar); `docgen.lua` `cell()`
dupliziert `docs_util.cell` (Konsolidierung = neue Cross-Modul-Abhängigkeit);
`dispatcher/init.lua` closure-lokale `Registration`-Klasse (Verschieben zu
riskant für Kommentar-Sweep).

**Für Sub-Häppchen 8:** `doc/lib.nvim-composer.txt` nutzt in USAGE
`require("replacer").prompt()`, `composer/init.lua`-Doc nutzt
`.replace_prompt()` — beide fiktiv, aber inkonsistent; angleichen.

Kein Deutsch, kein toter Code, keine Smart Quotes, keine `require`-Pfad-Bugs,
keine `X and CONST or CONST`-Ternaries in diesem Scope.

stylua ok, luacheck 0/0 (28 Dateien), `LIB_TESTS_OK`. Ohne Co-Authored-By.

**Sub-Häppchen 1 — erledigt** (Commit `524ec4d`, gepusht, `pull --ff-only`
sauber). Teilbaum war **überdurchschnittlich sauber** — kaum Deutsch, keine
Smart Quotes, konsistenter House-Style. Funde konzentriert auf:

**Direkte Fixes:**
- `lua/lib/lua/time/diff/init.lua` + `@types/init.lua` — **Doc widersprach
  Code:** Header/USAGE/@types behaupteten `require("lib.lua.time.diff")`
  liefere eine Instanz (`diff.start()`); das Modul ist eine **Factory**,
  korrekt ist `require(...)()`. An 4 Stellen gefixt. „Technical Notes"-Wall
  (Benchmark, Umrechnungstabelle, Limitations-Listen — alles im README
  dupliziert) getrimmt.
- `lua/lib/lua/memo/memo.lua` — toter auskommentierter `---@field memoize2`;
  copy-paste-falscher `memoize2`-Docstring korrigiert; `@types` fehlte das
  (dokumentierte) `memoize2`-Feld → ergänzt.
- `lua/lib/lua/lazy/init.lua` — Boilerplate-Header + „Design goals"-Wall auf
  Param-Liste; `LAZY.require`-USAGE zeigte ein nicht existierendes 2. Argument.
- `lua/lib/@types/all_functions.lua` — „corrent" → „current" (4×), verirrtes
  `-` in Feldsignatur, kaputter Satz neu formuliert.
- `lua/lib/health.lua` — doppelter `PROBE`-Eintrag `"lib.nvim.ui.kit"`; falscher
  Kommentar „one representative module per namespace" (Liste hat immer mehrere).
- `lua/lib/lua/json/decode/to_string_array.lua` — veralteter Header (Code
  existiert nicht) neu geschrieben.
- `lua/lib/lua/memo/lru.lua` — eine deutsche Zeile → Englisch.
- `lua/lib/nvim_usrcmds/{@types,actions}.lua` — stale `@see`-Referenz;
  `-- FIX:` → `--- CDX:`.

**`--- CDX:` gesetzt:**
- `lua/lib/lua/strings/init.lua` — **echter Logikbug:** `M.normalize_ws =
  require("lib.lua.strings.links").normalize_ws` → `links` hat keine solche
  Funktion, Ausdruck ist `nil` und überschreibt das direkt darüber korrekt
  zugewiesene `core.normalize_ws`. Typ ist deklariert, Laufzeit ≠ Typ.
- `lua/lib/lua/lazy/init.lua` — `LAZY.typed` byte-gleich zu `LAZY.require`,
  keine Caller, undokumentiert. Löschkandidat, aber geteilte Dependency → getaggt.
- `lua/lib/@types/init.lua:7` — `Lib.Modules` ohne `---@type`-Referent,
  abgedriftet, vermutlich durch `Lib` (in `all_functions.lua`) abgelöst.
- **3× `vim`-Leck in `lib.lua.*`** (`memo/memo.lua` `vim.inspect`,
  `json/decode/to_string_array.lua` `vim.split`, `time/diff/init.lua`
  `vim.uv.hrtime`) — `architecture.md` sagt `lib.lua.*` sei editor-unabhängig;
  Schwestermodule vermeiden es. Ein Ausgliedern in ein eigenes `lib.lua`-Repo
  (in `architecture.md` als Ziel) würde daran scheitern.

**Für das Docs-Sub-Häppchen (8) vorgemerkt — dieselben Fehler in READMEs:**
- `lua/lib/lua/time/diff/README.md` — `require("lib.lua.time.diff")` →
  `require("lib.lua.time.diff")()`.
- `lua/lib/lua/lazy/README.md` — „Every call to require(...) creates an
  independent timer instance" ist ein Textbaustein-Fehler (falsches Modul).

**Bewusst nicht angefasst:** `@types/luassert.lua` (langer, aber konkret-
technischer Essay), `strategies/{control,telemetry_wrap}.lua` (tragende
„why this exists"-Docs), `nvim_usrcmds/autocmds.lua` (Rationale eng am Code),
`lua/diff/myers.lua` (Modulname vs. DP-LCS-Inhalt — selbst dokumentiert).

stylua ok, luacheck 0/0 (349 Dateien), `LIB_TESTS_OK`. Ohne Co-Authored-By.

Offene Aufräum-Punkte aus dem Sweep, die bewusst NICHT gefixt wurden (jeweils
`--- CDX:` im Code + im jeweiligen Häppchen dokumentiert) — eigene
Autorenentscheidung nötig, siehe Häppchen 8/9/10/12/15/16:
- `config/noice/init.lua` catch-all-Route dead-codet alle nachfolgenden Routes
- `config/neotest/whichkey/init.lua:69` `<leader>ntS` → nicht-existente Funktion
- `config/neotest/debug/init.lua` TS-Root-Detection läuft nie
- `config/harpoon/preview.lua` `require` auf nicht-existentes Modul
- `hl_config` 5 Bugs (u.a. `extract_lua_field_key` gibt Quote statt Key)
- `wkdnvchad` lspbased-Variante (`chadrc`-require kaputt), `neotest_module` tot+kaputt
- `lua/plugins/workflow.lua` 82-Z. auskommentierter `autolist.nvim`-Block
- `PERFORMANCE.md` (wkdoptions/docs) fabrizierte Benchmarks

<details><summary>Plugin-Liste</summary>

buffer-ctx, cascade, casedesk, cmdlog, color_my_ascii, dap, debugging, diff,
documentation, emojis, fileops, filetree, github_stats, gopath, hover, images,
insights, language, lib, lsp, markdown, mdview, open, pdfport, pickers,
recommender, replacer, reposcope, runtime-analysis, sandbox, sessions, spotlight
(alle unter `C:/repos` bzw. `E:/repos`). Nativ zusätzlich: docmap-desktop.

</details>

---

## Relocation-Log

Format: `Quelle → Ziel — was`

- `lua/autocmds/explorer-singleton.smoke.lua` (+ `explorer-singleton.lua` Header)
  → `wkdbook-Neovim/MyNotes/WinEnter-frisches-Fenster-Timing.md` (neu) — die
  Mechanik „`WinEnter` sieht bei frisch erstellten/gesplitteten Fenstern kurz
  den Buffer des Vorgängerfensters; `:split` klont erst den fokussierten
  Buffer". Stand vorher als ~12-Zeilen-Kommentar 2× im Code, jetzt 3-Zeilen-
  Pointer auf die Note. Commit in `StefanBartl/WKDBooks`.
- `lua/bindings/mappings/editing.lua` (Header + 3 Doc-Blöcke)
  → `wkdbook-Neovim/MyNotes/Paste-Register-Clipboard-vim.paste.md` (neu) —
  Register-Clipboard-Umleitung (`getreg` folgt ihr nicht), Bracketed Paste
  läuft an Register+Keymap vorbei → `vim.paste`-Wrap, `vim.paste`-Phasen
  −1/1/2/3 + „Chunk-Grenze ≠ Zeilenumbruch". Header 29→11 Z.
- `lua/bindings/mappings/treesitter_structure.lua` (Header 58→18 Z.)
  → `wkdbook-Neovim/MyNotes/treesitter-textobjects-block-outer-erweitern.md`
  (neu) — `@block.outer` pro Sprache via `after/queries/*/textobjects.scm`
  erweitern, unbekannter Knotenname bricht die ganze Query.
  → **`docs/NOTES/CrossPlugin/Keymaps-Collisions.md`** neue Sektion
  „Bracket-pair motions (`[x`/`]x`)" mit dem Owner-Inventar (Neovim/lsp.nvim/
  snacks/config) + der `[b]`/`]b`-Story.

---

## Wiederkehrende Fund-Muster

Aus Häppchen 1, als Kalibrier-Referenz für die nächsten Bereiche:

1. **Deutsch in englischen Kommentaren** — v.a. eigene `AUDIT:`/`FIX:`-Marker
   und einzelne Wörter (`Debounce-Verzögerung`). → übersetzt.
2. **`-- Description:`-Zeilen, die `desc = "…"` doppeln** — direkt darüber steht
   schon eine `-- N) …`-Sektionsüberschrift, darunter das `desc`-Feld. Die
   mittlere Zeile trägt nichts bei. → entfernt.
3. **Header-Kommentar dupliziert Inline-Kommentar** — dieselbe Begründung
   einmal im `---@module`-Block und nochmal an der Code-Stelle. → Header-Version
   raus, Inline bleibt (dort gehört sie hin).
4. **Falsche `require`-Pfade in USAGE-Beispielen** — Modulname im Doc-Block
   weicht vom echten Rückgabepfad ab. → korrigiert.
5. **Kommentar widerspricht dem Code** — `enable = true, -- Disabled by default`.
   → Kommentar an den Code angepasst.
6. **Neovim-Mechanik-Tutorial im Kommentar** — `keytrans() converts raw
   terminal bytes to a readable name …`, `:split` klont den fokussierten Buffer
   … . Allgemeinwissen, nicht ortsgebunden. → gekürzt auf den ortsrelevanten
   Kern, Rest ins Relocation-Log / nach wkdbook-Neovim.
7. **Undokumentierte Config-Felder** — `defaults.lua`-Tabellen ohne
   Feld-Beschreibungen, teils schon vom User als `AUDIT: Optionen beschreiben`
   markiert. → als `--- CDX:` belassen (Beschreiben ist eigene Aufgabe).
