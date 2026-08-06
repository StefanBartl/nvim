# Personal Plugins — Checklist-Rollout

Trackt die vollständige Anwendung der Lua/Neovim-Checklisten auf jedes personal Plugin
(Quelle der Liste: [source.lua](../../../../lua/plugins/personal/source.lua) /
[list.lua](../../../../lua/plugins/personal/list.lua)). `learn-cli.nvim` ist im Quell-Repo
`disabled` und daher nicht Teil dieser Liste.

Jedes Repo liegt unter `E:\repos\<name>`. Angewendete Checklisten (immer in dieser
Reihenfolge, siehe jeweilige Datei für Details):

1. [PERFORMANCE.md](E:/repos/Notes/MyNotes/Checklists/Lua/PERFORMANCE.md) — nur bei betroffenen Hotpaths
2. [LUA_NVIM.md](E:/repos/Notes/MyNotes/Checklists/Lua/LUA_NVIM.md) — Lua-/Neovim-Regeln
3. [REVIEW.md](E:/repos/Notes/MyNotes/Checklists/Lua/REVIEW.md) — Review-Checkliste vor Merge
4. [RELEASE.md](E:/repos/Notes/MyNotes/Checklists/Lua/RELEASE.md) — Release-Gate
5. [Refactoring..md](E:/repos/Notes/MyNotes/Checklists/Refactoring..md) — Fail-late / Report-at-boundary

Ein Häkchen (`[x]`) in einer Spalte heißt: Checkliste für dieses Plugin durchgearbeitet,
Ergebnisse committet und auf `main` gepusht. Details/Abweichungen je Plugin im Abschnitt
darunter, sofern relevant.

---

## Status

| Plugin | Performance | Lua/Nvim | Review | Release | Refactoring | Committed & Pushed |
| ------ | :---------: | :------: | :----: | :-----: | :----------: | :-----------------: |
| 1. CORE / INFRASTRUCTURE, UTILITIES & SYSTEM |||||||
| lib.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| sessions.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| pickers.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| buffer-ctx.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| open.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| sandbox.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| spotlight.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| documentation.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| runtime-analysis.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 2. NAVIGATION, FILE SYSTEM, SEARCH & TREES |||||||
| fileops.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| gopath.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| replacer.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| insights.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| filetree.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| reposcope.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY |||||||
| debugging.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| dap.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| diff.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| language.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| cmdlog.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| emojis.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| github_stats.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| 4. FILE TYPES (MARKDOWN & DOCUMENTS) |||||||
| cascade.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| pdfport.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| markdown.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| color_my_ascii.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| recommender.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| mdview.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| images.nvim | [x] | [x] | [x] | [x] | [x] | [x] |

---

## Notizen je Plugin

Abweichungen, bewusst ausgelassene Punkte (z. B. kein Hotpath → PERFORMANCE.md entfällt)
und offene Punkte werden hier je Plugin ergänzt, sobald es abgearbeitet ist.

### sessions.nvim

Codebase war bereits sehr sauber (explizite `ok, err`-Rückgaben statt stiller Fehler,
kein `notify()` außerhalb der UI-Schicht/Usercmds/Picker, `@types`-Ordner, `config/DEFAULTS.lua`,
`lib.nvim` durchgängig mit Fallback genutzt, `git.lua`/`portable.lua` bereits cross-plattform).
Gefunden und behoben:

- **PERFORMANCE.md**: einziger echter Hotpath ist `sessions.statusline.component()` (wird bei
  jedem Redraw von lualine/heirline aufgerufen) — hat pro Aufruf eine neue Options-Tabelle via
  `vim.tbl_extend` gebaut; jetzt per Weak-Table pro `opts`-Referenz memoisiert. Keine weiteren
  Hotpaths im Plugin (kleine Datenmengen, seltene Events wie `VimLeavePre`/Usercmds).
- **LUA_NVIM.md**: fehlende `@class`-Kopfannotationen in 13 Modulen ergänzt (git, health, layout,
  meta, picker, portable, state, config/init, alle `bindings/*`), teils zusammen mit `@brief`.
- **REVIEW.md**: Schnell-Check und Detailprüfung durchgegangen, keine Anti-Patterns gefunden
  (kein globaler State, Buffer/Window-Handles werden validiert, Cross-Plattform-Pfade laufen über
  `lib.nvim.cross`). Kein `.stylua.toml`/`.luacheckrc` im Repo — `luacheck --globals vim` lief
  sauber (0 Warnings) über alle 17 Dateien; `stylua --check` mit Default-Config weicht vom
  bestehenden handformatierten Stil ab (u. a. ausgerichtete `@field`-Kommentare) — keine
  projekteigene stylua-Config vorhanden, daher nicht blind reformatiert, um keine Drift gegenüber
  dem etablierten Stil einzuführen.
- **RELEASE.md**: `doc/sessions.txt` hatte veraltete Angaben — `autoload`/`autosave`-Defaults
  waren vertauscht gegenüber `config/DEFAULTS.lua`, `relative_paths`/`root_remap`/`which_key`
  fehlten komplett im Config-Block, lib.nvim war fälschlich als "Optional" statt "Required"
  gelistet, und eine verwaiste `License: MIT`-Zeile stand dort ohne zugehörige LICENSE-Datei
  (jetzt entfernt). README bekam ein Table of Contents (nur Level-2-Überschriften) und eine
  korrigierte Intro-Zeile (referenzierte noch "no external dependencies", obwohl lib.nvim
  inzwischen Pflicht ist). `gh repo edit --description` aktualisiert (dieselbe veraltete
  Abhängigkeits-Aussage); Topics, Default-Branch (`main`) und leeres Homepage-Feld entsprechen
  bereits den Schwester-Plugins (lib.nvim, dap.nvim) und wurden unverändert gelassen.
  `:checkhealth sessions` war bereits grün/vollständig implementiert. `docs/ROADMAP.md` ist
  absichtlich fast leer ("Nothing currently planned") — kein verwaistes Dokument, nur aktuell
  ohne offene Punkte.
- **Refactoring.md**: Fail-late/Report-at-boundary war bereits vollständig eingehalten — alle
  `notify()`-Aufrufe liegen ausschließlich in `bindings/autocmds`, `bindings/usercmds` und
  `picker.lua` (UI-Schicht); `core.lua`, `git.lua`, `layout.lua`, `meta.lua`, `portable.lua`,
  `state.lua` geben durchweg nur Status/Fehlertext zurück. Keine Änderung nötig.

Übersprungen/nicht verifizierbar: CI-Setup (kein `.github/workflows`, keine `.stylua.toml`/
`.luacheckrc`) wurde nicht neu angelegt — außerhalb des Scopes eines reinen Checklisten-Passes
ohne expliziten Auftrag. Alles committet (`d5484e3`, `7736eb2`) und nach `origin/main` gepusht.

### fileops.nvim

Bereits das mit Abstand sauberste geprüfte Plugin bisher: `.luarc.json` (identisch zu
sessions.nvim), `.luacheckrc`, `stylua.toml` und `.github/workflows/ci.yml` (Headless-Testsuite +
stylua/luacheck-Lint) waren schon vorhanden; `luacheck lua` lief mit 0 Warnings/Errors über alle
17 Quelldateien, die Headless-Suite (`docs/TESTS/run.lua`, 6 Specs) lief grün. Durchgängig
`(ok, msg)`-Rückgaben statt stiller Fehler, keine `notify()`-Aufrufe außerhalb von
`util/notify.lua` (der dedizierten Boundary-Schicht) — Refactoring.md/Fail-late war bereits
vollständig eingehalten, keine Änderung nötig. Gefunden und behoben:

- **PERFORMANCE.md**: kein echter Hotpath über das übliche Directory-Scanning hinaus (`ops/cycle`
  füllt Arrays bereits per `acc[#acc+1]`, kein `..`-Loop-Concat) — keine Änderung.
- **LUA_NVIM.md**: alle Dateien tragen bereits `@module`; `@class`/`@brief`/`@description` fehlen
  in einigen (nur 🟡 empfohlen) — bewusst nicht nachgerüstet, um den bestehenden knappen
  Kommentarstil nicht zu verwässern. `@types`-Konvention: ein einziger konsolidierter
  `@types/init.lua` statt pro Unterordner ein eigener `types/`-Ordner — Abweichung von der
  Buchstaben-Regel in LUA_NVIM.md, aber die Datei ist sauber nach Quelldatei gruppiert und bei nur
  26 Lua-Dateien insgesamt sinnvoller als eine Fragmentierung in sechs Mini-Ordner; als bewusste
  Ausnahme belassen.
- **REVIEW.md §8 Tooling**: `stylua --check .` fand 11 Dateien mit CRLF-Zeilenenden entgegen
  `stylua.toml`s `line_endings = "Unix"` (vermutlich durch `core.autocrlf=true` bei früheren
  Commits eingeschlichen). `stylua .` normalisiert, danach `stylua --check`/`luacheck`/Testsuite
  erneut grün — reine Whitespace-Änderung, kein Logikunterschied.
