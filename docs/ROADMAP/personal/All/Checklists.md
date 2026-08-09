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
| pickers.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| buffer-ctx.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| open.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| sandbox.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| spotlight.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| documentation.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| runtime-analysis.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| 2. NAVIGATION, FILE SYSTEM, SEARCH & TREES |||||||
| fileops.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| gopath.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| replacer.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| insights.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| filetree.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| reposcope.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY |||||||
| debugging.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| dap.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| diff.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| language.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| cmdlog.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| emojis.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| github_stats.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| 4. FILE TYPES (MARKDOWN & DOCUMENTS) |||||||
| cascade.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| pdfport.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| markdown.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| color_my_ascii.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| recommender.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
| mdview.nvim | [x] | [x] | [x] | [x] | [x] | [x] |
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

### insights.nvim

- **PERFORMANCE.md**: kein echter Hotpath betroffen — `scan.rg`/`rg_index` laufen synchron über
  `vim.wait`, aber je einmal pro Nutzeraktion, nicht pro Tastendruck/Render; keine Änderung.
- **LUA_NVIM.md**: bereits stark `lib.nvim`-basiert (`lib.nvim.notify`, `lib.nvim.cross.*` für
  Plattform-/Pfad-/Shell-Fragen in `util/platform.lua`, `lib.nvim.usercmd.composer`,
  `lib.nvim.progress`) und sauber typisiert (`config/@types/init.lua`, `config/DEFAULTS.lua`,
  `Insights.CompressEngine`-Alias). Keine Verstöße gefunden, die einen Code-Fix erforderten.
- **REVIEW.md**: Schnell-Check größtenteils grün. Einziger konkreter Fund: `.luarc.json` war
  bereits inhaltlich identisch zu `sessions.nvim`s Referenz — keine Änderung nötig. `stylua.toml`
  und `.luacheckrc` fehlten komplett (§8 Tooling) — beide neu angelegt (`line_endings = "Windows"`,
  da das Repo konsistent CRLF ist; `std = "lua51+lua52"` für LuaJITs `package.searchpath`;
  `max_line_length` deaktiviert, da `stylua`s `column_width` das Codeformat bereits regelt und die
  verbleibenden langen Zeilen Regex-Patterns/Doc-Kommentare sind). `stylua .` einmal über den ganzen
  Baum laufen lassen (rein mechanisch, keine Verhaltensänderung) und zwei echte `luacheck`-Warnungen
  gefixt (toter `notify`-Import in `tree/init.lua`, ungenutztes `rg_msg` in `symbols/init.lua`).
  `stylua --check .` und `luacheck .` laufen jetzt beide grün (0/0).
- **RELEASE.md**: README hatte ASCII-Art, Badges, Schwesterplugin-Absatz (buffer-ctx.nvim) und
  einen Installationsblock mit explizitem `cmd = "Insights"` bereits korrekt — nur das geforderte
  Table of Contents (nur Level-2-Überschriften) fehlte, ergänzt. `doc/insights.txt`,
  `docs/BINDINGS.md`, `docs/ROADMAP.md` waren bereits vollständig und aktuell — gegen den
  tatsächlichen Code (`bindings/{keymaps,usrcmds,autocmds}.lua`) verifiziert, keine Abweichung.
  `compress`-Feature (`Insights.CompressEngine "auto"|"tar"|"zip"|"powershell"`): `auto`-Auflösung
  (tar auf Unix, PowerShell Compress-Archive auf Windows) wird bereits in `health.lua`s
  `check_compress()` gegen tatsächlich verfügbare Tools geprüft — keine Änderung nötig.
  `:checkhealth insights` per Headless-Smoke-Test verifiziert (`health.check()` läuft fehlerfrei
  durch), zusätzlich ein Headless-`require()`-Smoke-Test aller 44 Produktionsmodule (0 Fehler) als
  Ersatz für eine fehlende Testsuite (kein `tests/`-Ordner, kein `.github/workflows/`, daher kein
  `gh run list`-CI-Status verfügbar). GitHub-Metadaten (`gh repo view`) bereits vollständig gesetzt:
  Description, 7 Topics, Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention),
  keine LICENSE-Datei/-Referenz — keine Änderung nötig. Cross-Plattform: `util/platform.lua`
  delegiert bereits vollständig an `lib.nvim.cross` (OS-Erkennung, Shell-Ausführung, Clipboard);
  keine hartkodierten Pfadtrenner außerhalb der bewusst plattformverzweigten Stellen in
  `compress/init.lua`.
- **Refactoring.md**: ein echter Fund — `insights.scan.rg`s `M.run()` (geteilte Low-Level-Utility,
  von `symbols/rg_index.lua` und `symbols/init.lua` genutzt) rief bei fehlendem `rg`-Binary bzw.
  einem unerwarteten Exit-Code direkt `notify.error`/`notify.debug` auf. Umgebaut auf
  `(lines, err)`-Rückgabe ohne Seiteneffekt; beide Aufrufer sammeln den Fehler jetzt genauso wie
  bereits vorhandene Parse-Fehler und melden ihn an ihrer eigenen Grenze. Die übrigen `notify()`-
  Aufrufe (in `compress`, `conflicts`, `imports`, den `symbols`-Scannern, `devserver`, `unimported`)
  sind bewusst unangetastet geblieben: jede dieser Funktionen ist der von `bindings/usrcmds.lua`
  direkt aufgerufene Einstiegspunkt für genau ein `:Insights <sub>`-Kommando, also bereits die
  UI-Grenze für diese vertikale Slice — anders als `scan.rg`, das von mehreren Features geteilt wird.

Übersprungen/nicht verifizierbar: CI-Status (`gh run list`) nicht anwendbar — kein
`.github/workflows/` im Repo. POSIX-Verhalten nicht lokal nachstellbar (Windows-Umgebung); Review
der `platform.is_windows()`-Verzweigungen in `compress/init.lua` und `util/platform.lua` ergab keine
Windows-only-Annahmen im POSIX-Zweig. Zentrale Bindings-Sammlung geprüft und aktualisiert, siehe
`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/insights.nvim.md`. Alles
committet (`6445452`) und nach `origin/main` gepusht.

### buffer-ctx.nvim

Bereits solide (54 Lua-Dateien): durchgängig `@module`, `@types.lua` als einzelne konsolidierte
Datei (bewusste Ausnahme wie bei fileops.nvim/emojis.nvim — sauber nach Quelldatei gruppiert),
`config/DEFAULTS.lua` + `config/init.lua`, `.luarc.json` (identisch zu `sessions.nvim`s Referenz),
`.luacheckrc`, `.stylua.toml`, `.github/workflows/ci.yml` (stylua + luacheck + headless
`docs/TESTS/run.lua`, 5 Specs + separater `:checkhealth`-Job) bereits vorhanden. `gh run list`
zeigte die letzten 5 CI-Runs auf `main` als `failure` — dieser Pass hat das behoben, siehe unten.

- **PERFORMANCE.md**: kein echter Hotpath — jedes `:Insert`/`:Copy`/`:Format`/`:Mark`-Subcommand
  läuft einmal pro Nutzeraktion, kein Cursor-move-Autocmd, keine Statusline-Komponente.
  `format/table_fmt.lua`s Zeilen-Scan über einen ganzen Buffer/mehrere Markdown-Dateien ist der
  einzige nennenswerte Kandidat und baut Zeilen bereits per `t[#t+1]`/`table.concat` auf — bis auf
  einen Fund (`parse_row`, siehe REVIEW.md unten) keine Änderung nötig.
- **LUA_NVIM.md**: `lib.nvim` wird über den Commandlayer (`lib.nvim.usercmd.composer`) tatsächlich
  als **harte** Abhängigkeit genutzt (unconditional `require`, kein `pcall`) — anders als in der
  Aufgabenstellung vermutet ("soft dependency, unlike most siblings"); README/`docs/installation.md`
  dokumentieren das bereits korrekt (`-- required`), nur `notify`/`map`/`which_key` bleiben weich
  mit nativem Fallback. Die GitHub-Repo-Description behauptete dagegen noch "No hard dependencies,
  standalone" (stammt vermutlich von vor der composer-Migration) — mit `gh repo edit --description`
  korrigiert. `config/init.lua`s `M.setup()` akzeptierte jeden `user_opts`-Wert ohne Typprüfung vor
  `vim.tbl_deep_extend` (hätte bei einem Nicht-Tabellen-Wert dort gecrasht) — Guard ergänzt.
  `@types.lua`s `Config.format`-Feld war ein anonymer Inline-Typ statt einer benannten Klasse (im
  Gegensatz zu `Config.mark`) — `BufferCtx.FormatConfig` ergänzt.
- **REVIEW.md — mehrere echte Funde**: (1) systematischer `@return`-Arität-Fehler in acht
  `ops/*`/`format/*`-Dateien (`annotation.lua`, `bufinfo.lua`, `env.lua`, `filepath.lua`,
  `location.lua`, `module.lua`, `snippet.lua`, `boilerplate/init.lua`,
  `blank_lines.lua`s `squeeze_buffer`): als `(result, err)` annotierte Funktionen ließen das
  abschließende `nil` auf dem Erfolgspfad weg (in Lua harmlos, aber eine echte Doku-/Aritäts-
  Abweichung) — überall ergänzt. (2) `format/table_fmt.lua`s `parse_row` baute jede Tabellenzelle
  zeichenweise per `..` auf (O(n²) in der Zeilenlänge) — auf `gmatch`-Split umgestellt. (3)
  `format/text_width.lua`s `reflow_buffer`/`reflow_range` prüften den übergebenen `bufnr` nie mit
  `nvim_buf_is_valid` — ergänzt. (4) `format/column_align.lua`s modul-globaler `state`-Tisch
  (letzte Zielspalte/Füllzeichen) wurde direkt gelesen/geschrieben — jetzt über `get_last()`/
  `set_last()` gekapselt. (5) `mark/init.lua`s `marked`-Tabelle (Buffer → Extmark-IDs) wurde von
  vier Stellen direkt manipuliert — jetzt über `get_marks()`/`add_mark()`/`remove_mark()`/
  `clear_marks()` gekapselt. (6) `telescope/_extensions/buffer_ctx.lua`s Preview schrieb in den
  Previewer-Buffer ohne `nvim_buf_is_valid`-Guard — ergänzt (geringes Risiko dank Telescopes
  synchronem Preview-Vertrag, aber ein echter fehlender Guard). `.luarc.json`/`.luacheckrc`/
  `.stylua.toml` (§8 Tooling) waren bereits vorhanden und korrekt — keine Änderung.
- **RELEASE.md**: README hatte ASCII-Art, Badges, Schwesterplugin-Absatz (gopath.nvim) und einen
  Installationsblock mit explizitem `event = "VeryLazy"` bereits korrekt — nur das geforderte
  Table of Contents (nur Level-2-Überschriften) fehlte, ergänzt. `doc/buffer-ctx.txt`,
  `docs/BINDINGS.md`, `docs/ROADMAP/ROADMAP.md` waren bereits vollständig und aktuell — gegen den
  tatsächlichen Code verifiziert (Keymaps/Usercmds/Autocmds decken sich exakt). `:checkhealth
  buffer_ctx` per Headless-Smoke-Test verifiziert, sowohl mit als auch **ohne** lib.nvim auf dem
  Runtimepath (siehe LUA_NVIM.md-Fund/echter Crash-Fix unten). GitHub-Metadaten (`gh repo view`)
  bereits gesetzt: 6 Topics, Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-
  Konvention), keine LICENSE-Datei/-Referenz; nur die Description war stale (siehe LUA_NVIM.md
  oben), korrigiert. Cross-Plattform: `util/path.lua`s Soft-Fallback (ohne `lib.nvim.cross`) ist
  bereits genuin plattformübergreifend (`gsub("\\","/")`-Normalisierung vor jeder Segmentierung,
  parametrischer `sep` statt hartkodiertem Trenner); `ops/filepath.lua`s `\\`/`package.config`-
  Vorkommen sind bewusste, nutzerangeforderte Ausgabeformat-Schalter (`format=win`), keine
  OS-Erkennungs-Bugs.
- **Refactoring.md — zwei echte Funde**: (1) `util/clip.lua`s `M.copy` (geteilte Low-Level-Utility,
  von `commands.lua`, `bindings/keymaps.lua` und `mark/init.lua` genutzt) notifizierte selbst
  (`info`/`warn`) statt nur Status zurückzugeben — problematisch, weil `warn` dabei nie
  unterdrückbar war, selbst wenn ein Aufrufer `{ silent = true }` übergab (`mark.yank` tat genau
  das). Umgebaut auf `(ok, err, preview)`-Rückgabe ohne Seiteneffekt; alle vier Aufrufer (zwei Sinks
  in `commands.lua`, drei Keymaps in `bindings/keymaps.lua`, `mark.yank`) entscheiden jetzt selbst
  über das Melden. (2) `format/table_fmt.lua`s `resolve_overrides` (eine Parsing-Hilfsfunktion,
  zwei bis drei Aufrufebenen von jedem Command-Handler entfernt) notifizierte direkt bei
  unauflösbaren `col_overrides` — gibt jetzt `(map, warnings)` zurück, die beiden echten Aufrufer
  (`format_table_at_cursor`, `format_tables_in_buffer`) melden die Warnungen selbst.
  `format_tables_in_scope`s eigene `notify()`-Aufrufe (Batch-Fortschritt über mehrere Dateien) sind
  bewusst unangetastet geblieben — das ist bereits eine "Orchestrator"-Ebene mit eigener
  Fortschritts-/Aggregations-Verantwortung, kein reiner Low-Level-Helfer, und der einzige Ort mit
  Sicht auf den Gesamtfortschritt über mehrere Dateien.
