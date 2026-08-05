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
| open.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| sandbox.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| spotlight.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
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