- **RELEASE.md**: README hatte ASCII-Art, Badges, Schwesterplugin-Absatz (sessions.nvim) und
  Installationsblock mit explizitem `event = "VeryLazy"` bereits korrekt — nur das geforderte
  Table of Contents (nur Level-2-Überschriften) fehlte, ergänzt. `doc/fileops.txt`,
  `docs/BINDINGS.md`, `:checkhealth fileops` waren bereits vollständig und akkurat.
  `docs/ROADMAP.md` war nach einem früheren "drop completed-tasks"-Commit komplett leer (nur
  Überschrift) — das zählt als verwaist, daher mit einer echten Implemented/Planned-Übersicht
  gefüllt. `gh repo edit` gesetzt: Description, Homepage (`https://github.com/StefanBartl/
  fileops.nvim`), Topics (neovim, neovim-plugin, lua, file-management, libuv) — vorher alle leer.
  Default-Branch war bereits `main`, keine LICENSE-Datei/-Referenz vorhanden.
  Cross-Plattform-Check: keine hartkodierten Pfadtrenner gefunden (die wenigen `\\`-Vorkommen sind
  Lua-Pattern-Matches zum *Erkennen* von Trennern, keine Joins; Joins laufen konsequent über `/`,
  das libuv auch unter Windows akzeptiert).
- **Refactoring.md**: siehe oben — bereits vollständig eingehalten.
- **Bonus-Fix außerhalb der Checkliste, aber beim Lesen aufgefallen**: `features/on_hold.lua`
  rief `git rev-parse`/`git blame`/`git show` ohne `cwd` auf (lief also in Neovims globalem cwd
  statt im Verzeichnis der Datei) — bei einer Datei außerhalb des aktuellen cwd meldete
  `in_git_repo()` fälschlich "kein Repo" und die Preview blieb stumm. Auf das gleiche
  `cwd`-Pattern wie `util/git.lua` umgestellt.

Alles committet (`4b85343` docs, `8accb5f` fix, `f5c5ab9` style) und nach `origin/main` gepusht.

### spotlight.nvim

Bereits durch eine eigene, ausführliche Checklisten-Runde gelaufen (siehe
`docs/ROADMAP/Checklist.md`, `Arch&Coding.md`, `Zentral-Prinzipien.md` im Repo selbst,
Stand 2026-07-30) — dieser Pass fand entsprechend kaum noch etwas: 31 Lua-Dateien, alle mit
vollständigen `@module`/`@brief`/`@description`-Kopfannotationen und `@param`/`@return`,
durchgängig `(value, err)`-Rückgaben statt stiller Fehler, `@types/init.lua` vollständig, eigener
`config/DEFAULTS.lua` + `config/init.lua` mit Typvalidierung pro Key, `.luarc.json` (mit
`diagnostics.globals=vim`, `workspace.library`) sowie `.luacheckrc`/`stylua.toml`/CI (stylua +
luacheck + 164-Assertion-Testsuite in `TESTS/`) bereits vorhanden und grün (0 Warnings/Errors).
Cross-Plattform bereits sauber über `lib.nvim.cross.platform.is_windows` und Forward-Slash-
Normalisierung in `util/path.lua` gelöst.

- **PERFORMANCE.md**: einziger echter Hotpath ist das `matchadd()`-Rendering selbst — bewusst in
  C/Vim statt Lua gehalten (die zentrale Architekturentscheidung des Plugins, im README
  dokumentiert). Der einzige O(Datei)-Scan (`core/count.lua`, Match-Zählung/Quickfix-Filter) läuft
  bereits chunked (5000 Zeilen), nutzt `table.concat`/`t[#t+1]`, nie `table.insert`, und ist per
  `count_max_lines`/`max_entries` gedeckelt. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig mit nativem Fallback
  (`util/lib.lua`), Fehlerbehandlung strukturiert, Buffer/Window-Handles validiert (auch in
  deferred `vim.schedule`-Callbacks), Importreihenfolge eingehalten. Keine Änderung nötig.
- **REVIEW.md**: Schnell-Check und Detailprüfung sauber — kein globaler State, Single
  Responsibility pro Modul, `.luarc.json` bereits vorhanden (leicht anderes Format als
  `sessions.nvim`s `.luarc.json`, aber inhaltlich gleichwertig: `diagnostics.globals=["vim"]` +
  `workspace.library` gesetzt — nicht angeglichen, um keine funktionslose Diff einzuführen).
  **Ein Fund**: `qf.lua` (Quickfix-Filter) rief bei Trunkierung `lib.notify()` direkt auf, obwohl
  alle anderen Feature-Module (`nav.lua`, `persist.lua`) konsequent nur Status zurückgeben und das
  Melden der Fassade (`init.lua`) überlassen — Anti-Pattern-Check "notify() im Low-Level-Code".
- **RELEASE.md**: README (Englisch, ASCII-Art, Badges, Level-2-only ToC, Schwesterplugin-Absatz
  zu buffer-ctx.nvim), `doc/spotlight.txt`, `docs/BINDINGS.md`, `docs/ROADMAP/ROADMAP.md`,
  `:checkhealth spotlight` (headless getestet, läuft fehlerfrei durch), Installationsblock mit
  explizitem `event = "VeryLazy"`, Dependency auf `lib.nvim` korrekt deklariert — alles bereits
  vollständig. GitHub-Metadaten (`gh repo view`) bereits gesetzt: Description, Homepage, 15 Topics,
  Default-Branch `main`, keine LICENSE-Datei/-Referenz. Zentrale Bindings-Sammlung
  (`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/spotlight.nvim.md`)
  bereits vorhanden. Keine Änderung nötig.
- **Refactoring.md**: **Der einzige Codefix dieses Passes.** `qf.lua`s `M.fill()` notifizierte
  selbst bei Trunkierung (`quickfix.max_entries` erreicht) statt nur einen `truncated`-Boolean
  zurückzugeben; jetzt gibt `M.fill()` `(found, err, truncated)` zurück und `init.lua`s
  `M.quickfix()` (die Fassade/Boundary) entscheidet über das Melden — konsistent mit
  `nav.lua`/`persist.lua`, die dasselbe Muster bereits einhielten.

Übersprungen/nicht verifizierbar: nichts — GitHub-Metadaten, `:checkhealth` und die zentrale
Bindings-Sammlung waren alle direkt prüfbar und bereits vollständig. Alles committet (`c529cac`)
und nach `origin/main` gepusht.

### open.nvim

Ebenfalls bereits durch eine eigene, ausführliche Checklisten-Runde gelaufen (siehe
`docs/ROADMAP/Checklist.md`, `Arch&Coding.md`, `Zentral-Prinzipien.md` im Repo selbst) — dieser
Pass bestätigte, dass die dort dokumentierten Action-Items (`lib.usercmd`/`lib.cross`-Migration)
inzwischen umgesetzt sind (`platform.lua` nutzt `lib.nvim.cross.platform.is_*`,
`bindings/usrcmds.lua` läuft vollständig über `lib.nvim.usercmd.composer`) — die entsprechenden
❌-Markierungen in `docs/ROADMAP/Zentral-Prinzipien.md` sind also stale/überholt, wurden aber nicht
angefasst (Änderung an den Repo-eigenen Audit-Notizen war nicht Teil des Auftrags). 33 Lua-Dateien,
durchgängig `@module`/`@brief`/`@description`, `@param`/`@return`, `@types/init.lua`,
`config/DEFAULTS.lua` + `config/init.lua`, `.luarc.json`, `.luacheckrc`, `stylua.toml`, CI
(stylua + luacheck + headless `TESTS/run.lua`, 6 Specs) bereits vorhanden.

- **PERFORMANCE.md**: kein echter Hotpath — `:Open` läuft einmal pro Aufruf; `viewer/scan.lua`s
  Zeilen-Scan für `:Open viewer cwd` ist das Nächste an einem Hotpath, baut Ergebnisse aber bereits
  per `out[#out+1]` statt `table.insert` auf, keine `..`-Loop-Concats. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig (`lib.nvim.notify`,
  `lib.nvim.cross.*`, `lib.nvim.usercmd.composer`, `lib.nvim.harvest`), saubere Importreihenfolge,
  `custom_handlers`/`keywords` typisiert und user-konfigurierbar. Keine Änderung nötig.
- **REVIEW.md §8 Tooling**: `stylua --check` fand 12 Dateien mit CRLF-Zeilenenden entgegen
  `stylua.toml`s `line_endings = "Unix"` (derselbe `core.autocrlf`-Effekt wie bei fileops.nvim);
  `stylua .` normalisiert, danach `stylua --check`/`luacheck` (0 Warnings/Errors)/Testsuite (6/6
  grün) erneut sauber — überwiegend Whitespace, ein Fund mit echtem `collapse_simple_statement`-Delta
  in `handlers/image.lua`. `.luarc.json` bereits inhaltlich äquivalent zu sessions.nvim
  (`diagnostics.globals=["vim"]`, `workspace.library`), nicht angeglichen (kein funktionaler Gap).