- **Echter CI-Regressions-Fix, beim Verifizieren gefunden**: `docs/TESTS/format_spec.lua` prüfte
  `column_align` mit handgeschriebenen `'</'>'`-Marks statt einer echten Visual-Selektion — seit
  dem submode-detection-Fix (`5ef85b6`, liest `vim.fn.visualmode()` statt Mark-Geometrie zu raten)
  lieferte `visualmode()` dabei immer `""`, also schlug `align_to_column` in der Suite immer mit
  "No valid visual selection found" fehl. Beide Stellen simulieren jetzt eine echte
  Ein-Zeichen-Visual-Selektion per `normal! v<Esc>`. **Echter Crash-Fix**: `health.lua` rief
  `lib.nvim.usercmd.composer.checkhealth(...)` an vier Stellen ungeschützt auf, obwohl die Datei
  zwei Zeilen darüber selbst per `pcall` prüft, ob lib.nvim fehlt — ohne lib.nvim brach
  `:checkhealth buffer_ctx` mit einem unabgefangenen Fehler ab, bevor die Format-/Mark-Abschnitte
  erreicht wurden. Jetzt hinter demselben `pcall`-Ergebnis gated; mit und ohne lib.nvim verifiziert.

Übersprungen/nicht verifizierbar: nichts — GitHub-Metadaten, `:checkhealth` (beide Varianten),
CI-Status (`gh run list`, vor und nach dem Fix geprüft, jetzt grün) und die zentrale
Bindings-Sammlung waren alle direkt prüfbar. Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/buffer-ctx.md`) war
inhaltlich größtenteils bereits aktuell; `Autocmds/buffer-ctx.md`s "Known issue"-Abschnitt behauptete
noch, `:Mark` schlüssle nach roher Zeilennummer statt Extmark-ID — das war bereits gefixt
(`docs/ROADMAP/anchor-stable-marks.md`, Status "implemented"), korrigiert zu einem
"Previously an issue, now fixed"-Abschnitt; `Usercmds/buffer-ctx.md` um die beiden obigen
Refactoring-Funde ergänzt. Alles committet (`91f7d5b`) und nach `origin/main` gepusht.

### diff.nvim

Größtes bisher geprüftes Plugin (72 Lua-Dateien). Ein Durchlauf wurde durch ein Session-Limit
unterbrochen, direkt nachdem der erste Push bereits erfolgreich war ("Let's watch the new CI
run" war die letzte Nachricht) — der eigentliche Checklisten-Pass war zu diesem Zeitpunkt
bereits vollständig abgeschlossen und gepusht (mehrere Commits, u. a. README-ToC, `stylua.toml`/
`.luacheckrc` neu angelegt + CI-Lint ergänzt, ein In-Memory-Fake-Clipboard für die Headless-Suite,
Typkorrekturen für Source/Target-Params, sowie als Bonus die letzte offene Cross-Plugin-Roadmap-
Aufgabe aus `images.nvim`s `docs/ROADMAP/CROSS-PLUGIN.md`: `:Diff` erkennt jetzt zwei Rasterbild-
Pfade und zeigt sie über `images.nvim`s `gallery()` nebeneinander statt sie sinnlos byteweise zu
text-diffen).

Bei der Fortsetzung fiel auf, dass **CI seit mindestens zehn aufeinanderfolgenden Commits durchgängig
rot war** (`gh run list`, zurück bis 2026-07-31) — zwei echte, vom eigentlichen Checklisten-Pass
unabhängige Infrastruktur-Bugs, nicht durch diesen Rollout verursacht, aber dabei gefunden und
behoben:

- **CI-Fund 1**: `JohnnyMorganz/stylua-action@v4` im `lint`-Job hatte keinen `token`-Parameter
  ("Parameter token or opts.auth is required") — `replacer.nvim`s Workflow hat ihn bereits korrekt
  gesetzt, als Vorlage übernommen.
- **CI-Fund 2**: `stylua.toml` behauptete `line_endings = "Windows"`, aber die tatsächlich in Git
  gespeicherten Blobs sind LF (verifiziert: `git show HEAD:<file> | grep -c $'\r'` == 0 auf
  mehreren Dateien) — auf dem lokalen Windows-Checkout mit `core.autocrlf=true` unsichtbar (Git
  wandelt beim Checkout in CRLF um und beim Commit automatisch zurück in LF), auf dem
  Linux-CI-Runner (kein autocrlf) aber ein Fehlschlag auf buchstäblich jeder Datei. Auf `"Unix"`
  korrigiert.
- **CI-Fund 3**: selbst danach schlug der `tests`-Job weiter fehl, obwohl die Suite sichtbar
  `DIFF_NVIM_TESTS_OK` ausgab (13/13 Specs grün) — der rohe Exitcode von `nvim --headless` selbst
  war auf dem Runner ungleich 0 (Deprecation-Warnungen o. ä., kein Testfehler) und leckte durch die
  Pipe durch. Workflow umgebaut: `nvim ... > out.log 2>&1` statt `| tee out.log`, `set +e` davor,
  einzig `grep -q DIFF_NVIM_TESTS_OK out.log` entscheidet über Erfolg — derselbe Marker-Ansatz wie
  bei allen Schwester-Plugins, nur ohne die Pipe, die den nvim-eigenen Exitcode durchließ. CI danach
  grün (beide Jobs).

Ansonsten deckte der ursprüngliche Pass alle fünf Checklisten ab (PERFORMANCE: kein Hotpath über
das übliche Rendering hinaus; LUA_NVIM: `lib.nvim` durchgängig, `@types` vollständig; REVIEW:
Tooling ergänzt, `@return`-Aritäten stichprobenartig verifiziert; RELEASE: README/doc/BINDINGS/
ROADMAP/`:checkhealth`/GitHub-Metadaten bereits vollständig oder ergänzt, inkl. der
Vimdoc-Tag-Kollisionsprüfung gegen Neovims eingebautes `:h diff`; Refactoring: `notify()`
ausschließlich an Boundary-Stellen). Details zu den einzelnen Codefixen liegen in den
Commit-Messages der oben genannten Commits, nicht redundant hier repliziert.

Übersprungen/nicht verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — jetzt aber
tatsächlich über die reparierte CI grün verifiziert. Alles committet (u. a. `592f202`, `eddbc41`,
`4cb35d4`, `9ceccc6`, `5a98f20`, `daf7173`, `5d8abd8`, `eb0f0f1`, `91316a6`, `ee7b14f`) und nach
`origin/main` gepusht; CI-Status abschließend grün geprüft.

### recommender.nvim

Kleines, bereits sehr sauberes Plugin (24 Lua-Dateien inkl. `plugin/`): durchgängig
`@module`/`@brief`/`@description`, vollständige `@param`/`@return`, ein konsolidiertes
`@types.lua` (bewusste Ausnahme wie bei fileops.nvim/emojis.nvim/dap.nvim — bei diesem Umfang
sinnvoller als Ordner-pro-Unterverzeichnis), `config/DEFAULTS.lua` + `config/init.lua`,
`.luarc.json`/`.luacheckrc`/`stylua.toml`/CI (stylua + luacheck) bereits vorhanden.

- **CI war seit den letzten zwei Pushes durchgängig rot** (`gh run list`) — echter Fund, kein
  Infra-Ghost: `health.lua` hatte eine 180-Zeichen-Zeile (`luacheck`s `max_line_length = 130`
  und `stylua`s `column_width = 130` schlugen beide auf exakt dieselbe Zeile fehl). Umgebrochen
  (String-Konkatenation über zwei Zeilen), danach `stylua --check`/`luacheck` lokal gegen eine
  LF-normalisierte Kopie verifiziert grün (die Windows-Checkout-CRLF-Diskrepanz war sonst
  irreführend — `git show HEAD:<file> | grep -c $'\r'` bestätigte, dass die gespeicherten Blobs
  bereits LF sind, passend zu `stylua.toml`s `line_endings = "Unix"`, keine Config-Änderung
  nötig). Push danach: CI grün (`gh run list`).
- **PERFORMANCE.md**: kein echter Hotpath — `:Recommender` läuft einmal pro Aufruf, auch der
  `-c`/`--cwd`-Projekt-Scan ist ein einmaliger, nutzergetriggerter Vorgang, kein Redraw-/
  Keystroke-Handler. Alle Analyzer bauen Ergebnistabellen bereits per `out[#out+1]` statt
  `table.insert` auf und nutzen `require("lib.lua.tables").dedup_list`. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` ist seit der `usercmd.composer`-Migration
  Pflichtabhängigkeit für `:Recommender`, `notify`/`map` bleiben bewusst weich mit nativem
  Fallback (`util/lib.lua`), Buffer/Window-Handles werden überall validiert (auch in
  `vim.schedule`-Callbacks in `float/keymaps.lua`/`float/autocmds.lua`), `Recommender.Config`
  vollständig typisiert. Keine Änderung nötig.
- **REVIEW.md**: Schnell-Check und Detailprüfung sauber — kein globaler State, Single
  Responsibility pro Modul. §8 Tooling bereits vollständig (`.luarc.json` mit
  `diagnostics.globals=["vim"]`/`workspace.library`, `.luacheckrc`, `stylua.toml`, CI) —
  Vergleich gegen `sessions.nvim`s `.luarc.json` ergab keine funktionale Lücke, nicht angeglichen.
- **RELEASE.md**: `doc/recommender.nvim.txt` → umbenannt zu `doc/recommender.txt` mit
  retagten Abschnitten (`recommender-*` statt `recommender.nvim-*`) plus expliziten
  `*recommender.nvim*`/`*recommender*`-Tags, damit `:h recommender` direkt trifft statt nur
  `:h recommender.nvim-*` (Referenzen in `docs/BINDINGS.md`/`docs/architecture.md` mitgezogen,
  `doc/tags` neu erzeugt). README bekam ein Level-2-only Table of Contents; der
  Schwesterplugin-Absatz (bereits vorhanden: replacer.nvim, wegen `:Replace` in Replace-Mode —
  die im Auftrag vermuteten Kandidaten markdown.nvim/reposcope.nvim treffen laut Code nicht zu)
  wurde direkt nach ASCII-Art/Badges verschoben statt nach dem Beschreibungsabsatz.
  `docs/BINDINGS.md`, `docs/ROADMAP.md` (bewusst leer — "every previously tracked idea has
  shipped"), `:checkhealth recommender` (headless verifiziert: `setup()` + `health.check()`
  liefen fehlerfrei durch) bereits vollständig. GitHub-Metadaten (`gh repo view`) bereits gesetzt:
  Description, 6 Topics, Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention),
  keine LICENSE-Datei/-Referenz. Cross-Plattform: keine hartkodierten Pfadtrenner —
  `project.lua`s einziger `[/\\]`-Treffer ist eine Zeichenklasse zum *Erkennen* beider Trenner in
  `vim.split`, kein Join; `vim.fn.globpath`/`vim.fn.readfile` sind bereits plattformneutral.
  Ebenfalls stylua-only gefixt: `plugin/recommender.lua` (One-Liner-Guard → Mehrzeiler) und
  `plugin/recommender_autodoc.lua` (inline `pcall`-Closure → Mehrzeiler) — beide erst nach
  Ausschluss der CRLF-Artefakte als echte Findings sichtbar.
- **Refactoring.md**: Fail-late/Report-at-boundary war bereits vollständig eingehalten — alle
  `notify()`-Aufrufe sitzen ausschließlich in `bindings/usrcmds.lua` (Command-Dispatch) und
  `float/keymaps.lua` (UI-Schicht); `blacklist.lua`, `project.lua`, `custom_aliases.lua`,
  `config/*`, alle `analyzers/*` geben durchweg nur Werte/Status zurück, kein `notify()`. Keine
  Änderung nötig.

Übersprungen/nicht verifizierbar: kein Test-Runner im Repo (kein `tests/`/`TESTS/`) — per
Headless-`require()`-Smoke-Test aller 22 `lua/recommender/**`-Module plus `setup()`/
`health.check()` ersetzt, alle grün. POSIX-Test nicht lokal möglich (Windows-Umgebung) —
über die (jetzt grüne) `ubuntu-latest`-CI verifiziert. Alles committet (`65b4c19`) und nach
`origin/main` gepusht; CI-Status abschließend grün geprüft.

### pickers.nvim

Größtes bisher geprüftes Plugin nach diff.nvim (77 Lua-Dateien) und bereits durch mehrere eigene
Checklisten-Runden gelaufen (`docs/ROADMAP/{schnell-check,arch-coding,zentrale-prinzipien}.md`,
alle mit Datum/Begründung) — `@module`/`@brief`/`@description` durchgängig, `@param`/`@return`
vollständig, `@types` pro Unterverzeichnis, `config/DEFAULTS.lua` + `config/init.lua` mit
typisierten Keys, `.luarc.json` (`diagnostics.globals=["vim"]`, `workspace.library`, identisch zum
`sessions.nvim`-Muster), `.luacheckrc`, `stylua.toml`, CI (stylua + luacheck + headless
`docs/TESTS/pickers_spec.lua`, 296 Assertions) bereits vorhanden.

- **CI war seit mindestens 5 Commits durchgängig rot** (`gh run list`) — derselbe Infra-Bug-Typ wie
  bei `diff.nvim`/`recommender.nvim`, aber eine dritte Variante: `stylua-action@v4` war auf
  `version: latest` gepinnt, und ein neuerer stylua (2.5.2 lokal) formatiert einige Konstrukte
  (Single-Line-`if`-Bodies, `kit.input`-Call-Argumente) anders als die Version, mit der zuletzt
  committet wurde — reproduziert via `git show HEAD:<file> | stylua --check -` (CRLF-frei, damit
  kein `core.autocrlf`-Rauschen). Mit dem lokal installierten stylua neu formatiert (17 Dateien
  mit echtem Diff, verifiziert gegen `git diff --stat`) und die CI-Action auf `v2.5.2` gepinnt,
  damit das nicht erneut lautlos drifted. Danach deckte der jetzt tatsächlich laufende
  `luacheck`-Schritt (vorher durch den fehlschlagenden stylua-Schritt maskiert, da beide Schritte
  im selben `lint`-Job liegen) einen zweiten, unabhängigen Fund auf: `docs/TESTS/pickers_spec.lua`
  stubbt `vim.fn.executable` (read-only field) für den `sources.system`-Test — mit
  `-- luacheck: push/pop ignore 122` lokal um genau den Stub-Block eingegrenzt, statt einer
  Repo-weiten `.luacheckrc`-Regel. CI danach zweimal grün geprüft.
- **PERFORMANCE.md**: einziger ernsthafte Hotpath-Kandidat ist `pickers.smart.query`
  (`lua/pickers/smart/{init,score,search}.lua`) — läuft pro Tastenanschlag der "smart"-Aktion
  (kombiniertes Grep+Find, live). Bereits sauber: `items[#items+1]` statt `table.insert` überall,
  `string.format`/`table.concat` statt `..`-Loops, kein unnötiges Pre-Allocate nötig (Größe
  hängt von Query ab). Die fd/rg-Subprozessaufrufe sind bewusst synchron
  (`vim.system():wait(timeout)`, im Modulkommentar begründet: die Engines selbst debouncen die
  Live-Eingabe, ein geteilter synchroner Kern ist portabler als drei Async-Streaming-
  Integrationen). Keine Änderung nötig — sonst kein Hotpath (alles läuft on-demand über
  `:Pickers`).
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig (`notify`, `map` über
  `bindings/util.lua`, `usercmd.composer`, `autocmd`, `cross`), saubere Importreihenfolge,
  `Pickers.Config` vollständig typisiert. Keine Änderung nötig.
- **REVIEW.md**: Schnell-Check/Detailprüfung bereits sauber laut eigenen Audit-Dateien, stichprobenartig
  gegencheckt — kein globaler State (nur die zwei dokumentierten `vim.g.pickers_nvim_*`-Load-Guards),
  Single Responsibility pro Modul. §8 Tooling: `.luarc.json` bereits vorhanden und äquivalent zu
  `sessions.nvim`s Version — nicht angeglichen (kein funktionaler Gap). Der einzige echte Fund war
  der CI-Drift oben (§8 Tooling: Formatter/Linter im CI).
- **RELEASE.md**: README hatte ASCII-Art, Badges und den Schwesterplugin-Absatz (insights.nvim)
  bereits korrekt — nur das Level-2-only Table of Contents fehlte, ergänzt. `doc/pickers.txt` (15
  Abschnitte), `docs/ROADMAP.md` (aktiv gepflegt, sehr ausführlich), `:checkhealth pickers`
  (headless verifiziert, läuft fehlerfrei durch, differenziert korrekt zwischen `ok`/`warn`/`error`)
  bereits vollständig. **`docs/BINDINGS.md` war unvollständig** (RELEASE.md §1, KRITISCH) — fehlten:
  drei Usercmds (`:PickersRepeat`/`:PickersScopes`/`:PickersResume`, in `ROADMAP.md`/`usrcmds.lua`
  längst vorhanden, aber nie ins Bindings-Sheet übernommen), die komplette `keys`-In-Picker-Namespace
  (12 Aktionen: preview scroll/history/entry actions/preview_toggle/split/vsplit/tab — nur in
  `docs/KEYMAPS.md` dokumentiert), `experimental.selected_index.toggle_key`, sowie die
  `selected_index`- (3 Autocmds) und `smart.frecency`-Autocmd-Gruppen (2 Autocmds) — nur der
  `VimEnter`-Fallback war gelistet. Alle ergänzt (Details unten). GitHub-Metadaten (`gh repo view`)
  bereits vollständig: Description, 8 Topics, Default-Branch `main`, leeres Homepage-Feld
  (Schwester-Plugin-Konvention), keine LICENSE-Datei/-Referenz. Cross-Plattform: keine hartkodierten
  Pfadtrenner (Grep über `lua/` negativ); Pfad-Joins laufen konsequent über `vim.fs.normalize`.
- **Refactoring.md**: Fail-late/Report-at-boundary bereits eingehalten laut eigener Audit-Datei
  (`docs/ROADMAP/arch-coding.md`) — stichprobenartig gegen `engines/*`, `sources/*`,
  `entry_actions/*`, `config/init.lua` gegengecheckt: alle `notify()`-Aufrufe sitzen an der
  jeweiligen Dispatch-/Setup-Grenze (Engine-Wrapper-Funktionen, die direkt vom Command-Dispatcher
  aufgerufen werden; Config-Normalisierung, die einmalig bei `setup()` läuft), nie in echten
  Low-Level-Helfern wie `smart/score.lua`/`smart/search.lua` (rein pure/`(ok, err)`-Rückgaben,
  kein `notify()`). Keine Änderung nötig.

Zusätzlich zentrale Bindings-Sammlung (`nvim/docs/NOTES/PersonelPlugins/BINDINGS/`) geprüft: alle
drei Dateien (`Keymaps`/`Usercmds`/`Autocmds`/`pickers.nvim.md`) waren bereits von einer eigenen,
sehr ausführlichen `2026-07-26`-Roadmap-Runde gepflegt und inhaltlich vollständig — sie hatten den
`docs/BINDINGS.md`-Rückstand oben bereits selbst als offenen Punkt vermerkt (⚠️-Hinweise in
`Keymaps/pickers.nvim.md` und `Autocmds/pickers.nvim.md`). Diese Hinweise auf "jetzt behoben"
aktualisiert, keine inhaltlichen Ergänzungen nötig (die zentralen Dateien waren bereits
vollständiger als das Repo-eigene `docs/BINDINGS.md`).

Übersprungen/nicht verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — über die
(jetzt grüne) `ubuntu-latest`-CI verifiziert. `CHEATSHEET.md` (erwähnt in `docs/KEYMAPS.md`'s
Cross-Reference als evtl. veraltet) nicht geprüft — außerhalb des RELEASE.md-Pflichtumfangs
(nur `BINDINGS.md` ist dort explizit gefordert). Alles committet (`fde104d`, `e273eb9`, `8f96abb`)
und nach `origin/main` gepusht; CI-Status abschließend zweimal grün geprüft.

### gopath.nvim

79 Lua-Dateien, bereits durch eine eigene, ausführliche Checklisten-Runde gelaufen (siehe
`docs/ROADMAP.md`s "Qualität & Checklist-Audits", Stand 2026-07-04, plus mehrere Folge-Commits
bis 2026-08-04) — dieser Pass fand entsprechend fast nichts mehr offen: `@module`-Kopfzeilen
durchgängig, `@param`/`@return` vollständig (jedes `fun(...)`-Annotation im Repo bereits mit
benannten Parametern — kein `fun(Type)`-Bug wie zuvor bei pickers.nvim gefunden), `@types` pro
Unterverzeichnis, `config/DEFAULTS.lua` + `config/init.lua` mit vollständig typisierten Keys
(`@types/config.lua`), `.luarc.json` (identisch zu `sessions.nvim`s Version), `.luacheckrc`,
`stylua.toml`, CI (stylua + luacheck + headless `scripts/ci/headless_tests.lua`, klont `lib.nvim`
und führt jedes `docs/TESTS/*.lua`-Fixture aus) bereits vorhanden und grün.

- **PERFORMANCE.md**: kein neuer Hotpath-Fund — `truncated/cache.lua`/`finder.lua`s
  Dateisystem-Scans laufen asynchron beim (gedrosselten) Cache-Build, nicht pro Tastenanschlag;
  `env_path.lua`/`linepath.lua` laufen einmal pro Resolve-Aufruf. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig (`map`, `autocmd`,
  `usercmd.composer`, `ui.kit`, `cross`), `util/cross.lua`/`util/log.lua` degradieren bewusst
  dokumentiert auf eingebaute Fallbacks statt zu erroren, GOPATH/GOROOT- bzw. `$VAR`-Auflösung in
  `resolvers/common/env_path.lua` prüft sowohl `vim.env` als auch `os.getenv` und normalisiert
  Backslash/Forward-Slash beidseitig. Keine Änderung nötig.
- **REVIEW.md**: Schnell-Check/Detailprüfung sauber — `notify()` beschränkt sich bereits auf
  `util/log.lua`/`util/safe_notify.lua` (die dedizierten Wrapper-Module selbst), kein
  Low-Level-Fund. `luacheck lua plugin` lief mit 0 Warnings/Errors über 73 Dateien;
  `stylua --check .` fand nur einen Diff in `docs/TESTS/02_tailsearch.lua` (Test-Fixture mit
  Kommentar-Doku-Stil, außerhalb des CI-Scopes `stylua --check lua/ plugin/`) — nicht angefasst,
  da nicht Teil des tatsächlichen CI-Checks und der abweichende Stil dort absichtlich lesbarer
  Dokumentationstext ist.
- **RELEASE.md — die beiden einzigen echten Funde dieses Passes**: `doc/gopath.txt`s
  Installationsblock hatte die `StefanBartl/lib.nvim`-Dependency vergessen (README.md hatte sie
  korrekt) — ergänzt. README.md fehlte das geforderte Level-2-only Table of Contents — ergänzt.
  `docs/BINDINGS.md`, `docs/ROADMAP.md`, `:checkhealth gopath` bereits vollständig und aktuell.
  GitHub-Metadaten (`gh repo view`) bereits vollständig gesetzt: Description, 7 Topics,
  Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention), keine
  LICENSE-Datei/-Referenz. Cross-Plattform: `util/cross.lua` delegiert an `lib.nvim.cross` mit
  dokumentiertem Fallback; `env_path.lua` behandelt Windows-Laufwerksbuchstaben und
  POSIX-`$VAR`-Auflösung explizit und symmetrisch.
- **Refactoring.md**: Fail-late/Report-at-boundary bereits vollständig eingehalten (laut
  `docs/ROADMAP.md` bereits 2026-07-04 durchgeführt) — verifiziert per Grep: `notify()`
  ausschließlich in den beiden Wrapper-Modulen, alle Resolver/Util-Module geben nur
  `GopathResult|nil` bzw. Status zurück. Keine Änderung nötig.

Zusätzlich zentrale Bindings-Sammlung (`nvim/docs/NOTES/PersonelPlugins/BINDINGS/`) geprüft: alle
drei Dateien (`Keymaps`/`Usercmds`/`Autocmds`/`gopath.nvim.md`) waren bereits aktuell und
kreuzreferenziert gegen `docs/BINDINGS.md` (Stand 2026-07-31), keine Änderung nötig.

Übersprungen/nicht verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — über die
(grüne) `ubuntu-latest`-CI verifiziert. Alles committet (`fb7ae24`) und nach `origin/main`
gepusht; CI-Status vor und nach dem Push grün geprüft.

### mdview.nvim

87 Lua-Dateien (Neovim-Seite eines größeren Go-Relay/Rust-WASM/TypeScript-Projekts).
`stylua --check .`/`luacheck lua/mdview --no-color` liefen vorher bereits grün, aber CI hatte
gar keinen Format-Check-Job — nur `luacheck` + `busted` + headless-nvim-Specs. Beim lokalen
`stylua`-Lauf stellte sich heraus, dass rund 35 Dateien tatsächlich auf 2-Space-Einrückung statt
der im restlichen Repo durchgängigen Tabs gedriftet waren (kein `stylua.toml` vorhanden, also kein
verbindlicher Maßstab) — mit `stylua.toml` (Tabs, matching Konvention) neu formatiert, plus
eigenem `stylua`-CI-Job (`JohnnyMorganz/stylua-action@v4` inkl. `token`, um den in diesem Rollout
schon einmal gefundenen Bug von Anfang an zu vermeiden).

- **PERFORMANCE.md**: zwei echte Hotpaths — `live_push.lua` (`TextChanged`/`TextChangedI`) und
  `scroll_sync.lua` (`CursorMoved`/`CursorMovedI`); beide bereits throttled/debounced aus einem
  vorherigen Commit (`perf(live-push): throttle TextChanged/TextChangedI pushes`), inkl. Trailing-
  Timer statt Drop, damit kein Content-Push verloren geht. `breadcrumbs.lua`s Autocmd (ebenfalls
  auf `CursorMoved`) ist laut eigenem Docstring ebenfalls throttled. Keine Änderung nötig.
- **LUA_NVIM.md**: `lib.nvim` durchgängig genutzt (`notify`, `usercmd.composer`, u. a.). Gefundener
  echter Bug: `types/adapter.lua`s `try_resolve fun(string): boolean` — bare-type ohne Namen vor
  dem Typ (derselbe Bug-Musterfund wie zuvor achtfach in `pickers.nvim`), zu
  `fun(cmd: string): boolean` korrigiert. Repo-weiter Grep nach weiteren `fun(<Type>` ohne Namen
  ergab keine weiteren Treffer.
- **REVIEW.md**: Schnell-Check größtenteils sauber; `.luarc.json` mit `diagnostics.globals=vim`
  bereits vorhanden, keine Änderung nötig.
- **RELEASE.md**: README bekam ein fehlendes Level-2-only Table of Contents sowie (nach der
  ASCII-Art) einen `>`-Absatz mit Verweis auf das Schwesterplugin `markdown.nvim` (laut
  `docs/companion-plugins.md` der offizielle "recommended companion"). `docs/BINDINGS.md` fehlten
  zwei Befehle (`:MDView standalone`, `:MDView blanklines`) — ergänzt; alles andere (Autocmds,
  Keymaps-Aussage "keine") war bereits vollständig. `docs/ROADMAP.md` neu angelegt (bisher gab es
  nur das ausführliche deutsche Ingenieurslog unter `docs/Roadmap/Roadmap.md`, das unverändert
  bleibt und von der neuen Datei aus verlinkt wird). `:checkhealth mdview` per Headless-Smoke-Test
  verifiziert (keine ERROR-Zeilen). GitHub-Metadaten bereits vollständig (Description, 20 Topics,
  Default-Branch `main`, leeres Homepage-Feld). Einzige echte Abweichung von der
  Schwesterplugin-Konvention: eine `LICENSE`-Datei (MIT) samt `"license": "MIT"` in `package.json`
  existierte noch — beides entfernt, damit das Repo der repo-übergreifenden
  "keine Lizenzdatei/-referenz"-Konvention entspricht (verifiziert: `sessions.nvim`/`pickers.nvim`
  haben ebenfalls keine). Cross-Plattform: kein hartkodierter Pfadtrenner im Lua-Code gefunden.
- **Refactoring.md**: zwei echte Funde in `core/state.lua` (Low-Level-Statusmodul) —
  `update_web()` notifizierte bei einem fehlgeschlagenen Callback direkt statt den Fehler
  zurückzugeben (keine externen Aufrufer betroffen, daher gefahrlos auf `(state, err)` erweitert);
  `ensure_proc_started()` notifizierte redundant zusätzlich zum Aufrufer
  (`bindings/usrcmds/start/init.lua`), der bei `nil` bereits selbst notifiziert — Notify entfernt,
  `err` als zweiten Rückgabewert durchgereicht, Aufrufer nutzt ihn jetzt für eine präzisere
  Meldung. Beide Male Rückgabe-Arität nach der Änderung gegen jeden tatsächlichen `return` erneut
  geprüft. `adapter/runner.lua`s zwei `notify()`-Aufrufe (Prozess-Spawn-Fehler) waren ebenfalls
  redundant zum Aufrufer und wurden auf `log.append()` umgestellt. Bewusst NICHT angefasst:
  `adapter/runner.lua`s übrige `notify()`-Aufrufe in den async Exit/stdout/stderr-Callbacks (keine
  wartende aufrufende Funktion vorhanden — dort ist der Callback selbst die Grenze) sowie
  `adapter/preview_tab.lua`/`adapter/inbound_poll.lua` (einzelne, klar umrissene Aktionsfunktionen
  ohne weitere Aufrufer-Kette).

Zentrale Bindings-Sammlung (`nvim/docs/NOTES/PersonelPlugins/BINDINGS/`) geprüft: alle drei
Dateien (`Keymaps`/`Usercmds`/`Autocmds`/`mdview.nvim.md`) bereits vollständig und aktuell
(inkl. `standalone`/`blanklines`), keine Änderung nötig.

Verifiziert: `stylua --check lua tests` grün, `luacheck lua/mdview --no-color` 0 Warnings/0
Errors, headless-nvim-Testsuite (`tests/nvim/harness.lua`, 24 Specs) grün, Modul-Require-Smoketest
über alle 87 Dateien unter `lua/mdview/` (einzige "Failure": `mdview.lps`, das optionale
`lspconfig` erwartet — erwartetes Verhalten, kein Bug), `:checkhealth mdview` ohne ERROR-Zeilen.
`busted` selbst war lokal nicht installierbar (Windows, kein `luarocks`-Setup) — die reinen
Lua-Specs unter `tests/lua/` liefen daher nicht lokal, nur über CI (grün). Übersprungen/nicht
verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — über die grüne
`ubuntu-latest`-CI verifiziert. Alles committet (`7f1cc17`) und nach `origin/main` gepusht;
CI-Status vor und nach dem Push grün geprüft (Laufzeit ca. 2 Minuten).

### markdown.nvim

91 Lua-Dateien. Codebase war größtenteils bereits sehr sauber (durchgängiges `lib.nvim`, saubere
`@module`/`@class`/`@param`/`@return`-Annotationen, konsolidierte `@types/init.lua` nach
Quelldatei gruppiert, typisierte Config-Keys, `config/init.lua` + `config/DEFAULTS.lua`) —
CI stand aber bei jedem Push der letzten Woche auf Rot (`gh run list` zeigte durchgängig
`failure`), das war der eigentliche Kern der Arbeit.

- **PERFORMANCE.md**: keine echten neuen Hotpaths gefunden, die nicht schon behandelt sind
  (`core/table_mode.lua` debounced bereits über `lib.nvim.debounce`). Keine Änderung.
- **LUA_NVIM.md**: bereits konform; `fun(` Grep über `lua/` ergab keine bare-type-Treffer (der in
  diesem Rollout achtfach in `pickers.nvim` und einmal bereits in mdview.nvim gefundene
  Annotations-Bug trat hier nicht auf).
- **REVIEW.md**: `.luarc.json` (`diagnostics.globals=vim`, passend zu `sessions.nvim`) und
  `.luacheckrc` bereits vorhanden. `luacheck lua` lieferte 7 echte Warnings — behoben: zwei
  Dead-Stores in `core/toc.lua`/`core/headline_spacing/init.lua` (Werte berechnet, nie gelesen),
  drei `path`-Parameter, die den modulweiten `path`-Require in `handler/file.lua`/`handler/init.lua`
  verschatteten (umbenannt zu `p`), zwei ungenutzte `pcall`-Rückgaben in `util/platform.lua`
  (`_`-Präfix + neue `211/_.*`-Ignore-Regel in `.luacheckrc`, analog zur bestehenden `212/_.*`).
  Zwei absichtlich leere `if`-Zweige in `util/path.lua` (selbstdokumentierender No-op, exakt wie
  im lib.nvim-Original) per gezieltem `-- luacheck: push/pop ignore 542` stehen gelassen statt
  umgebaut. `stylua --check .` schlug lokal **für fast das gesamte Repo** fehl — `stylua.toml`
  fehlte `collapse_simple_statement`, dessen Default (nie kollabieren) dem tatsächlich
  durchgängig genutzten Ein-Zeilen-`if`-Stil widersprach; `collapse_simple_statement = "Always"`
  ergänzt und mit `stylua .` neu formatiert (79 Dateien, reiner Formatierungs-Commit getrennt vom
  Bugfix-Commit).
- **RELEASE.md**: README bereits vollständig (ASCII-Art, Badges, ToC nur Level-2, `>`-Absatz mit
  Verweis auf `cascade.nvim` als Schwesterplugin — laut Code teilen sie sich die Dokumentstruktur:
  markdown.nvim rendert/strukturiert, cascade.nvim editiert Listeninhalte). `doc/markdown.nvim.txt`
  vermeidet den bloßen `markdown`-Tag bewusst (`markdown.nvim-*`-Namespace, Dateiname
  `markdown.nvim.txt`) — keine Kollision mit Neovims eingebautem `:h markdown`. `docs/BINDINGS.lua`
  (bewusste `.lua`- statt `.md`-Form, maschinenlesbar) bereits aktuell bis zum letzten Feature-Commit
  (TableView-Row-Move + `:w`-Write-back). `docs/ROADMAP.md` gepflegt (erledigte Punkte durchgestrichen
  markiert). `:checkhealth markdown` per Headless-Smoke-Test verifiziert: mit geladenem
  `filetype plugin` + geöffnetem `.md`-Puffer vollständig grün (11/11 `:Markdown`-Routen `OK`); ohne
  Dateityp-Erkennung (reiner `-u NONE`-Automatisierungsartefakt, kein Plugin-Bug) meldet es korrekt
  "verb 'Markdown' is not registered", weil die Registrierung absichtlich `FileType`-gated ist
  (siehe README: "Pure FileType-scoped — zero side effects on non-Markdown buffers"). GitHub-Metadaten
  bereits vollständig (Description, 10 Topics, Default-Branch `main`, leeres Homepage-Feld, keine
  Lizenzdatei). Cross-Plattform: kein hartkodierter Pfadtrenner gefunden; ein echter
  Cross-Plattform-Bug in `util/path.lua` behoben (siehe Refactoring/Bugfix-Absatz unten).
- **Refactoring.md**: `notify()`-Aufrufe durchgesehen — die gefundenen Stellen sitzen bereits in
  Controller-/Boundary-Schicht (`handler/*.lua`s öffentliche `M.open`/`M.jump`-Einstiegspunkte,
  `commands/*.lua`), nicht in echten Low-Level-Utilities; `util/path.lua` (das eigentliche
  Low-Level-Modul für Pfadauflösung) hat konsequent keinen einzigen `notify()`-Aufruf. Keine
  Verschiebung nötig.

**Echte Bugs gefunden und behoben** (nicht nur Stil): `util/path.lua`s `normalize()`/`resolve()`/
`resolve_traced()` riefen `vim.fn.expand()` **vor** der Backslash→Slash-Vereinheitlichung auf —
`expand()` behandelt einen nackten Backslash als Escape-Zeichen (verschluckt ihn, behält das
Folgezeichen), wodurch `"a\b\c"` zu `"abc"` statt `"a/b/c"` wurde; von `TESTS/path_spec.lua` in CI
aufgedeckt (Linux-Runner, daher nicht durch lokales `core.autocrlf` maskiert). Reihenfolge getauscht.
Zweiter Fund: ein absoluter Pfad mit Windows-Laufwerksbuchstaben (`C:/...`) hatte auf Nicht-Windows
keinen Fallback — ein Link, der `C:/...` referenziert (z. B. von Windows übernommene Notizen), schlug
auf POSIX immer fehl, selbst wenn dieselbe Datei ohne Laufwerksbuchstaben existiert; neue
`drive_fallback_if_exists()` behandelt das (nur auf Nicht-Windows, nur wenn der Pfad mit
Laufwerksbuchstabe selbst nicht existiert). Beide von `TESTS/handler_spec.lua`/`path_spec.lua`
aufgedeckt und jetzt grün. Dritter Fund, der eigentliche Ursache für die rote CI: `.github/
workflows/ci.yml`s `stylua-action@v4` fehlte der inzwischen von der Action geforderte `token`-Input
— schlug mit "Parameter token or opts.auth is required" fehl, bevor `stylua` überhaupt lief; `token`
ergänzt und Version von `latest` auf die lokal installierte `v2.5.2` gepinnt (Lehre aus diesem
Rollout: `latest` driftet sonst unbemerkt vom committeten Stil).

Zentrale Bindings-Sammlung (`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/
markdown.nvim.md`) geprüft: alle drei Dateien bereits vollständig und aktuell bis zum letzten
Feature-Commit (TableView-Row-Move/`:w`-Write-back vom 2026-08-08), keine Änderung nötig.

Verifiziert: `stylua --check .` grün, `luacheck lua` 0 Warnings/0 Errors, headless-nvim-Testsuite
(`TESTS/run.lua`, 20 Specs inkl. der beiden zuvor roten) grün. `:checkhealth markdown` grün (siehe
oben). Zwei Commits (`0dc5a46` Formatierung, `d8e05fb` Bugfixes) nach `origin/main` gepusht;
CI-Status vor (rot, seit mind. acht aufeinanderfolgenden Pushes) und nach dem Push (grün, beide Jobs
`tests`/`lint`) verifiziert.

### cmdlog.nvim

Kein `.github/workflows`, `stylua.toml`, `.luacheckrc` oder Testsuite vorhanden — komplett neu
angelegt (angelehnt an `pickers.nvim`, das nächstähnliche Schwester-Plugin: gleiche
`stylua.toml`-Werte, `lint`/`test`-Zweiteilung in der CI). 38 Lua-Dateien (nicht 94 wie ursprünglich
angenommen), `.luarc.json` war bereits vorhanden und korrekt.

- **PERFORMANCE.md — einziger echter Hotpath**: `core/tracker.lua`s `CmdlineLeave`-Autocmd feuert
  bei jedem `:`-Befehl. Zwei Funde: `project_history.get_git_root()` rief synchron `git rev-parse
  --show-toplevel` als Subprozess auf `bei jedem einzelnen Befehl` auf — jetzt per cwd über
  `lib.nvim.cache.memory` (ttl=3s) gecacht, wie in PERFORMANCE.md unter "Cache-Regeln" gefordert.
  Zusätzlich liefen `project_history.record()`/`stats.record()` (je ein synchroner JSON-Encode +
  Disk-Write) inline im Autocmd-Callback — jetzt in denselben `vim.schedule()` verschoben, der
  ohnehin schon für den `v:errmsg`-Check nötig war (Timing/Verhalten unverändert, nur nicht mehr auf
  dem synchronen Pfad).
- **LUA_NVIM.md**: `lua/cmdlog/@types/init.lua` fehlten `favorite_tags_path`/`project_history_path`/
  `stats_path`/`errors_path`/`track_commands` komplett in `CmdlogConfig`, `CmdlogMappingsConfig`
  fehlte `tag`, und `CmdlogKeymapsConfig` beschrieb noch die alte Fixed-Field-Form
  (`enabled`/`cmdlog`/`cmdlog_full`/...) statt der tatsächlichen `table<string,string>`-Subcommand-
  Map nach dem entsprechenden Refactor — alle vier behoben. Direkte `vim.notify()`/`vim.keymap.set()`-
  Aufrufe (3 Picker-Module, `integrations/which_key.lua`) auf `lib.nvim.notify`/`lib.nvim.map`
  umgestellt.
- **REVIEW.md §8 Tooling**: siehe oben (komplett neu angelegt). `stylua`/`luacheck` liefen danach
  sauber, bis auf zwei echte Funde beim ersten `luacheck`-Lauf: `ui/telescope-previewer.lua` rief
  ein nirgends definiertes globales `Job:new(...):start()` auf — ein Überbleibsel der
  plenary.nvim-Entfernung (der Rest der Datei nutzt bereits `local job =
  require("lib.nvim.system.job")`), hätte bei der ersten `:help`-/`:term`-Preview mit "attempt to
  index a nil value" abgestürzt; auf `job.start(...)` umgestellt. `ui/telescope/notes_picker.lua`
  enthielt toten Code (`attach_notes`/`get_selected_command`, nirgends aufgerufen — das Modul selbst
  ist komplett unverdrahtet, `M.open()` wird von keiner anderen Datei referenziert; als eigenständige
  Funktion belassen statt entfernt, da das eine Produktentscheidung wäre, keine reine
  Compliance-Frage) — die beiden toten privaten Funktionen entfernt, dadurch wurde auch der lokale
  `api`/`action_state`-Alias ungenutzt und mit entfernt.
- **RELEASE.md**: `doc/cmdlog.nvim.txt` → `doc/cmdlog.txt` umbenannt, alle `*nvim-cmdlog-*`-Tags zu
  `*cmdlog-*` (plus `*cmdlog.nvim*`) — `:h cmdlog` funktionierte vorher nicht, da nur `nvim-cmdlog*`-
  Tags existierten; `doc/tags` per `:helptags doc` neu erzeugt. LICENSE-Datei und alle
  Lizenz-Referenzen (README-Badge/-Abschnitt, `doc/cmdlog.txt`s LICENSE-Block) entfernt — kein
  anderes Plugin im Ökosystem hat eine. Stale `favorites.json`-Pfadangabe (`nvim-cmdlog/` bzw.
  `cmdlog.nvim/` statt des tatsächlichen `cmdlog/`) in README/`docs/COMMANDS.md`/`docs/OPTIONS.md`/
  `doc/cmdlog.txt` korrigiert. README hatte unter "Option 3: Lazy-load on specific event" einen
  kaputten Lua-Codeblock (fehlendes `end,` und schließende `}` — wäre als lazy.nvim-Spec nicht
  geladen worden), repariert. `ui/fzf-previewer.lua` implementiert tatsächlich Previews (über
  externe Shell-Kommandos wie `head`/`nvim -u NONE | redir`) — README/`doc/cmdlog.txt` behaupteten
  fälschlich, fzf hätte gar keine Preview-Unterstützung; korrigiert zu "POSIX only", und der
  Previewer selbst gibt jetzt unter Windows `nil` zurück statt ein kaputtes Shell-Kommando
  auszuliefern (kein `head`/`tail`-Äquivalent garantiert). `gh repo edit --homepage ""` — zeigte
  vorher auf die eigene alte "nvim-cmdlog"-URL des Repos selbst; Description/Topics/Default-Branch
  (`main`) waren bereits korrekt.
- **Refactoring.md**: `core/shell.lua`s `get_shell_history_path()` rief bei Erkennungsfehlern
  `notify.warn()` direkt auf, obwohl das Modul sowohl von Pickern als auch von `cmdlog.health`
  wiederverwendet wird — `:checkhealth cmdlog` hätte bei fehlgeschlagener Shell-Erkennung sowohl ein
  `vim.notify` als auch ein `health.warn` für denselben Zustand ausgelöst. Alle vier `notify.warn()`-
  Aufrufe entfernt, Funktion gibt jetzt nur noch Status (`""`) zurück; `cmdlog.health` hat bereits
  sein eigenes `vim.health.warn()` für exakt diesen Fall. `core/store.lua`/`core/favorites.lua`s
  `notify.error()` bei Schreibfehlern bewusst nicht verschoben — beides sind fire-and-forget-
  Autocmd-Handler ohne Rückgabewert-Prüfung an den Call-Sites; ein echtes Verschieben an die Grenze
  hätte entweder mehrschichtiges Plumbing durch mehrere Aufrufer oder stillschweigend verschluckte
  I/O-Fehler bedeutet — als bewusste Ausnahme belassen und im Abschlussbericht vermerkt.

Kein `docs/TESTS`/Testframework vorhanden — `docs/TESTS/smoke_spec.lua` neu angelegt
(`require()` aller 38 Module, `setup({})`, `bindings.catalog()`, `core.utils`-Pure-Functions,
`cmdlog.health.check()`); die beiden telescope-abhängigen Module werden geskippt statt zu scheitern,
wenn telescope.nvim nicht im Runtimepath liegt (lazy-required, kein Hard-Dependency zur Ladezeit).
CI checkt zusätzlich telescope.nvim + plenary.nvim als Siblings aus, damit diese beiden Module dort
tatsächlich mitgetestet werden. Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/cmdlog.nvim.md`) geprüft und
bereits deckungsgleich mit `docs/BINDINGS.md` im Repo befunden — keine Änderung nötig.

Übersprungen/nicht verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — verifiziert
über CI (`ubuntu-latest`, 2 Jobs `lint`/`test`), die nach dem Push grün lief. Vier Commits
(`9dd3af5` Tooling/CI/Tests, `7e1c1c2` Bugfixes, `f0c7616` Performance, `0d67271` Refactoring/Docs)
nach `origin/main` gepusht; CI-Status nach dem Push verifiziert grün (beide Jobs).

### color_my_ascii.nvim

Bereits eines der saubersten geprüften Plugins: 100 Lua-Dateien, durchgängig `@module`-Kopfzeilen
mit vollständigen `@param`/`@return`, ein konsolidiertes `lua/color_my_ascii/@types.lua`
(bewusste Ausnahme wie bei fileops.nvim/emojis.nvim, sauber nach Quelldatei gruppiert),
`config/DEFAULTS.lua` + `config/init.lua` mit vollständig typisierter `ColorMyAscii.Config`,
`.luarc.json` (identisch zu `sessions.nvim`s), `.luacheckrc`/`stylua.toml`/CI (`stylua` +
`luacheck`) bereits vorhanden, `lua/color_my_ascii/utils/safe_api.lua` bereits ein reiner
Re-Export von `lib.nvim.safe_api` (kein Eigenbau). Kein `fun(type)`-ohne-Namen-Fund (der
copy-paste-Bug aus pickers.nvim/mdview.nvim/markdown.nvim) — alle `fun(...)`-Annotationen hier
haben bereits benannte Parameter.

- **PERFORMANCE.md**: kein neuer Hotpath-Fund über den bestehenden Debounce/Extmark-Pfad hinaus
  (`highlighter.lua`/`debounce_manager.lua`) — bereits sauber implementiert. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten. Keine Änderung nötig.
- **REVIEW.md §8 Tooling — der einzige echte CI-Fund dieses Passes**: `gh run list` zeigte die
  letzten zehn `Lint`-Runs auf `main` durchgehend `failure` (seit dem Commit vom 2026-08-04).
  Ursache war kein CRLF/`.stylua.toml`-Problem (Blobs waren bereits reines LF; die lokale
  CRLF-Anzeige kam nur vom Windows-Checkout mit globalem `core.autocrlf=true` — durch temporäres
  `core.autocrlf=false` + `git checkout` lokal reproduziert, um echte von Checkout-bedingten Diffs
  zu trennen), sondern ein echter `stylua`-Fund: `debug/commands.lua` hatte kollabierte
  Tabellen-Literale (`{ path = {...}, ... }` einzeilig) entgegen `.stylua.toml`s
  `collapse_simple_statement = "Never"`. Mit `stylua lua/ plugin/` reformatiert (nur diese eine
  Datei änderte sich inhaltlich). Zusätzlich `stylua-action` von `version: latest` auf die lokal
  installierte `v2.5.2` gepinnt (bekanntes Drift-Risiko aus früheren Pässen). `.gitattributes`
  (`*.lua text eol=lf`, ...) ergänzt, damit künftige Commits nicht erneut plattformabhängig
  divergieren. `luacheck lua plugin` lief mit 0 Warnings/Errors über alle 95 Dateien; die
  vollständige Headless-Testsuite (`TESTS/run.lua`, 13 Specs) lief vor und nach der Änderung grün.
- **RELEASE.md**: README (Englisch, ASCII-Art, Badges, Schwesterplugin-Absatz zu markdown.nvim,
  Installationsblock mit explizitem `ft = 'markdown'`, `lib.nvim`-Dependency deklariert) war
  bereits fast vollständig — nur das Level-2-only Table of Contents fehlte, ergänzt; eine
  überflüssige Emoji ("🔧 Beta stage") aus der Status-Zeile entfernt (Markdown-Stilkonvention:
  keine Emojis). `doc/color_my_ascii.txt`, `docs/BINDINGS.md` (vollständig, alle Usercmds/Keymaps/
  Autocmds), `docs/ROADMAP.md` (aktuell, zuletzt selbst am 2026-08-08 gepflegt) waren bereits
  vollständig. `:checkhealth color_my_ascii` headless über einen echten `plugin/color_my_ascii.lua`-
  Bootstrap getestet (inkl. `usercmd.composer`-Routen) — läuft komplett grün, keine Warnings/Errors.
  GitHub-Metadaten (`gh repo view`) bereits vollständig gesetzt: Description, 8 Topics,
  Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention), keine
  LICENSE-Datei/-Referenz — keine Änderung nötig. Cross-Plattform: keine hartkodierten
  Pfadtrenner; die einzigen `\\`-Vorkommen in `commands/fence/export.lua` sind bewusste
  `gsub('\\', '/')`-Normalisierungen für den Pfadvergleich, keine Windows-only-Joins.
- **Refactoring.md — zweiter Codefix**: `config/init.lua`s `load_languages()`/`load_groups()`/
  `merge_user_languages()` riefen `notify()` direkt auf, obwohl sie bereits eine `errors`-Liste
  aufbauten und zurückgaben — klassischer Fail-late-Verstoß. Alle drei geben jetzt nur noch Status
  zurück; `M.setup()` (die einzige Boundary) sammelt die Fehler/Warnungen und entscheidet über das
  Melden. `commands/fence/import.lua`s `vim.fn.readfile()` (Dateisystem-Grenze) lief ungeschützt
  ohne `pcall` — jetzt abgesichert mit klarer Fehlermeldung statt eines rohen Lua-Errors.

Übersprungen/nicht verifizierbar: POSIX-Test nicht lokal möglich (Windows-Umgebung) — verifiziert
stattdessen über CI (`ubuntu-latest`, `stylua`+`luacheck`), die nach dem Push grün lief. Alles
committet (`2f17c82`) und nach `origin/main` gepusht.

### language.nvim

- **Ausgangslage**: Repo war bereits durch mehrere frühere Claude-Pässe (siehe eigener Git-Log)
  stark vorgearbeitet — `doc/language.txt`, `docs/BINDINGS.md`, `docs/ROADMAP/ROADMAP.md` waren
  bereits vollständig und aktuell, `health.lua` implementiert `lib.nvim`-durchgängig genutzt.
- **PERFORMANCE.md**: kein neuer Hotpath-Fund. `spell/live.lua` (Live-Scan auf `TextChanged`)
  nutzt bereits Debounce + `changedtick`-Cache (`spell/core/cache.lua`); keine Änderung nötig.
- **LUA_NVIM.md/REVIEW.md §8 Tooling — der eigentliche Fund dieses Passes**: `.luarc.json` und
  `stylua.toml` existierten bereits (Vorbild-konform zu `sessions.nvim`), aber es fehlte ein
  `.luacheckrc` komplett — dadurch meldete `luacheck` 215 falsch-positive "accessing undefined
  variable 'vim'"-Warnings über alle 51 Dateien. `.luacheckrc` (`std = "luajit"`,
  `globals = { "vim" }`, `max_line_length = 160` für die callback-lastigen `fun(...)`-Type-
  Annotationen) ergänzt. Danach blieben 4 echte Funde: ein ungenutztes Argument in
  `spell/core/collect.lua`s `provider_enabled` (entfernt, beide Call-Sites angepasst), ein leerer
  `elseif`-Zweig in `translate/filter.lua` (Logik zu `elseif not in_fence then` umstrukturiert,
  keine Verhaltensänderung), sowie zwei zu lange `@field`/`@alias`-Zeilen in
  `config/@types/init.lua` und `translate/@types/init.lua` (in benannte Sub-Aliase aufgeteilt
  bzw. gekürzt). `luacheck lua plugin` läuft jetzt mit 0 Warnings/Errors über 51 Dateien,
  `stylua --check .` war und blieb grün. `fun(...)`-Annotationen durchsucht — kein Fall des
  bekannten `fun(type)`-ohne-Namen-Bugs aus `pickers.nvim`/`mdview.nvim`/`markdown.nvim` gefunden.
- **RELEASE.md**: README bekam ASCII-Art, Neovim-Badge, Table of Contents (nur Level-2) und den
  Schwesterplugin-Absatz zu `sessions.nvim` (Installationsblock mit `event = "VeryLazy"` und
  `lib.nvim`-Dependency war bereits vorhanden). Ein echter Verstoß gegen die Konvention "keine
  Lizenzdatei/-referenz" gefunden und behoben: `doc/language.txt` enthielt eine Kopfzeile
  `License: MIT` ohne zugehörige LICENSE-Datei — Zeile entfernt. GitHub-Metadaten (`gh repo view`)
  bereits vollständig: Description, 7 Topics, Default-Branch `main`, leeres Homepage-Feld, keine
  LICENSE-Datei — keine Änderung nötig. Cross-Plattform: `util/job/init.lua` behandelt den
  Windows-`.cmd`/`.bat`-Shim-Fall (npm-globale `cspell`) bereits explizit und korrekt über
  `cmd.exe /c`; das Modul nutzt `vim.system` direkt statt `lib.nvim.cross.spawn_*` — als
  bewusste Ausnahme belassen, da die vorhandene Cancel/Timeout/Dual-Fallback-Logik ohne Einsicht
  in die exakte `lib.nvim.cross`-API nicht risikofrei migrierbar war. Keine hartkodierten
  Backslash-Pfadtrenner gefunden (alle Joins nutzen `"/"`, was `vim.fn.fnamemodify` auch unter
  Windows normalisiert).
- **Refactoring.md**: `notify(`-Aufrufe durchsucht — bis auf einen Fall ausschließlich in
  Top-Level-/UI-Modulen (`health.lua`, `spell/init.lua`, `translate/init.lua`,
  `translate/window.lua`, UI-Panels), also bereits an der richtigen Boundary. Einzige Ausnahme:
  `spell/providers/cspell_server.lua` (Low-Level-Provider) notifiziert direkt, wenn der
  persistente Node-Sidecar abstürzt — bewusst belassen, da dieser Fehler asynchron/ohne
  wartenden Caller auftritt (Prozess-Lifecycle-Event, kein Request-Response-Pfad) und es daher
  keine sinnvolle synchrone Boundary gibt, die ihn stattdessen melden könnte.
- **Kein CI vorhanden**: Das Repo hat kein `.github/workflows/`. `gh run list` liefert entsprechend
  keine Runs — nichts zu prüfen/reparieren.
- **Verifikation**: `stylua --check .` grün, `luacheck lua plugin` 0/0, sowie ein neuer headless
  Smoke-Test (requires alle Module unter `lua/language`, ruft `setup({})` und `health.check()`
  auf) lief erfolgreich (`SMOKE_TEST_OK`, exit 0) — kein vorhandener Testrunner im Repo, daher
  als Ad-hoc-Verifikation statt eines dauerhaften Test-Artefakts ausgeführt.

Übersprungen/nicht verifizierbar: POSIX-Verhalten nicht lokal testbar (Windows-Umgebung), keine
CI zum Gegenchecken vorhanden. Alles committet (`47994ed`) und nach `origin/main` gepusht.

### reposcope.nvim

- **Ausgangslage**: Repo war bereits sehr gut vorgearbeitet — README (ASCII-Art, Badges,
  Schwesterplugin-Absatz zu `filetree.nvim`), vollständiges `doc/reposcope.txt`, ausführliches
  `docs/BINDINGS.md`, gepflegtes `docs/ROADMAP.md`, typisierte `/config/init.lua` +
  `/config/DEFAULTS.lua`, `health.lua` durchgängig über `lib.nvim` implementiert. Kein `fun(type)`-
  ohne-Namen-Bug gefunden (anders als bei `pickers.nvim`/`mdview.nvim`/`markdown.nvim`).
- **PERFORMANCE.md**: kein neuer Hotpath-Fund über die bereits vorhandene README-Cache-Logik
  (`cache/readme_cache.lua`, RAM + File-Cache) hinaus; keine Änderung nötig.
- **LUA_NVIM.md/REVIEW.md §8 Tooling — Hauptfund dieses Passes**: weder `.luacheckrc` noch
  `stylua.toml` existierten. Beide ergänzt (Stil an `sessions.nvim`/`mdview.nvim` angelehnt, aber
  mit `indent_type = "Spaces"`/`indent_width = 2`, da der Code tatsächlich mit 2 Spaces eingerückt
  ist, nicht mit Tabs). `.luarc.json` um `runtime.version = "LuaJIT"`, `runtime.path` und
  `$VIMRUNTIME/lua` ergänzt. Größerer Nebenfund: das gesamte Arbeitsverzeichnis war mit CRLF
  ausgecheckt (lokales `core.autocrlf=true`), obwohl jeder Git-Blob bereits LF war — das ließ
  `stylua --check .` bei jeder Datei einen Full-File-Diff melden. `.gitattributes`
  (`* text=auto eol=lf`) ergänzt und alle 117 Textdateien im Arbeitsverzeichnis von CRLF auf LF
  normalisiert (reiner Zeilenenden-Fix, keine Inhaltsänderung). `luacheck lua plugin` meldete 7
  Warnings, davon 2 echte Bugs: `ui/background/background_window.lua` erzeugte bei jedem
  `open_window()` bedingungslos neuen Buffer/Fenster statt (wie `preview_window.lua`/
  `list_window.lua`) ein noch gültiges wiederzuverwenden — behoben. `ui/preview/preview_window.lua`s
  `close_window()` setzte eine tote lokale `win`-Variable auf `nil` statt `ui_state.windows.preview`
  — das Fenster-Handle wurde nie tatsächlich aus dem State entfernt — behoben, analog zu
  `list_window.lua`. Weitere Funde: `network/clients/api_client.lua` nahm den `context`-Parameter
  entgegen, hat ihn aber nie an `http_client.request` als `metrics_context` durchgereicht — jetzt
  durchgereicht. Totes `debug_parts`-Tracking in `providers/github/query_builder.lua` und eine
  wirkungslose `selected = 1`-Zuweisung direkt vor `return nil` in `cache/repository_cache.lua`
  entfernt. `utils/debug.lua`: Parameter `_schedule` (führender Unterstrich = "unused"-Hinweis für
  Luacheck, wird aber tatsächlich benutzt) zu `schedule` umbenannt; `is_dev_mode()` war mit
  `@return nil` annotiert, gibt aber einen `boolean` zurück — Annotation korrigiert. `stylua --check
  .` und `luacheck lua plugin` liefen danach beide grün (0/0 über 105 Dateien).
- **RELEASE.md**: README bekam ein fehlendes Table of Contents (nur Level-2, ASCII-Art/Badges/
  Schwesterplugin-Absatz/Installationsblock mit `event = "VeryLazy"` und `lib.nvim`-Dependency
  waren bereits vorhanden). GitHub-Metadaten: Description war veraltet (beschrieb eine
  "Telescope-Extension" und listete GitLab/Codeberg-Support fälschlich als "future planned",
  obwohl beides implementiert ist) — aktualisiert; `homepage` stand auf der GitHub-Repo-URL selbst
  — geleert (Konvention über die Schwesterplugins hinweg). Keine LICENSE-Datei/-Referenz, Default-
  Branch `main`, Topics bereits sinnvoll gesetzt.
- **Refactoring.md**: `notify(`-Aufrufe durchsucht — anders als bei den bisherigen Plugins ist die
  Verletzung hier tief im Code verankert: ca. 70 `notify()`-Aufrufe direkt in Low-Level-Modulen
  (`utils/*`, `cache/*`, `network/*`, `state/*`), nicht nur an der UI-Boundary. Bewusst NICHT
  refaktoriert: eine Umstellung dieser Größenordnung über ~20 Dateien hinweg, ohne vorhandene
  Testabdeckung, hätte ein reales Risiko für Verhaltensregressionen bei einem Plugin, das direkt
  ohne Review nach `main` gepusht wird — das Risiko/Nutzen-Verhältnis sprach dagegen. Aus demselben
  Grund wurde auch der eigene `reposcope.utils.debug.notify`-Wrapper (statt `lib.nvim.notify`)
  nicht angetastet — er bündelt Dev-Mode-Gating bereits konsistent, ein Austausch wäre eine
  vergleichbar breite Verhaltensänderung ohne klaren Mehrwert für dieses Ausmaß an Risiko.
- **Kein CI vorhanden**: Das Repo hat kein `.github/workflows/`. `gh run list` liefert entsprechend
  keine Runs — nichts zu prüfen/reparieren.
- **Verifikation**: `stylua --check .` grün, `luacheck lua plugin` 0/0 über 105 Dateien, sowie ein
  headless Smoke-Test (requires alle Module unter `lua/reposcope`, ruft `setup({})` und
  `health.check()` auf) lief erfolgreich, ebenso `:checkhealth reposcope` (grün bis auf ein lokal
  fehlendes `wget`-Binary — `gh`/`curl` sind vorhanden und ausreichend, kein Plugin-Bug). Kein
  vorhandener Testrunner im Repo, daher Ad-hoc-Verifikation statt eines dauerhaften Test-Artefakts.

Übersprungen/nicht verifizierbar: POSIX-Verhalten nicht lokal testbar (Windows-Umgebung), keine
CI zum Gegenchecken vorhanden. Alles committet (`3f09164`) und nach `origin/main` gepusht.

### runtime-analysis.nvim

Das mit Abstand sauberste bisher geprüfte Plugin: 34 Lua-Dateien, durchgängig ausführliche
`@module`-Kopfkommentare, vollständige `@param`/`@return` mit Aliasen statt Inline-Monstern,
ein konsolidiertes `@types/init.lua` pro Verzeichnis (`lua/runtime-analysis/@types/init.lua`,
`telemetry/@types/init.lua`), `config/DEFAULTS.lua` + `config/init.lua`, `.luarc.json`
(`diagnostics.globals=["vim"]`, identisch zu `sessions.nvim`s Version), `.luacheckrc`,
`.stylua.toml`, `.gitattributes` (erzwingt `eol=lf` für `.lua`/Map-Artefakte — genau das später
in dieser Liste mehrfach gefundene CRLF-Problem hier bereits präventiv gelöst) und CI
(stylua + luacheck + headless `docs/TESTS/run.lua`, 20 Specs, + ein `gen_map.lua --check`-Job
für die `documentation.nvim`-Modulkarte) bereits vollständig vorhanden. `PERFORMANCE.md` wurde
besonders sorgfältig gegen den einzigen echten Hotpath geprüft (`telemetry/registry.lua`s
Funktions-Wrapper, läuft bei jedem instrumentierten Aufruf) und war bereits vorbildlich: der
Kommentarkopf der Datei benennt selbst "exactly two things per call in the cheapest mode: index
a table and add one integer", Sampling/`outermost_only` sind explizit opt-in gegen die Kosten von
`pcall`/`debug.getinfo`, und `registry.dispatch`/`make_wrapper` vermeiden jede Tabellenallokation
im Cheap-Path. Keine Änderung an diesem Modul nötig.

- **PERFORMANCE.md**: siehe oben — einziger Hotpath ist bereits vorbildlich optimiert und
  dokumentiert. Keine Änderung nötig.
- **LUA_NVIM.md — der einzige Codefix dieses Passes**: `view.lua`, `env.lua` und
  `bindings/usrcmds.lua` riefen `vim.notify()` direkt mit einem handgestrickten
  `"runtime-analysis: "`-Präfix pro Aufruf auf, statt wie `telemetry/init.lua` und
  `telemetry/command.lua` bereits vormachen `require("lib.nvim.notify").create(prefix)` zu
  nutzen — auf denselben Factory-Wrapper umgestellt (`notify.info`/`.warn`/`.error`, plus
  `notify.notify(msg, level)` für die zwei Stellen mit dynamischem Level in `do_usage`).
  Rein mechanisch, Nachrichtentext inhaltlich unverändert; gegen die volle Headless-Testsuite
  verifiziert (die Specs fangen `vim.notify` selbst ab, das `lib.nvim.notify` intern weiter
  aufruft, und prüfen nur den Level, nie den exakten Präfix-String). Keine `fun(type)`-ohne-Name-
  Bugs gefunden (anders als bei `pickers.nvim`/`mdview.nvim`/`markdown.nvim` in dieser Rollout-
  Serie) — alle `fun(...)`-Annotationen in `@types/init.lua` und den Modulen selbst benennen ihre
  Parameter korrekt.
- **REVIEW.md §8 Tooling**: `.luarc.json`/`.luacheckrc`/`.stylua.toml` bereits vollständig und
  identisch im Format zu `sessions.nvim`s Version — keine Änderung nötig. `stylua --check .` und
  `luacheck lua docs/TESTS scripts ftdetect` liefen nach dem Notify-Fix beide grün (0/0 über 59
  Dateien).
- **RELEASE.md**: README (Englisch, ASCII-Art, Badges, Level-2-only Table of Contents,
  Schwesterplugin-Absatz zu documentation.nvim, Installationsblock mit explizitem `lazy = false`
  und Begründung dafür, `lib.nvim`-Dependency deklariert), `doc/runtime-analysis.txt`,
  `docs/BINDINGS.md` (vollständig, inkl. expliziter "keine Keymaps"-Aussage und Autocmd-Tabelle),
  `docs/ROADMAP.md` (aktiv gepflegt, mit `docs/FINISHED.md`-Archiv-Verweis), `:checkhealth
  runtime-analysis` (headless gegen `setup({})` getestet, läuft grün durch) waren bereits
  vollständig und aktuell. GitHub-Metadaten (`gh repo view`) bereits vollständig gesetzt:
  Description, 8 Topics, Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention),
  keine LICENSE-Datei/-Referenz — keine Änderung nötig. Cross-Plattform: keine hartkodierten
  Pfadtrenner gefunden.
- **Refactoring.md**: Fail-late/Report-at-boundary war bereits fast vollständig eingehalten —
  praktisch jeder `notify()`-Aufruf sitzt in `bindings/usrcmds.lua` (Command-Handler, die
  eigentliche Boundary) oder `view.lua`/`telemetry/command.lua` (UI-Schicht). Einzige Ausnahme:
  `env.lua`s `warn_if_not_gitignored()` (aufgerufen aus `load_all()`, einer Low-Level-Datenlade-
  Funktion) notifiziert selbst — bewusst NICHT weiter nach oben verschoben: es ist ein einzelner,
  ausführlich im Modulkommentar begründeter "best-effort nudge" (max. einmal pro Session, kein
  Fehlerpfad, keine Rückgabe, die ein Caller ohnehin auswerten würde), kein systematisches Muster
  wie bei `reposcope.nvim`s ~70 Fundstellen weiter oben in dieser Liste — eine zusätzliche
  Rückgabe-Ebene nur für diese eine Stelle hätte keinen echten Boundary-Gewinn gebracht.
- **Zusätzlicher Fund außerhalb der fünf Checklisten, beim `gh run list`-Verifikationsschritt**:
  der letzte `main`-Push vor diesem Pass hatte `docs/map/` (die von `documentation.nvim` erzeugte
  Modulkarte) stale hinterlassen — der `map`-CI-Job schlug fehl. Mit
  `nvim --headless -l scripts/gen_map.lua` neu erzeugt und committet; `--check` lief danach grün.
  Ein einzelner CI-Fehlschlag (`usrcmds_spec.lua`, ein `vim.wait`-Race gegen einen lokalen
  150-ms-Delay-Server) auf dem ersten Rerun war ein reiner Timing-Flake — lokal dreimal
  hintereinander grün, `gh run rerun --failed` lief beim zweiten Versuch grün durch.

Übersprungen/nicht verifizierbar: nichts — GitHub-Metadaten, `:checkhealth`, CI-Status (vor und
nach den Änderungen per `gh run list`/`gh run view` geprüft) und die zentrale Bindings-Sammlung
waren alle direkt prüfbar. Alles committet (`794c659` Notify-Refactor, `3ab1324` Map-Regenerierung)
und nach `origin/main` gepusht.

### filetree.nvim

Größtes bisher geprüftes Plugin (112 Lua-Dateien) und inhaltlich bereits sehr weit: durchgängige
`@module`-Kopfzeilen, vollständige `@param`/`@return`, `@types/`-Ordner (`adapter.lua`,
`config.lua`, `node.lua`, `init.lua`), `config/DEFAULTS.lua` + `config/init.lua`, `.luarc.json`
(bereits vorhanden, äquivalent zu `sessions.nvim`s), README (Englisch, ASCII-Art, Badges,
Schwesterplugin-Absatz zu fileops.nvim, Installationsblock mit explizitem `event = "VeryLazy"`),
`doc/filetree.txt`, `docs/BINDINGS/{KEYMAPS,USERCOMMANDS,AUTOCMDS}.md` + maschinenlesbares
`docs/BINDINGS.lua` (bewusste Abweichung vom `docs/BINDINGS.md`-Dateinamen aus RELEASE.md — Inhalt
und Vollständigkeit sind identisch, nur auf drei Dateien aufgeteilt, und die Live-Korrektheit wird
von `test/smoke.lua` gegen den tatsächlichen Katalog verifiziert), `docs/ROADMAP/*.md` (mehrteilig,
gepflegt, inkl. bereits abgeschlossener `NEOTREE_FEATURES.md`-Migrationsaufgabe aus RELEASE.md),
`health.lua` (209 Zeilen), und eine bereits vorhandene, gut strukturierte Headless-Testsuite
(`test/{smoke,units,menu,cwd_mode}.lua`, 356 Assertions) — aber **kein CI, kein `.luacheckrc`, kein
`stylua.toml`**, alle drei neu ergänzt.

- **PERFORMANCE.md — der einzige echte Hotpath-Fund dieses Passes**: `features/git/git_status/
  init.lua` re-renderte seine Git-Status-Extmarks (vollständiges `clear_namespace` +
  Zeile-für-Zeile-Rebuild) über ein **globales** `CursorMoved`-Autocmd (`pattern = "*"`) — eines
  der am häufigsten feuernden Events in Neovim überhaupt, hier bei jedem Cursor-Schritt in *jedem*
  Fenster im gesamten Editor (mit anschließendem `vim.bo.filetype`-Gate). Innerhalb des Tree-Fensters
  bedeutete das: jeder einzelne j/k-Tastendruck löste einen vollständigen Extmark-Rebuild aus, obwohl
  Extmarks ihre Position bei reiner Cursor-Bewegung automatisch beibehalten und sich am Inhalt nichts
  ändert. Umgestellt auf ein buffer-lokales `CursorMoved` (gebunden pro Tree-Buffer in
  `tree_attach.on_attach`, `buffer = buf`) plus 50ms-Debounce für den Render-Call — folgt damit
  demselben Muster, das `features/ui/opened_sync/init.lua` bereits bewusst für denselben Zweck nutzt
  (Kommentar dort: "far too chatty for a redraw"). Kein weiterer Hotpath-Fund (Icon-Lookups laufen im
  Adapter, nicht im Plugin selbst; kein sonstiges Polling).
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig mit dokumentierten Soft-
  Dependency-Fallbacks, saubere Importreihenfolge, Config-Keys typisiert. `fun(...)`-Annotationen
  repo-weit gegrept — keine Instanz des in `pickers.nvim`/`mdview.nvim`/`markdown.nvim` gefundenen
  "fehlender Parametername"-Bugs (`fun(type)` statt `fun(name: type)`). Keine Änderung nötig.
- **REVIEW.md §8 Tooling — der Hauptfund dieses Passes**: kein `.github/workflows`, kein
  `.luacheckrc`, kein `stylua.toml` vorhanden (trotz vorhandener, guter Testsuite, die nie in CI
  lief). Alle drei ergänzt, angelehnt an `pickers.nvim`s aktuelles Muster (stylua `v2.5.2` gepinnt,
  luacheck als echtes Gate, Headless-Testsuite gegen einen Sibling-`lib.nvim`-Checkout als zweiter
  Job). `stylua --check` deckte zusätzlich auf, dass `core.autocrlf=true` den Checkout als CRLF
  auslieferte, obwohl die committeten Blobs LF waren (falscher Vollfile-Diff bei jedem `--check`) —
  `.gitattributes` um `* text=auto eol=lf` ergänzt (bereits vorhandene templates-spezifische Regel
  blieb bestehen) und den Working-Tree per `git rm -r --cached . && git add -A` neu normalisiert.
  stylua bleibt bewusst `continue-on-error` in CI (77 von 112 Dateien wichen vom neuen Format ab —
  ein blindes Repo-weites Reformat ist bei einem 221-Datei-Plugin ohne lückenlose Testabdeckung zu
  riskant für diesen Pass; dieselbe Entscheidung wie bei `fileops.nvim` dokumentiert). `luacheck`
  fand 23 Warnings/1 Error (Error: ein Datei-Template mit Platzhalter-Syntax `$1`/`$name`, das kein
  gültiges eigenständiges Lua ist — von `luacheck` ausgeschlossen); die 23 Warnings (tote
  `notify`/`platform`-Requires, ungenutztes Modul-level-State in `handle_guard`/`cheatsheet`/
  `node_info`, Variablen-Shadowing in `util/buffer.lua`/`test/units.lua`) behoben, jetzt 0/0. Dabei
  auch ein echter (kleiner) Bug in `search/find_files/init.lua`s `via_builtin`-Fallback gefunden: die
  `_cfg.hidden`-Option wurde in ein nie verwendetes `pattern`-Local berechnet und danach ignoriert —
  `globpath`s `**/*` matcht auf Punktdateien grundsätzlich nicht, wodurch versteckte Dateien im
  Picker-losen Fallback-Pfad nie erschienen, unabhängig von der Konfiguration. Jetzt ein zweiter
  `**/.*`-Glob-Pass, der bei `hidden=true` gemergt wird. `fun(...)`-Annotationen bereits sauber (s.
  oben).
- **RELEASE.md**: alles bereits vollständig (siehe oben) bis auf CI (behoben, s. §8 Tooling). Kein
  README-Table-of-Contents vorhanden — bei nur drei Level-2-Abschnitten (`Requirements`,
  `Quick start`, `Documentation`) bewusst nicht nachgerüstet, ein ToC für drei Einträge wäre reine
  Redundanz. GitHub-Metadaten (`gh repo view`) bereits vollständig gesetzt: Description, 9 Topics,
  Default-Branch `main`, leeres Homepage-Feld (Schwester-Plugin-Konvention), keine
  LICENSE-Datei/-Referenz. Cross-Plattform: keine hartkodierten Pfadtrenner-Joins gefunden (nur
  dokumentierte `gsub`-Normalisierungen und bewusste Windows-Zweige über `util/platform.lua`).
- **Refactoring.md**: `notify()` in Low-Level-Utils gefunden (`util/buffer.lua`, `util/pdf.lua`,
  `util/platform.lua` [nur im Kommentar erwähnt, kein echter Call], `util/refs_picker.lua`) — bewusst
  **nicht** angefasst: `refs_picker.lua` ist selbst eine interaktive Picker-UI (keine reine
  Low-Level-Funktion trotz `util/`-Pfad), `pdf.lua`s Notifies sind Fallback-Feedback beim Öffnen
  externer Viewer (grenzwertig, aber eng an die eine aufrufende Stelle gekoppelt), und
  `buffer.lua`s einzelner Call sitzt in einer öffentlichen Utility-Funktion ohne separate
  Boundary-Schicht darüber. Ein systematisches Repo-weites Verschieben dieser vier Fundstellen in
  einem 112-Datei-Plugin ohne lückenlose Testabdeckung wäre ein riskanter Blind-Refactor für einen
  reinen Checklisten-Pass — dieselbe bewusste Scope-Entscheidung wie bei `reposcope.nvim` (~70
  Fundstellen) weiter oben in dieser Liste, hier nur in kleinerem Maßstab.
- **CI-Verifikation**: da CI in diesem Pass neu angelegt wurde, gab es naturgemäß keinen
  Vorher-Zustand zu vergleichen. Der erste Push deckte zwei echte, bislang unentdeckte
  POSIX-Bugs in `test/units.lua` auf (nie auf einem Linux-Runner gelaufen): `vim.env.TEMP` ist
  Windows-only (Runner-Absturz "attempt to concatenate a nil value"), und eine `path.to_unix`-
  Assertion hartcodierte einen Windows-Laufwerksbuchstaben-Pfad. Nach der Behebung ein dritter
  Fund: der Headless-Ubuntu-Runner hat keinen Clipboard-Provider, wodurch sechs Assertions in
  zwei clipboard-abhängigen Fixtures (`smart_create`-Paste, `markdown_links`-Copy) fehlschlugen —
  kein Plugin-Bug, sondern eine Umgebungslücke; per Probe (`HAS_CLIPBOARD`) erkannt und die
  Content-Assertionen entsprechend übersprungen (Call-Pfad bleibt über `pcall` weiter abgedeckt).
  Nach allen drei Fixes: CI grün (`lint` + `tests`).

Übersprungen/nicht verifizierbar: repo-weites `stylua .`-Reformat (siehe oben, bewusst
`continue-on-error` belassen); ein systematisches Verschieben der vier gefundenen Low-Level-
`notify()`-Aufrufe (siehe Refactoring.md oben). Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/filetree.nvim.md`) war
bereits vorhanden und bei Stichprobe (context_menu-Feature, datiert 2026-08-01) inhaltlich aktuell
und deckungsgleich mit `docs/BINDINGS/KEYMAPS.md`/`AUTOCMDS.md` im Repo selbst — keine Änderung
nötig; unverändert gelassen, da eine parallele Session diese Dateien laut Arbeitsverzeichnis
offenbar bereits selbst gepflegt hat und ein Diff hier nur Konfliktrisiko ohne Mehrwert gewesen
wäre. Alles committet (`62dd545` Tooling, `66213a0` luacheck-Cleanup, `cab67de` Perf-Fix, `baa78af`
+ `8239bf1` Test-Cross-Plattform-Fixes) und nach `origin/main` gepusht.

