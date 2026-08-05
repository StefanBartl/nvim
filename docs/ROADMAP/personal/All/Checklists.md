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
| fileops.nvim | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
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