- **RELEASE.md**: README (Englisch, ASCII-Art, Badges, Schwesterplugin-Absatz zu insights.nvim,
  Installationsblock mit explizitem `cmd = {...}`), `doc/open.txt`, `docs/BINDINGS.md`,
  `:checkhealth open` bereits vollständig — nur das Level-2-only Table of Contents fehlte im
  README, ergänzt. `docs/ROADMAP.md` war buchstäblich leer (0 Byte) statt nur "nichts geplant" —
  zählt als verwaist, mit einer kurzen "empty by design"-Notiz gefüllt. GitHub-Metadaten
  (`gh repo view`) bereits gesetzt: Description, Topics, Default-Branch `main`, keine
  LICENSE-Datei/-Referenz; Homepage leer wie bei allen anderen geprüften Schwester-Plugins
  (unverändert gelassen). Cross-Plattform: keine hartkodierten Pfadtrenner außerhalb
  `platform.is_win`-gegatterter Zweige (`keywords.lua`s `pip_conf`/`hosts`).
- **Refactoring.md**: Fail-late/Report-at-boundary bereits vollständig eingehalten — alle
  `notify()`-Aufrufe liegen in `handlers/*`, `registry.lua` (Dispatch-Grenze) und
  `bindings/keymaps.lua` (Setup-Warnung); `context.lua`, `util.lua`, `platform.lua`,
  `viewer/scan.lua` geben durchweg nur Status/Werte zurück. Keine Änderung nötig.

Übersprungen/nicht verifizierbar: `gh repo edit --homepage` nicht gesetzt (siehe oben, folgt der
Schwester-Plugin-Konvention); zentrale Bindings-Sammlung unter
`nvim/docs/NOTES/PersonelPlugins/BINDINGS/` wurde nicht neu geprüft (aus Zeitgründen, `docs/BINDINGS.md`
im Repo selbst ist bereits vollständig). Alles committet (`fc3a4a4`) und nach `origin/main` gepusht.

### images.nvim

Von allen bisher geprüften Plugins das sauberste: 34 Lua-Dateien, durchgängig `@module`/`@brief`/
`@description`, vollständige `@param`/`@return` mit `@types/init.lua`, `config/DEFAULTS.lua` +
`config/init.lua`, `.luarc.json` (`diagnostics.globals=["vim"]`, `workspace.library`), CI
(luacheck + headless `TESTS/run.lua`, 10 Specs, + ein `gen_map.lua --check`-Job für die
`documentation.nvim`-Modulkarte) bereits vorhanden — und explizit im Quellcode selbst dokumentiert
(`init.lua`s Kopfkommentar beschreibt das Fail-late-Muster wörtlich, `docs/ROADMAP/README.md` nennt
"Low-Level meldet nicht" als eine von drei festen Leitplanken). Dieser Pass fand entsprechend nur
Tooling-/Doku-Lücken, keinen einzigen Codefix:

- **PERFORMANCE.md**: kein echter Hotpath — `:Image`-Befehle laufen je einmal pro Aufruf,
  `gallery.lua`/`terminal.lua` bauen Platzierungen bzw. den OSC-Payload bereits per `t[#t+1]`/
  `table.concat` statt `table.insert`/`..`-Loop auf. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig mit dokumentierten Soft-
  Dependency-Fallbacks (`lib.nvim.ui.kit`, `markdown.nvim`, `snacks.picker`, `which-key`), saubere
  Importreihenfolge, `ImagesNvim.Config` vollständig typisiert inkl. `string|false` für abschaltbare
  Keymaps. Keine Änderung nötig.
- **REVIEW.md §8 Tooling**: `.luarc.json` vorhanden und äquivalent zu `sessions.nvim`s, aber
  `.luacheckrc` und `stylua.toml` fehlten komplett (jedes andere geprüfte Plugin mit CI hat beide) —
  ergänzt, angelehnt an `markdown.nvim`/`cascade.nvim` (`collapse_simple_statement =
  "ConditionalOnly"`, passend zum bereits im Code verwendeten Guard-Clause-Stil). `stylua --write`
  mit dieser Config über `lua/`, `plugin/`, `scripts/`, `TESTS/` laufen lassen (reine Formatierung,
  Logik unverändert) und einen `stylua --check`-Schritt in `.github/workflows/ci.yml`s `lint`-Job
  ergänzt (vorher nur `luacheck`). `luacheck`/`stylua --check`/Testsuite (10/10) danach grün;
  `gen_map.lua --check` initial "stale" (Map bettet Quelltext ein, das sich durch die Reformatierung
  geändert hatte) — mit `gen_map.lua` neu erzeugt und committet.
- **RELEASE.md**: README (Englisch, ASCII-Art, Badges, Schwesterplugin-Absatz zu markdown.nvim,
  Installationsblock mit explizitem `ft = {...}`, `lib.nvim`-Dependency deklariert) war bereits
  release-reif — nur das Level-2-only Table of Contents fehlte, ergänzt. `doc/images.txt` (9
  Abschnitte, jeder Befehl/jede Lua-API-Funktion dokumentiert), `docs/BINDINGS.md` (alle 19
  Subcommands, 6 Keymaps, 5 Autocmd-Einträge), `docs/ROADMAP/{README,FEATURES,CROSS-PLUGIN,
  TERMINALS}.md`, `:checkhealth images` (Terminal-Ausgabe, Terminal-Erkennung, Clipboard-Tool pro
  Plattform, lib.nvim/markdown.nvim-Deps) bereits vollständig und aktuell. GitHub-Metadaten
  (`gh repo view`) bereits vollständig gesetzt: Description, 10 Topics, Default-Branch `main`, leeres
  Homepage-Feld (Schwester-Plugin-Konvention), keine LICENSE-Datei/-Referenz — keine Änderung nötig.
  Cross-Plattform: keine hartkodierten Backslash-Pfadtrenner; alle Pfad-Joins laufen über `/`
  (Windows-tauglich), die einzigen `\\`-Vorkommen sind bewusste `gsub("\\", "/")`-Normalisierungen
  in `resolve.lua`/`paste.lua` (mit ausführlichem Kommentar, warum `fnamemodify` unter Windows
  gemischte Trenner liefern kann) — kein `lib.nvim.cross`-Bedarf, da nichts plattformspezifisch
  verzweigt außer `paste.lua`/`health.lua`s bereits korrekten `has("win32")`/`has("mac")`-Zweigen für
  das Clipboard-Tool.
- **Refactoring.md**: Fail-late/Report-at-boundary bereits vollständig eingehalten — geprüft in
  `browse.lua`, `compare.lua`, `zen.lua`, `guard.lua`, `paste.lua`, `init.lua`: alle `notify()`-
  Aufrufe sitzen an der Befehls-Einstiegsstelle (`M.open`/`M.run`/`M.replace`/`M.check`/die
  öffentlichen `images.*`-Funktionen), nie in `terminal.lua`, `gallery.lua`, `scan.lua`,
  `resolve.lua`, `info.lua`, `orphans.lua` — die geben durchweg nur `ok, err` zurück. `guard.lua`
  zentralisiert das `warned`-Flag bewusst für drei Aufrufer (`init`, `browse`, `zen`) statt jeder
  Aufrufer sein eigenes mitschleppt — im Modulkommentar selbst begründet. Keine Änderung nötig.

Zusätzlich zentrale Bindings-Sammlung (`nvim/docs/NOTES/PersonelPlugins/BINDINGS/`) geprüft und
korrigiert: `Keymaps/images.nvim.md` war aktuell; `Usercmds/images.nvim.md` fehlten sechs
Subcommands (`replace`, `orphans`, `pickers`, `compare`, `zen`, `check` — das Plugin ist seit der
ersten Fassung des Sheets gewachsen), ergänzt; `Autocmds/images.nvim.md` existierte noch gar nicht,
neu angelegt (5 Einträge, deckungsgleich mit `docs/BINDINGS.md` im Repo).

Übersprungen/nicht verifizierbar: nichts — alle Prüfpunkte waren direkt einsehbar oder per
`luacheck`/`stylua`/`nvim --headless -l TESTS/run.lua`/`nvim --headless -l scripts/gen_map.lua
--check` lokal verifizierbar. Alles committet (`07e9f18`) und nach `origin/main` gepusht.

### emojis.nvim

Ebenfalls eines der saubersten geprüften Plugins: 37 Lua-Dateien, durchgängig `@module`/
`@brief`/`@description`, vollständige `@param`/`@return`, ein zentrales `@types.lua` (statt
Ordner-pro-Unterverzeichnis — bewusste Ausnahme, siehe unten), `config/DEFAULTS.lua` +
`config/init.lua` mit typisierten Keys, `.luacheckrc`/`stylua.toml`/CI (stylua + luacheck +
headless `docs/TESTS/run.lua`, 7 Specs) bereits vorhanden. Dieser Pass fand keinen einzigen
Codefix — nur Tooling-/Doku-Lücken:

- **PERFORMANCE.md**: kein Hotpath-Fund über den Tokenizer/Ops hinaus, der bereits sauber ist —
  `core/patterns.lua`/`core/ops.lua` nutzen durchweg lokale Refs, `table.concat` statt
  `..`-Loop-Concat, und bauen Ergebnistabellen per `t[#t+1]` auf. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` ist seit der `usercmd.composer`-Migration
  Pflichtabhängigkeit für die `:Emojis`-Registrierung, `notify`/`map` bleiben bewusst weich mit
  nativem Fallback (`util/lib.lua`), Importreihenfolge sauber, Buffer/Window-Handles überall
  validiert (auch in `vim.schedule`-Callbacks des Overlays). Keine Änderung nötig.
- **REVIEW.md §8 Tooling**: `.luarc.json` fehlte komplett (einziges bisher geprüftes Plugin ohne
  eins) — ergänzt, identisch zu `sessions.nvim`s Version (`diagnostics.globals=["vim"]`,
  `workspace.library`). `luacheck lua docs/TESTS` lief mit 0 Warnings/Errors; headless Testsuite
  (7/7 Specs) lief grün. `stylua --check` zeigte einen vollständigen Diff über alle Dateien — kein
  echtes Formatproblem, sondern der in `.gitattributes` selbst dokumentierte CRLF-Checkout-Effekt
  (`core.autocrlf=true` lokal vs. LF in CI); nicht angefasst, da Reformatierung hier nur Churn ohne
  Nutzen erzeugt hätte.
- **RELEASE.md**: `doc/emojis.txt` (13 Abschnitte), `docs/BINDINGS.md`, `docs/{installation,
  configuration,commands,keymaps,api,architecture}.md`, `:checkhealth emojis`, Installationsblock
  mit explizitem `cmd = "Emojis"` waren bereits vollständig und aktuell — nur README.md fehlten
  ASCII-Art/Badges/Level-2-only-ToC/Schwesterplugin-Absatz, ergänzt (Schwesterplugin: cascade.nvim,
  dessen `cycle.groups`-Bridge über `cascade_groups()` im Code bereits existierte, im README aber
  nicht erwähnt war). **`docs/ROADMAP.md` war leer** — absichtlich am 2026-07-24 geleert (alle
  Punkte umgesetzt), aber `lua/emojis/bindings/autocmds.lua`s Modulkommentar verweist weiterhin
  namentlich auf deren "Nicht geplant"-Abschnitt für die No-Autocmds-Design-Entscheidung → totes
  Cross-Reference. Mit kurzer Status-Zusammenfassung + demselben "Nicht geplant"-Abschnitt wie vor
  dem Leeren wiederhergestellt (Quellcode nicht angefasst). GitHub-Metadaten (`gh repo view`) waren
  komplett leer (Description, Topics) — gesetzt: Description, 4 Topics (neovim, neovim-plugin, lua,
  emoji); Homepage bewusst leer gelassen (Schwester-Plugin-Konvention), Default-Branch bereits
  `main`, keine LICENSE-Datei/-Referenz. Cross-Plattform: keine hartkodierten Pfadtrenner (die
  einzigen `\`-Vorkommen sind Lua-Escapes wie `"\t"`/`"\27"` oder das ripgrep-Unicode-Pattern
  `\x{...}`, keine Pfad-Joins; `overlay/frecency.lua` joint konsequent über `/`).
- **Refactoring.md**: Fail-late/Report-at-boundary war bereits vollständig eingehalten —
  `core/*` (patterns/ops/scope/checkbox/insert) und `util/lib.lua` geben durchweg nur
  Werte/Status/`(ok, err)` zurück, `notify()` sitzt ausschließlich in `actions.lua`, `commands.lua`,
  `init.lua`, `search.lua`, `picker.lua`, `overlay/init.lua`, `health.lua`, `config/init.lua`
  (Dispatch-/UI-/Setup-Grenze). Keine Änderung nötig.

Bewusste Abweichung: `lua/emojis/@types.lua` bleibt eine einzelne Datei statt eines
`@types/init.lua`-Baums pro Unterverzeichnis — sie gruppiert bereits sauber nach Quelldatei und
gibt `{}` zurück; bei diesem Plugin-Umfang wäre eine Aufsplittung in sechs Mini-Ordner reine
Fragmentierung ohne Mehrwert (gleiche Ausnahme wie bei fileops.nvim).

Übersprungen/nicht verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — verifiziert
stattdessen über die bestehende GitHub-Actions-CI (`ubuntu-latest`, stylua + luacheck + Testsuite),
die bei jedem Push läuft. Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/emojis.nvim.md`) war
inhaltlich bereits aktuell (Keymaps/Usercmds-Tabellen stimmten mit `docs/BINDINGS.md` überein);
korrigiert wurde nur die stale Behauptung in `Usercmds/emojis.nvim.md` und
`Autocmds/emojis.nvim.md`, die `docs/ROADMAP.md`s "Nicht geplant"-Cross-Reference sei bereits
repo-weit bereinigt worden — war sie nicht, siehe RELEASE.md-Fund oben. Alles committet
(`824b6ba`) und nach `origin/main` gepusht.

### replacer.nvim

Bei weitem das größte bisher geprüfte Plugin (41 Lua-Dateien, ~7900 Zeilen) und auch inhaltlich
sehr ausgereift: durchgängig `@module`-Kopfzeilen, vollständige `@param`/`@return`, ein eigenes
`@types`-Verzeichnis (`config.lua`, `pickers.lua`, `init.lua`), `config/DEFAULTS.lua` +
`config/init.lua`, `.luarc.json`, `.luacheckrc`, `stylua.toml`, `.github/workflows/ci.yml`
(luacheck + stylua + drei Headless-Testsuiten) sowie `doc/replacer.txt`, `docs/BINDINGS.md`
(vollständig, inkl. expliziter "keine Autocmds"-Aussage) und `docs/ROADMAP.md` (gepflegt) waren
bereits vollständig und aktuell vor diesem Pass — offensichtlich Ergebnis einer eigenen früheren
Aufräum-Serie (`git log` zeigt u. a. "feat(health): wire composer.checkhealth", "docs: add LuaLS
annotations for documentation.nvim").

- **PERFORMANCE.md**: kein neuer Hotpath-Fund — `rg.lua`s Match-Sammlung (der einzige Kandidat,
  läuft über potenziell viele Dateien) nutzt bereits durchgängig `t[#t+1]`/explizite Indizes statt
  `table.insert`, `apply.lua`s bottom-up-Edits sortieren einmal statt pro Iteration neu. Keine
  Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig (`lib.nvim.notify`,
  `lib.nvim.usercmd.composer`, `lib.nvim.progress`, `lib.nvim.ui.kit`), saubere Trennung
  pure/side-effecting (`apply.lua`s `compute_file_edits` vs. `apply_matches`), `RP_Config` in
  `types/config.lua` vollständig typisiert mit Kommentar pro Key. Keine Änderung nötig.
- **REVIEW.md §8 Tooling — der einzige echte Fund dieses Passes**: `stylua --check` (wie von CI
  ausgeführt) schlug seit mehreren Commits in Folge fehl (`gh run list` zeigte 5/5 letzte Runs
  `failure`) — ein `stylua`-Versions-Bump hatte begonnen, den im gesamten Repo konsequent
  genutzten kompakten Guard-Clause-Stil (`if x then return y end`) unter
  `collapse_simple_statement = "Never"` in Mehrzeiler zu expandieren, was vom tatsächlich
  committeten (kompakten) Stil abwich. Mit `stylua lua/ plugin/` neu formatiert (reine
  Whitespace-Änderung; verifiziert per `luacheck` [0 Warnings/Errors] und der vollständigen
  Headless-Testsuite: 153/154 vor und nach dem Reformat identisch — die eine verbleibende
  Fehlschlag "history: pick() re-runs the newest entry" ist reproduzierbar unabhängig von diesem
  Commit und stammt aus altem lokalen `stdpath("data")/replacer/history.json`-Zustand auf dieser
  Maschine, kein Regressions-Bug). `.luarc.json` war inhaltlich äquivalent zu `sessions.nvim`s,
  aber ohne `runtime.path`/`workspace.library`/`workspace.useGitIgnore` — ergänzt zur
  Vereinheitlichung mit dem Schwester-Plugin-Muster.
- **RELEASE.md**: README fehlten ASCII-Art und der Schwesterplugin-Absatz (jetzt: fileops.nvim,
  wegen der thematischen Nähe Datei-/Verzeichnis-Operationen ↔ Inhalts-Ersetzung/-Umbenennung) —
  ergänzt; das inline `## Roadmap`-Kapitel war veraltet (Punkte als offen markiert, die laut
  `docs/ROADMAP.md` längst umgesetzt sind) und hatte zudem einen doppelten `___`-Trenner — durch
  einen Verweis auf das gepflegte `docs/ROADMAP.md` ersetzt. `doc/replacer.txt`,
  `docs/BINDINGS.md`, `:checkhealth replacer` (inkl. `composer.checkhealth`-Preflight für
  `:Replace`/`:Surround`) bereits vollständig. GitHub-Metadaten (`gh repo view`) bereits gesetzt:
  Description, 13 Topics, Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention),
  keine LICENSE-Datei/-Referenz — keine Änderung nötig. Cross-Plattform: keine hartkodierten
  Pfadtrenner; die einzigen `[/\\]`-Vorkommen sind bewusste Zeichenklassen zum *Erkennen* beider
  Trenner beim Normalisieren (`root.lua`, `fnames.lua`, `checkpoint.lua`, `rg.lua`), keine
  Windows-only-Joins.
- **Refactoring.md**: bereits vollständig eingehalten — geprüft in `apply.lua`, `rg.lua`,
  `checkpoint.lua`, `fnames.lua`, `batch.lua`, `presets.lua`, `root.lua`, `surround.lua`,
  `init.lua`: alle `notify()`-Aufrufe sitzen an der jeweiligen Befehls-Einstiegsstelle/
  Boundary-Funktion des Moduls, nie in echt-low-level/pure Helfern — `root.lua`s
  `detect`/`detect_best`, `gitfiles.lua` (komplett) und `casing.lua` (komplett) enthalten
  überhaupt kein `notify()`. Bewusst keine weitere Schichtentrennung eingeführt: Module wie
  `apply.lua`/`fnames.lua`/`checkpoint.lua` SIND bereits die Befehls-Handler ohne separate
  UI-Zwischenschicht — eine zusätzliche Indirektion nur zum Verschieben von `notify()`-Aufrufen
  hätte hier keinen Boundary-Gewinn, nur Overhead in einem 41-Datei-Repo erzeugt.

**Zweiter Fund, erst nach dem ersten Push per echtem CI-Lauf sichtbar geworden**: die
Headless-Testsuite schlug auf `ubuntu-latest` reproduzierbar mit demselben einen Fehlschlag fehl
wie lokal — `tests/feature_smoke.lua`s "history: pick() re-runs the newest entry" stubbte noch
`vim.ui.select`, obwohl `history.lua`s `M.pick()` bereits vor mehreren Commits (`0b3d1a5`) auf
`lib.nvim.ui.kit.select` migriert wurde; der Stub griff seither nie mehr. Auf denselben
`package.loaded`-Stub-und-Reload-Pattern umgestellt, den derselbe Testfile bereits für
`lib.nvim.ui.kit.confirm` nutzt — Suite danach 154/154 statt 153/154.

Übersprungen/nicht verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — verifiziert
stattdessen über CI (`ubuntu-latest`, luacheck + stylua + 3 Headless-Testsuiten), die bei jedem
Push läuft; genau diese CI deckte den zweiten Fund oben erst auf, nachdem der stylua-Fix bereits
grün war. Alles committet (`34f64a1`, `4e71144`) und nach `origin/main` gepusht.

### debugging.nvim

Bei weitem das sauberste bisher geprüfte Plugin: 42 Lua-Dateien, durchgängig `@module`/`@brief`/
`@description`, vollständige `@param`/`@return` (Arität stichprobenartig gegen die tatsächlichen
`return`-Statements verifiziert, keine Abweichung gefunden), `@types/init.lua` pro Unterverzeichnis
mit echten mehrfeldrigen Strukturen (bewusst ausgelassen für `actions/`, `terminals/`,
`nvim_options/` — dort nur Primitive, dokumentiert im Kopf von `tools/@types/init.lua` und in
`docs/ROADMAP/Checklist.md`), `config/DEFAULTS.lua` + `config/init.lua`, `.luarc.json`/
`.luacheckrc`/`stylua.toml`/CI (stylua + luacheck + headless `docs/TESTS/run.lua`, 4 Specs) bereits
vorhanden und grün. Das Repo hat außerdem schon drei eigene Audit-Dateien unter `docs/ROADMAP/`
(`Checklist.md`, `Arch&Coding.md`, `Zentral-Prinzipien.md`), die frühere Checklisten-Läufe gegen
exakt dieselben Quell-Checklisten dokumentieren, inklusive begründeter bewusster Abweichungen.
Ein vorheriger (durch ein Session-Limit unterbrochener) Anlauf hatte bereits den einzigen
gefundenen **Refactoring.md**-Verstoß behoben und gepusht (Commit `0e75b46`): `views/capture/
init.lua`s `capture_messages()` notifizierte vormals selbst; jetzt gibt sie ausschließlich
`(ok, content, detail)` zurück, die beiden Call-Sites (`debugging.views.messages_capture`,
`bindings/keymaps.lua`s `<lt>c`) entscheiden über das Melden — verifiziert mit stylua/luacheck/
Testsuite grün. Dieser Pass deckte die restlichen vier Checklisten vollständig ab und fand sonst
nur eine einzige Lücke:

- **PERFORMANCE.md**: kein Hotpath vorhanden (alles läuft on-demand über `:Debug`, plus zwei
  Auto-Refresh-Autocmds für offene Debug-Fenster) — bereits explizit in
  `docs/ROADMAP/Zentral-Prinzipien.md` und `Checklist.md` begründet. `autocmds/sources.lua`, die
  einzige nennenswerte Iteration (rekursiver Verzeichnis-Scan), nutzt bereits lokale
  `table.insert`/`concat`/`sort`-Aliase, `table.concat` statt Verkettung, und einen 5s-TTL-Cache
  (`lib.nvim.cache.memory`) pro Root. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig (`notify`, `window`,
  `buf_win_tab.*`, `fs.collect_recursive`, `cache.memory`, `cross.copy_to_clipboard`, `usercmd.
  composer`, `autocmd.create`, `lua_ls.get_module_path`, `lazy`), Buffer/Window-Handles überall
  validiert (auch in `vim.defer_fn`-Callbacks in `bindings/autocmds.lua`/`views/utils.lua`), saubere
  Importreihenfolge, `Dbg.Config` vollständig typisiert. Keine Änderung nötig.
- **REVIEW.md**: Schnell-Check und Detailprüfung sauber — kein globaler State (das einzige
  `_G[varname]`-Lesen in `tools/vardump/init.lua` ist die dokumentierte Kernfunktion des Befehls,
  kein Zustands-Anti-Pattern), Single Responsibility pro Modul, `bindings/usercmds.lua` als einzige
  Registrierungsstelle für `:Debug`. `.luarc.json`/`.luacheckrc`/`stylua.toml` bereits korrekt und
  unverändert übernommen (§8 Tooling). `stylua --check .`/`luacheck lua`/Headless-Testsuite liefen
  bereits vor jeder Änderung grün (0 Findings) — ungewöhnlich für einen ersten Checklisten-Pass,
  aber durch die dokumentierte Vorgeschichte (drei eigene Audit-Runden, sieben grüne CI-Runs)
  erklärt.
- **RELEASE.md — der einzige Fund dieses Passes**: README.md hatte ASCII-Art, Badges, den
  Schwesterplugin-Absatz (insights.nvim) und einen Installationsblock mit explizitem `cmd = "Debug"`
  bereits korrekt — nur das geforderte Table of Contents (nur Level-2-Überschriften) fehlte,
  ergänzt (`## Table of Contents` mit Ankern auf `Quick Start`/`Documentation`). `doc/debugging.txt`,
  `docs/BINDINGS.md`, `docs/ROADMAP.md`, `docs/{architecture,commands,configuration,installation,
  troubleshooting}.md` waren bereits vollständig und aktuell — Cross-Check gegen den tatsächlichen
  Code (`bindings/keymaps.lua`, `bindings/autocmds.lua`, `commands.lua`s Registry) ergab keine
  Abweichung. `:checkhealth debugging` headless getestet (`setup({all=true})` +
  `:checkhealth debugging` lief fehlerfrei durch). GitHub-Metadaten (`gh repo view`) bereits
  vollständig gesetzt: Description, 5 Topics, Default-Branch `main`, leeres Homepage-Feld
  (Schwester-Plugin-Konvention), keine LICENSE-Datei/-Referenz — keine Änderung nötig.
  Cross-Plattform: keine hartkodierten Pfadtrenner (`debug_helper.lua`s einziger `\\`-Treffer ist
  reines Reporting von `package.config`, kein Join). CI (`gh run list`) war vor und nach dem Fix
  grün.
- **Refactoring.md**: siehe oben — der einzige Fund war bereits durch den unterbrochenen Vorlauf
  (Commit `0e75b46`) behoben; dieser Pass fand keine weiteren `notify()`-Aufrufe in Low-Level-Code.
  Alle verbleibenden `notify()`-Stellen sitzen entweder an der Dispatch-Grenze (von
  `commands.lua`s Registry direkt aufgerufene Action-Funktionen in `actions/*`, `tools/*`,
  `autocmds/runtime.lua`, `terminals/keylogger.lua`, `nvim_options/indent_helpers.lua`,
  `markdown/inline_debug.lua`) oder sind explizit Opt-in-Diagnostik (`debug=true` in
  `views/capture/init.lua`, `views/capture/clipboard/init.lua`, `views/debug_helper.lua` — letzteres
  ein eigenständiges, nicht in `:Debug` verdrahtetes Entwickler-Tool).

Übersprungen/nicht verifizierbar: nichts — GitHub-Metadaten, `:checkhealth`, CI-Status und die
zentrale Bindings-Sammlung waren alle direkt prüfbar. Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/debugging.nvim.md`) war
inhaltlich bereits aktuell und deckungsgleich mit `docs/BINDINGS.md`; korrigiert wurde nur eine
stale Aussage in `Usercmds/debugging.nvim.md` ("No CI for this repo" — CI wurde am 2026-07-30
ergänzt, nach der dort dokumentierten `usercmd.composer`-Migration). Alles committet (`0e75b46`
aus dem unterbrochenen Vorlauf, `8e2c080` aus diesem Pass) und nach `origin/main` gepusht.

### dap.nvim

Bereits sehr sauber: 43 Lua-Dateien, durchgängig `@module`, `@param`/`@return` (Arität gegen die
tatsächlichen `return`-Statements der geänderten Funktionen verifiziert), `@types/init.lua`
(einzelne Datei statt Ordner-pro-Unterverzeichnis — bei nur einer Config-Types-Datei sinnvoll,
gleiche bewusste Ausnahme wie bei fileops.nvim/emojis.nvim), `config/DEFAULTS.lua` +
`config/init.lua`, `.luarc.json` (inhaltlich über sessions.nvims Version hinaus: zusätzlich
`workspace.ignoreDir`, `hint.*`), `.luacheckrc`/`stylua.toml`/CI (stylua + luacheck + headless
plenary-Suite, 23 Specs über 4 Dateien) bereits vorhanden.

- **PERFORMANCE.md**: kein echter Hotpath — alles läuft on-demand über Keymaps/`:Dap`-Subcommands
  einmal pro Aufruf; die einzige Iteration mit Nutzer-Interaktion (`counted_step()`s DAP-
  Listener-Kette für `vim.v.count1`) ist bereits auf `MAX_CHAINED_STEPS = 1000` gedeckelt und
  räumt sich selbst über `event_terminated`/`event_exited` auf. Keine Änderung nötig.
- **LUA_NVIM.md — zwei echte Funde**: `bindings/keymaps/init.lua` nutzte `vim.keymap.set` direkt
  statt `lib.nvim.map` (das Modul existiert in `lib.nvim` noch gar nicht) — auf denselben
  `pcall(require, "lib.nvim.map")`-mit-Fallback ergänzt, den `sessions.nvim`s
  `bindings/keymaps/init.lua` bereits für genau diesen Fall etabliert hat; `health.lua` meldet
  jetzt zusätzlich, ob `lib.nvim.map` verfügbar ist. `bindings/usercmds/init.lua`s
  `conditional-breakpoint`/`log-point`-Routen benutzten noch blockierendes `vim.fn.input()`,
  obwohl dieselben Prompts in `bindings/keymaps/init.lua` und `languages/*.lua` längst auf
  `lib.nvim.ui.kit.input` migriert sind (siehe Git-Historie) — nachgezogen.
- **REVIEW.md**: Schnell-Check/Detailprüfung sauber; `.luarc.json`/`.luacheckrc`/`stylua.toml`
  bereits vorhanden und korrekt (§8 Tooling, kein Vergleich mit sessions.nvim nötig gewesen).
  `stylua --check .` schlug initial auf `tests/wkddap/languages/program_prompt_spec.lua` fehl —
  dieselbe Klasse von Fund wie bei replacer.nvim: `gh run list` zeigte die CI seit mehreren Commits
  durchgehend `failure` auf exakt diesem stylua-Schritt. `stylua .` normalisiert (reine
  Whitespace-Änderung); `luacheck`/`stylua --check`/die volle Headless-Suite (23/23) liefen danach
  grün, und der nächste CI-Lauf war zum ersten Mal seit mehreren Commits wieder grün.
- **RELEASE.md**: README (Englisch, ASCII-Art, Badges, Schwesterplugin-Absatz zu debugging.nvim —
  bewusst beibehalten statt auf sessions.nvim/language.nvim umgestellt, da debugging.nvim
  technisch näher verwandt ist: DAP-Sessions vs. Live-Editor-Introspektion desselben Debugging-
  Workflows) fehlte nur das Level-2-only Table of Contents, ergänzt. `doc/wkddap.txt` trug bisher
  nur `*wkddap.txt*`/`*dap.nvim*` als Tags, kein bloßes `*wkddap*` — `:h wkddap` lief damit ins
  Leere; ergänzt. `docs/BINDINGS.md`/`docs/ROADMAP.md`/`:checkhealth wkddap` bereits vollständig
  und aktuell. GitHub-Metadaten (`gh repo view`) bereits vollständig gesetzt: Description, 7
  Topics, Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention), keine
  LICENSE-Datei/-Referenz — keine Änderung nötig. Cross-Plattform — **ein echter Fund**:
  `languages/python.lua`s `pythonPath` hängte hartkodiert `/bin/python` an `$VIRTUAL_ENV` an, was
  unter Windows (`Scripts\python.exe`) bricht — jetzt über `lib.nvim.cross.is_windows()`
  verzweigt und über `utils/paths.join()` zusammengesetzt. `languages/rust.lua`/`languages/zig.lua`
  bauten ihren Default-Pfad-Vorschlag (`target/debug`, `zig-out/bin`) noch per `..`-Konkatenation
  statt `utils/paths.join()` wie `c.lua`/`assembly.lua` — vereinheitlicht.
- **Refactoring.md — der einzige weitere Codefix**: `registry.lua`s `register()` rief
  `notify.warn`/`notify.error` selbst auf *und* gab `(false, err)` zurück; sein einziger Aufrufer
  `adapters/init.lua` notifiziert bei `not ok` bereits selbst — jeder Registrierungsfehler wurde
  also doppelt gemeldet. `register()`/`unregister()` geben jetzt nur noch Status zurück;
  `register_all()` (ein eigenständiger, unbenutzter Public-API-Aggregationseinstieg ohne weiteren
  Wrapper) behält sein `notify.warn` bewusst, da dort sonst niemand meldet.

Übersprungen/nicht verifizierbar: nichts — GitHub-Metadaten, `:checkhealth`-Code, CI-Status (vor
und nach dem Push per `gh run list` verifiziert) und die zentrale Bindings-Sammlung waren alle
direkt prüfbar oder per `stylua`/`luacheck`/der vollen Plenary-Suite lokal verifizierbar (POSIX
selbst nicht lokal testbar, Windows-Umgebung — wie bei den anderen Plugins über die
`ubuntu-latest`-CI abgedeckt). Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/dap.nvim.md`) war noch gar
nicht angelegt (keine der drei Dateien existierte) — alle drei neu erstellt aus
`docs/BINDINGS.md`. Alles committet (`467fb1b`) und nach `origin/main` gepusht.

### pdfport.nvim

Bereits das sauberste bisher geprüfte Plugin: 36 Lua-Dateien, alle 36 einzeln gelesen (nicht nur
gegrept) — durchgängig `@module`/`@brief`/`@description`, vollständige `@param`/`@return` (Arität
gegen die tatsächlichen `return`-Statements aller Funktionen mit mehreren Rückgabewerten
verifiziert, kein Fund), `@types/init.lua` (eine Datei statt Ordner-pro-Unterverzeichnis — gleiche
bewusste Ausnahme wie bei fileops.nvim/emojis.nvim/dap.nvim), `config/DEFAULTS.lua` +
`config/init.lua`, `.luarc.json` (inhaltlich äquivalent zu sessions.nvim: `diagnostics.globals=
["vim"]`, `workspace.library`), `.luacheckrc`/`stylua.toml`/CI (stylua + luacheck + headless
`TESTS/run.lua`, 4 Specs) bereits vorhanden. Kein einziger `notify()`-Aufruf außerhalb der
UI-Schicht (`renderers/*`, `bindings/usrcmds.lua`, `integrations/*`, `util/batch.lua`) —
`core/*`, `backends/*`, `util/cache.lua`, `util/page_range.lua`, `platform/init.lua` geben
durchweg nur `(status, err)`/`Result`-Tabellen zurück. Cross-Plattform bereits vollständig über
`lib.nvim.cross.platform.is_*`/`lib.nvim.cross.uv.spawn_capture` gelöst, keine hartkodierten
Pfadtrenner (die einzigen `\\`-Treffer sind bewusste `gsub("\\", "/")`-Normalisierungen in
`marker.lua` bzw. Zeichenklassen-Checks `dir:sub(-1) == "\\"` in `netrw.lua`/`integrations/
init.lua`, keine Windows-only-Joins).

- **PERFORMANCE.md**: kein Hotpath — bereits so in `docs/ROADMAP/Checklist.md` dokumentiert; alles
  läuft on-demand pro `:PdfPort`-Aufruf, jede Subprozess-Ausgabe läuft über `spawn_capture` +
  `table.concat`. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig (`notify`, `map`, `autocmd`,
  `usercmd.composer`, `window.make_scratch`, `cache.disk`, `progress`, `ui.kit`, `cross.*`),
  Buffer/Window-Handles validiert auch in `vim.schedule`/`vim.defer_fn`-Callbacks
  (`renderers/buffer.lua`, `terminal.lua`, `integrations/telescope.lua`/`fzf.lua`). Keine
  Änderung nötig.
- **REVIEW.md**: Schnell-Check/Detailprüfung sauber, kein globaler State, Single Responsibility
  pro Modul, `.luarc.json`/`.luacheckrc`/`stylua.toml` bereits korrekt (§8 Tooling). `stylua
  --check`/`luacheck`/die Headless-Suite liefen erst nach einem lokalen `core.autocrlf=true`-
  bedingten CRLF-Checkout-Effekt (gleiche Ursache wie bei emojis.nvim/replacer.nvim/dap.nvim,
  reiner lokaler Checkout-Artefakt, CI läuft auf `ubuntu-latest` und war nie betroffen) sauber
  durch, nach lokaler LF-Normalisierung ohne inhaltliche Diffs. Keine Codefix nötig.
- **RELEASE.md**: README hatte ASCII-Art/Badges bereits, aber kein Level-2-only Table of Contents
  und keinen Schwesterplugin-Absatz — beides ergänzt (Schwesterplugin: mdview.nvim, da mehrere
  Backends Markdown erzeugen). `doc/pdfport.nvim.txt` trug nur `pdfport.nvim-*`-Subtags, keinen
  bloßen `*pdfport*`-Treffer — nach `doc/pdfport.txt` umbenannt und alle Tags auf `pdfport-*`
  umgestellt, analog zu `fileops.txt`/`replacer.txt`, damit `:h pdfport` wie bei den anderen
  Plugins auffindbar ist. `docs/BINDINGS.md`/`docs/ROADMAP.md`/`:checkhealth pdfport` bereits
  vollständig und aktuell. Ein `test/`-Verzeichnis (`smoke.lua` + `README.md`) war ein Überbleibsel
  der Vor-`TESTS/`-Ära, nirgends mehr aus CI erreichbar und laut `docs/ROADMAP/Arch&Coding.md`
  selbst als abgelöst dokumentiert — entfernt, zwei dangling Links in `docs/ROADMAP.md`/
  `docs/ROADMAP/NEOTREE_FEATURES.md` korrigiert. GitHub-Metadaten (`gh repo view`) bereits
  vollständig gesetzt: Description, 6 Topics, Default-Branch `main`, leeres Homepage-Feld
  (Schwester-Plugin-Konvention), keine LICENSE-Datei/-Referenz — keine Änderung nötig.
- **Refactoring.md**: Fail-late/Report-at-boundary war bereits vollständig eingehalten — kein
  Codefix nötig, siehe `notify()`-Grep oben.

Übersprungen/nicht verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — verifiziert
stattdessen per `gh run list` gegen die bestehende `ubuntu-latest`-CI (grün vor und nach diesem
Pass). Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/pdfport.nvim.md`) geprüft
und aktualisiert — siehe unten. Alles committet (`8781b98`) und nach `origin/main` gepusht.

### cascade.nvim

Bereits mehrfach eigenständig auditiert (siehe `docs/ROADMAP/ROADMAP.md`s "Qualität &
Checklist-Audits"-Abschnitt: gegen "Arch&Coding", die Master-Checklist und den
Filetree-Feature-Katalog — alle drei abgeschlossen, die zugehörigen Audit-Dateien inzwischen
entfernt). 45 Lua-Dateien, durchgängig `@module`/`@brief`/`@description`, vollständige
`@param`/`@return` (Arität der geänderten Funktionen gegen die tatsächlichen `return`-Statements
verifiziert), ein konsolidiertes `@types/init.lua` pro Verzeichnisebene (`lua/cascade/@types/`,
`lists/types/`, `cycle/types/` — bereits sauber nach Quelldatei gruppiert, keine Änderung nötig),
`config/DEFAULTS.lua` + `config/init.lua` mit typisierten Keys, `.luarc.json`
(`diagnostics.globals=["vim"]`, `workspace.library` — inhaltlich äquivalent zu sessions.nvim),
`.luacheckrc`/`stylua.toml`/CI (stylua + luacheck + headless `docs/TESTS/run.lua` mit
lib.nvim-Sibling-Checkout, 6 Specs) bereits vorhanden und grün. Dieser Pass fand entsprechend
keinen einzigen Anti-Pattern-Fund in Fehlerbehandlung/Modularität/Buffer-Validierung/Cross-Plattform
und keinen `notify()`-Verstoß (kein Aufrufer von `util/lib.lua`s `M.notify` existiert überhaupt im
Plugin derzeit — die Funktion ist ein bereitstehender, ungenutzter Utility-Wrapper, kein
Low-Level-Verstoß). Gefunden und behoben:

- **PERFORMANCE.md — der einzige Codefix dieses Passes**: `lists/indent.lua`s `shift_line`
  (Indent/Dedent + Subtree) und `shift_range` (Visual-Range-Shift) sowie `lists/transform.lua`s
  `rotate`/`apply_order` (genutzt von `sort`/`reverse`)/`strip` riefen pro geänderter Zeile einen
  eigenen `nvim_buf_set_lines`-Call auf — ein echter Hotpath, da ein Indent/Rotate/Sort/Strip über
  einen großen Block/eine große Visual-Selection potenziell viele Zeilen trifft. `lists/renumber.lua`
  im selben Verzeichnis hatte genau dieses Muster bereits vorher gelöst (im Kommentar dort explizit
  begründet: ein `nvim_buf_set_lines`-Call ist billiger und gibt dem Markdown-Treesitter-Highlighter
  einen sauberen zusammenhängenden Edit statt vieler verstreuter). Alle fünf Funktionen auf dasselbe
  "im Speicher zusammenbauen, einmal committen"-Muster umgestellt — bei `transform.lua` zusätzlich
  der Fall behandelt, dass Basis-Indent-Zeilen nicht zusammenhängend sind (tiefer eingerückte
  Kind-Zeilen können dazwischenliegen). Mit manuellen Headless-Buffer-Tests verifiziert (Subtree-Shift
  mit Gap-Closing, Rotate/Sort/Reverse/Strip mit dazwischenliegenden Kind-Zeilen, Blank-Line-Handling
  — alle identisch zum vorherigen Verhalten).
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig über `util/lib.lua`s
  geführte Brücke (`lib.map`, `lib.notify`, `lib.augroup`, Roman/Alpha-Konvertierung,
  Case-Shape — alle mit dokumentiertem nativem Fallback), Buffer/Window-Handles validiert
  (`core.context.writable`), Importreihenfolge eingehalten, Konfigurierbarkeit vollständig
  (jeder Config-Key hat einen `@types`-Typ). Keine Änderung nötig.
- **REVIEW.md**: Schnell-Check/Detailprüfung/Anti-Pattern-Check sauber — kein globaler State,
  Single Responsibility pro Modul, `.luarc.json`/`.luacheckrc`/`stylua.toml` bereits korrekt
  (§8 Tooling, identisch zum sessions.nvim-Muster). `stylua --check .`/`luacheck lua scripts
  docs/TESTS`/die Headless-Suite liefen bereits vor jeder Änderung grün (0 Findings) und blieben es
  danach.
- **RELEASE.md**: README (Englisch, ASCII-Art, Badges, Level-2-only ToC, Schwesterplugin-Absatz zu
  pickers.nvim), `docs/BINDINGS.md` (gegen den tatsächlichen Code in `bindings/{keymaps,usrcmds,
  autocmds}.lua` verifiziert — deckungsgleich), `docs/ROADMAP/ROADMAP.md`, `:checkhealth cascade`
  waren bereits vollständig und aktuell. **Ein Fund**: `doc/cascade.txt`s CONFIGURATION-Beispiel war
  gegenüber `cascade.config.DEFAULTS` verwaist (fehlende `features`-Tabellen für `lists`/`cycle`,
  fehlendes `cycle.features.date`, `precision`/`precision_nodes` fehlten komplett, `lists.renumber`
  noch als bloßes Boolean statt der aktuellen Tabellenform) — korrigiert. GitHub-Metadaten
  (`gh repo view`) bereits vollständig gesetzt: Description, 8 Topics, Default-Branch `main`, leeres
  Homepage-Feld (Schwester-Plugin-Konvention), keine LICENSE-Datei/-Referenz. Cross-Plattform: keine
  hartkodierten Pfadtrenner (der einzige `\\`-Treffer in `config/DEFAULTS.lua` ist ein Markdown-
  Escape-Zeichen in einer Marker-Liste, kein Pfad-Join). CI (`gh run list`) war vor und nach diesem
  Pass grün.
- **Refactoring.md**: Fail-late/Report-at-boundary war bereits vollständig eingehalten — kein
  Codefix nötig (siehe `notify()`-Befund oben).

Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/cascade.nvim.md`) geprüft:
alle drei bereits vollständig und deckungsgleich mit `docs/BINDINGS.md` im Repo (inkl. `<leader>cp`
cycle_pick und der `:Cascade`-Bang-Positions-Historie) — keine Änderung nötig.

Übersprungen/nicht verifizierbar: nichts — GitHub-Metadaten, `:checkhealth`, CI-Status und die
zentrale Bindings-Sammlung waren alle direkt prüfbar oder per `stylua`/`luacheck`/der vollen
Headless-Suite lokal verifizierbar (POSIX selbst nicht lokal testbar, Windows-Umgebung — wie bei
den anderen Plugins über die `ubuntu-latest`-CI abgedeckt). Alles committet (`6602ae3`) und nach
`origin/main` gepusht.

### github_stats.nvim

45 Lua-Dateien. Kein `stylua.toml`/`.luacheckrc` im Repo vorhanden (einziges bisher geprüftes
Plugin ohne beides) — beide neu angelegt (angelehnt an `cascade.nvim`s `stylua.toml`;
`.luacheckrc` mit `std = "luajit"`, `globals = { "vim" }`, Ignores für `_`-präfigierte/`self`-
Parameter und read-only-Global-Field-Writes). `stylua .` fand daraufhin echte Formatierungs-
Abweichungen in ~10 Dateien (Tabs statt der konfigurierten 2 Spaces — kein reiner CRLF-Fund wie
bei den meisten anderen Plugins dieses Rollouts, das Repo ist durchgängig CRLF-eingecheckt, daher
`line_endings = "Windows"` statt `"Unix"` gesetzt, um keine unnötige Zeilenenden-Churn einzuführen).
Nach `stylua .`/`luacheck lua .luacheckrc` beide grün (0 Findings); zwei echte `luacheck`-Warnungen
(unbenutzte `fetch_time` in `analytics.lua`, ein sofort überschriebener Initialwert in
`fetcher.lua`s `fetch_all`) behoben.

- **PERFORMANCE.md**: kein echter Hotpath — alles läuft on-demand über `:GithubStats`-Subcommands,
  Dashboard-Keymaps oder den periodischen Background-Fetch (kein Redraw-/Keystroke-Hotpath). Keine
  Änderung nötig.
- **LUA_NVIM.md — der größte Fund dieses Passes**: sechs Dateien unter `bindings/usrcmds/`
  (`debug.lua`, `diff.lua`, `export.lua`, `paths.lua`, `referrers.lua`, `summary.lua`) riefen
  rohes `vim.notify()` auf statt wie der Rest des Plugins (`chart.lua`, `show.lua`,
  `keymaps.lua`) über `config.notify()` zu gehen (die zentrale `lib.nvim.notify`-Fassade mit
  `notification_level`-Filterung) — auf `config.notify(msg, "info"|"warn"|"error")`
  vereinheitlicht. `health.lua`s `command_exists()` enthielt zusätzlich **echten Duplicate-Code**:
  zwei komplette, identische Windows-PowerShell-Erkennungsblöcke hintereinander (einer über
  `vim.fn`/`vim.v.shell_error` direkt, einer über lokale Aliase) — durch einen einzigen Aufruf von
  `lib.nvim.cross.executable.exists(cmd)` ersetzt (vorhandene `lib.nvim`-Funktionalität, die exakt
  dasselbe robuster leistet). Ansonsten `lib.nvim` bereits breit genutzt (`notify`, `map`, `window`,
  `net.curl`, `fs.json`, `usercmd.composer`, `ui.kit.note`, `lua.strings.format`, `lua.tables`) —
  in 41 von 45 Dateien nachgewiesen.
- **REVIEW.md**: Schnell-Check/Detailprüfung sauber bis auf die beiden LUA_NVIM-Funde oben.
  **Ein echter Korrektheits-Bug gefunden und gefixt** (Buffer/Window-Abschnitt, Line-Height-
  Berechnung): `dashboard/render.lua`s `build_entry()` gibt 5 Zeilen pro Repo aus (Titel, Clones,
  Views, Period, Trenner), aber `dashboard/state.lua` und `dashboard/render.lua` hatten mehrere
  hartkodierte `* 6`-Annahmen (plus eine dritte, unabhängige und nirgends aufgerufene `2 + 3*N`-
  Formel in totem Code in `dashboard/movement.lua`) — jede Scroll-/Cursor-Berechnung war dadurch
  pro Eintrag um eine Zeile versetzt, kumulierend mit der Repo-Anzahl (bereits in `docs/devs/
  BUGS.md`/`docs/ROADMAP.md` als offener Priority-0-Bug dokumentiert). `render.lua` exportiert
  jetzt `M.ENTRY_LINES = 5` als einzige Quelle der Wahrheit; alle Stellen referenzieren sie.
  Der tote `move_to_index`/`move_down`/`move_up`/`move_first`/`move_last`-Code in
  `dashboard/movement.lua` (nirgends aufgerufen, trug seine eigene dritte falsche Formel) wurde
  entfernt statt gefixt. `.luarc.json` war bereits vorhanden und korrekt (`diagnostics.globals`
  inkl. `vim`/Busted-Globals, `workspace.library` für `luv`/`busted`) — keine Änderung nötig.
- **RELEASE.md**: README hatte ASCII-Art, Badges, Schwesterplugin-Absatz (reposcope.nvim) und
  einen Installationsblock mit explizitem `event = "VimEnter"` bereits korrekt — nur das
  geforderte Table of Contents (nur Level-2-Überschriften) fehlte, ergänzt. `doc/github_stats.
  nvim.txt` trug den Haupttag `*github_stats.txt*` in einer Datei, die nicht `github_stats.txt`
  hieß (abweichend von der Schwester-Plugin-Konvention `doc/<name>.txt`, z. B. `cascade.nvim` →
  `doc/cascade.txt`) — auf `doc/github_stats.txt` umbenannt. `docs/BINDINGS.md` gegen den
  tatsächlichen Code in `bindings/{keymaps,usrcmds/init,autocmds}.lua` verifiziert — bereits
  vollständig und deckungsgleich. `docs/ROADMAP.md`/`docs/devs/BUGS.md` aktualisiert, um die in
  dieser Session gefixten Priority-0-Bugs als erledigt zu markieren (vorher als offen
  dokumentiert). `:checkhealth github_stats` per Headless-Smoke-Test verifiziert (`health.check()`
  läuft ohne Fehler durch). GitHub-Metadaten (`gh repo view`) bereits vollständig gesetzt:
  Description, 7 Topics, Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention),
  keine LICENSE-Datei/-Referenz — keine Änderung nötig. Cross-Plattform: keine hartkodierten
  Pfadtrenner; Authentifizierung gegen die GitHub-API läuft über `config.get_token()`
  (Env-Var `GITHUB_TOKEN` oder `token_file`, kein `gh`-CLI-Aufruf, kein hartkodiertes Token) —
  Token wird nirgends geloggt/committet (`debug.lua` zeigt nur `#token` Zeichen, nie den Wert
  selbst).
- **Refactoring.md**: siehe LUA_NVIM-Fund oben (`vim.notify()` → `config.notify()` in sechs
  Usercommand-Dateien) — das war der einzige Fail-late-Verstoß; alle Low-Level-Module
  (`api.lua`, `storage.lua`, `analytics.lua`, `date_presets.lua`, `diff.lua`, `export.lua`,
  `visualization.lua`) geben durchweg nur `(data, err)`/`(ok, err)` zurück, kein `notify()`.

Übersprungen/nicht verifizierbar: Keine `busted`/`plenary`-Runtime in dieser Umgebung installiert
(`luarocks` ohne konfiguriertes Lua-Interpreter-Binary) — die drei `tests/*_spec.lua`-Dateien
konnten nicht tatsächlich ausgeführt werden. Zwei defekte `require()`-Pfade darin
(`dashboard.renderer`/`dashboard.navigator` statt `dashboard.render`/`bindings.keymaps`) wurden
trotzdem gefixt und stattdessen per Headless-`require()`-Smoke-Test aller 45 Produktionsmodule
verifiziert (0 Fehler). Kein `.github/workflows/` im Repo, daher kein `gh run list`-CI-Status
verfügbar. POSIX-Test nicht lokal möglich (Windows-Umgebung) — Code-Review ergab keine
Windows-only-Annahmen außerhalb der bereits korrekt `has("win32")`-gegatterten Zweige in
`health.lua`. Zentrale Bindings-Sammlung geprüft und aktualisiert, siehe unten. Alles committet
(`db8d8cb`) und nach `origin/main` gepusht.