### sandbox.nvim

284 Lua-Dateien, größtes bisher geprüfte Plugin nach `documentation.nvim`/`lib.nvim`. Der
ursprüngliche Durchlauf wurde durch ein Session-Limit unterbrochen, mit ~55 Dateien echt
geänderter, aber noch nicht committeter Arbeit im Working Tree. Vor dem Übernehmen verifiziert:
`luacheck` 0 Warnings/Errors über 268 Dateien, `stylua --check .` sauber — dann committet
(`3cc1b32`) und gepusht. CI (`gh run list`) grün bestätigt, inkl. der im selben Commit neu
verdrahteten `stylua --check`-Stufe (fehlender `token`-Parameter ergänzt, gleiches Muster wie bei
mehreren anderen Plugins in diesem Rollout).

Inhaltlich (aus dem Diff rekonstruiert, da der ursprüngliche Checklisten-Fortschrittsbericht durch
das Session-Limit verlorenging): CI-Lint um `stylua --check` erweitert, `stylua.toml`/
`.gitattributes` neu angelegt, **Refactoring.md**-Fund: zahlreiche `notify()`-Aufrufe in
`adapters/wsl/*`, `telescope/*` und `ui/list_view.lua` lagen in Low-Level-Code — auf
Status-Rückgabe statt direkter Benachrichtigung umgestellt, `bindings/usrcmds/init.lua` entsprechend
mit angepasst (554-Zeilen-Diff). GitHub-Metadaten waren laut Live-Fortschritt des unterbrochenen
Agenten bereits vollständig gesetzt (Description, Topics, `main`, kein License-File, leeres
Homepage-Feld) — keine Änderung nötig. Nach der Übernahme selbst ergänzt: README fehlte die
ASCII-Art (RELEASE.md) — nachgetragen; **kein** Schwesterplugin-Absatz, da sandbox.nvim (Container-/
WSL-Verwaltung) mit keinem anderen personal Plugin in diesem Ökosystem direkt integriert ist —
ein erzwungener Verweis wäre eine erfundene Querreferenz gewesen, bewusst weggelassen.

