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
| replacer.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| insights.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| filetree.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| reposcope.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY |||||||
| debugging.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| dap.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| diff.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| language.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| cmdlog.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| emojis.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| github_stats.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 4. FILE TYPES (MARKDOWN & DOCUMENTS) |||||||
| cascade.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| pdfport.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| markdown.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| color_my_ascii.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| recommender.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| mdview.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| images.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

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