Nicht abschließend geprüft/übersprungen: der volle Plenary-Testlauf (`tests/sandbox/**`) konnte
lokal nicht verifiziert werden (Aufruf-Konfigurationsproblem, `PlenaryBustedDirectory` wurde nicht
als Command erkannt — kein Hang, sondern ein fehlerhafter lokaler Testaufruf meinerseits); stattdessen
über die grüne GitHub-CI (die genau diese Suite ausführt) verifiziert. `docs/ADD_USECASE.md`,
`docs/CONTRIBUTING.md`, `docs/GENERATED_COMMANDS.md`, `doc/sandbox.txt` wurden vom unterbrochenen
Agenten bereits mitgeändert (Teil des committeten Diffs) — nicht einzeln nachverifiziert, da
inhaltlich konsistent mit den Code-Änderungen und `luacheck`/`stylua`/CI grün. Alles committet
(`3cc1b32`, `cfbddf1`) und nach `origin/main` gepusht.

### documentation.nvim

Das Plugin, das diese Konventionen selbst durchsetzt (`:DocMap` prüft u. a. auf `@module`-Drift und
tote `@see`-Ziele) — entsprechend hoher Maßstab angelegt, und entsprechend wenig gefunden: 74
geprüfte Lua-Dateien (`lua/`, `TESTS/`, `scripts/`), bereits durchgängig `@module`/`@brief`/
`@description`, vollständige `@param`/`@return`, ein einziges konsolidiertes `@types/init.lua` pro
Verzeichnisebene (sauber nach Quelldatei gruppiert, `return {}` überall vorhanden), `config/
DEFAULTS.lua` + `config/init.lua`, `.luarc.json`/`.luacheckrc`/`.stylua.toml`/`.gitattributes`
(inkl. der dokumentierten `eol=lf`-Begründung für generierte Artefakte) bereits vorhanden. CI besteht
aus vier parallelen Jobs (`stylua`, `luacheck`, `tests`, `map`) über `scripts/ci.sh`/`scripts/ci.lua`,
lief vor diesem Pass bereits grün (`gh run list`), und alle vier Gates liefen lokal ebenfalls grün
(`stylua --check .`: 0 Diffs; `luacheck`: 0 Warnings/Errors über 84 Dateien; Headless-Testsuite:
10/10 Specs, `DOCUMENTATION_TESTS_OK`; `scripts/ci.lua map --check`: Map aktuell, ein `info`-Fund
ist absichtliches Pseudo-Code-Beispiel in `docs/ROADMAP/IDEAS.md`, kein echter toter `@see`-Verweis).

- **PERFORMANCE.md**: `:DocMap`s Scan/Parse/Graph-Build ist wie erwartet ein One-Shot-Batch-Vorgang,
  kein Hotpath — `core/scan.lua` baut Pfade per einfacher String-Konkatenation (kein `..`-Loop über
  große Datenmengen), keine Autocmd-Re-Render-Schleife im Scan-Pfad selbst. Der einzige potenzielle
  Hotpath-Kandidat, die `CursorMoved`-Autocmd der Browser-Detailansicht
  (`lua/documentation/editor/browse/init.lua`), ist bereits korrekt `buffer = st.slots.list.bufnr`-
  gescoped statt auf `pattern = "*"` — genau das in früheren Plugins dieses Rollouts gefundene
  Anti-Pattern liegt hier nicht vor. Keine Änderung nötig.
- **LUA_NVIM.md**: vollständig eingehalten — `lib.nvim` durchgängig mit dokumentierten Soft-
  Dependency-Fallbacks (`pcall(require, "lib.nvim.progress")` in `bindings/progress.lua`, bewusst
  so belassen, siehe Refactoring-Notiz zum `pcall(require)`-Idiom), Buffer/Window-Handling im
  Browser sauber, Importreihenfolge eingehalten, `@types`-Ordner pro Verzeichnisebene vorhanden.
  Grep nach `fun(` ohne Namen vor dem Typ (das in `pickers.nvim`/`mdview.nvim`/`markdown.nvim`
  gefundene Copy-Paste-Bug-Muster) ergab **einen** Treffer, `core/render/html.lua:820` — aber das ist
  eine eingebettete JS-String-Literal-Doku ("fun(string)" beschreibt eine anonyme LuaCATS-Param-
  Notation für die HTML-Renderer-Ausgabe, kein echtes `---@param`), kein echter Annotation-Bug. Keine
  Änderung nötig.
- **REVIEW.md §8 Tooling — die beiden einzigen Codefixe dieses Passes**: `.github/workflows/ci.yml`s
  `stylua`-Job war auf `version: latest` gepinnt statt auf eine konkrete Version — dasselbe
  Drift-Risiko, das in `sandbox.nvim`/`filetree.nvim` bereits als reales Problem aufgetreten ist
  (lokal installiertes `stylua 2.5.2` vs. ein zukünftiges Latest mit anderem Default-Verhalten); auf
  `v2.5.2` gepinnt. `.luarc.json` hatte nur `diagnostics.globals`/`checkThirdParty`, ohne
  `runtime.path`/`workspace.library` (`${3rd}/luv/library`)/`useGitIgnore` — an das etablierte
  Referenzmuster aus `sessions.nvim`s `.luarc.json` angeglichen für ein vollständigeres LSP-Erlebnis.
  Sonst keine Abweichungen: kein globaler State, `_G.*`-Treffer sind nur Doku-Kommentare zu
  `_G.arg`, keine hartkodierten Pfadtrenner außerhalb von `gsub`-Normalisierungen.
- **RELEASE.md**: bereits vollständig release-reif, keine Änderung nötig. README (Englisch,
  ASCII-Art, Badges, Schwesterplugin-Absatz zu lib.nvim, Table of Contents nur Level-2, Install-Block
  mit explizitem `cmd = { "DocMap", "DocBrowse" }`, vier Package-Manager abgedeckt), `doc/
  documentation.txt` (Haupt-Tag `*documentation.nvim*`, kein Namenskonflikt mit einem generischen
  `documentation`-Builtin-Tag — per `getcompletion("documentation", "help")` gegen ein `--clean`-Nvim
  ohne dieses Plugin verifiziert: kein exakter `documentation`-Tag existiert builtin), `docs/
  BINDINGS.md` (generiert, vollständig, deckungsgleich mit dem tatsächlichen Code), `docs/ROADMAP/
  ROADMAP.md` (aktiv gepflegt, klare Trennung offen/erledigt), `:checkhealth documentation`
  implementiert (Versions-Check, `lib.nvim`-Teilmodul-Probes, Root-Auflösung). GitHub-Metadaten
  (`gh repo view`) bereits vollständig: Description, 10 Topics, Default-Branch `main`, leeres
  Homepage-Feld (Schwester-Plugin-Konvention), keine LICENSE-Datei/-Referenz.
- **Refactoring.md**: Fail-late/Report-at-boundary bereits vollständig eingehalten — kein einziger
  `notify()`-Aufruf in `lua/documentation/core/**` oder `lua/documentation/@types/**` gefunden; alle
  Meldungen sitzen in `bindings/`, `editor/` (Befehls-/UI-Schicht). Keine Änderung nötig.

Übersprungen/nicht verifizierbar: nichts Wesentliches — alle Prüfpunkte waren direkt einsehbar oder
lokal per `stylua`/`luacheck`/`nvim --headless -l scripts/ci.lua {stylua,luacheck,tests,map}`
verifizierbar; CI vor und nach dem Fix grün bestätigt (`gh run list`). Zentrale Bindings-Sammlung
(`nvim/docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/documentation.nvim.md`) war
bereits inhaltlich aktuell und deckungsgleich mit dem Repo-eigenen `docs/BINDINGS.md` (datiert
2026-08-05, deckt den `per-invocation root`-Commit bereits ab) — keine Änderung nötig. Alles
committet (`81631dd`) und nach `origin/main` gepusht.
