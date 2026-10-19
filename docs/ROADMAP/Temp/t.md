# Offene Punkte – Chat „5 Tasks aus dem Vault“ (2026-10-17)

## Tasks im Vault

- [ ] `testing.nvim/explorer-g-cheatsheet-and-footer-via-lib-nvim-keymap-cheatsh`
  – steht auf `blocked` (blocked_by `testing.nvim/ui-explorer-actions`). Es gibt noch
  keinen Explorer; die Kette `ui-explorer-window` → `ui-explorer-actions` ist selbst blockiert.

## Bekannte Grenzen (dokumentiert, ohne eigene Task)

- [ ] **terminal.nvim:** Ein direct-Terminal, das nach einem fehlgeschlagenen Pin oder
  einem Session-Restore neu startet, verliert `env`, `on_open`/`on_exit` und
  `TerminalExitPost`. Das Handle speichert sie nicht (Designgrenze). Steht in den
  Task-Notizen, aber **nicht** in `docs/commands.md`.
- [ ] **terminal.nvim:** Der `preflight` von `pin` prüft nur das `env` aus der Config, nicht
  das `env` aus `run()`. Ein `run(direct, env=…)` wird ohne dieses env in die Pane
  verschoben. Fiel im Review von `c3fec67` auf und war schon vorher so; dafür gibt es keine Task.
- [ ] **gitsuite.nvim:** lazygit in einer tmux- oder WezTerm-Pane (über terminal.nvim) hat
  keine nvr-Brücke zurück nach Neovim und keine `q`/`<Esc>`-Maps. Das steht in
  `docs/requirements.md`.
- [ ] **rules.nvim:** Über der ersten Überschrift eines Layouts gibt es kein `line`. Ein Token
  zwischen zwei Textstücken ganz oben kommt deshalb nicht exakt zurück. Laut Messung betrifft
  das kein reales Layout; die Grenze steht in `CONTRACT.md`.
- [ ] **markdown.nvim:** Ist ein Fenster zu niedrig für Rahmen plus Cursorzeile, verliert es
  den oberen Rahmen. `<C-e>` und das Mausrad blenden ihn absichtlich aus, bis zur nächsten
  Cursorbewegung bzw. zum nächsten Re-Render. Das steht in `docs/table-wrap.md`.

## Ungeprüft / Restrisiko

- [ ] **pickers.nvim `8aae5c5`:** Ein End-to-End-Test mit echtem fzf-lua lief headless nicht
  (0 Items). Dass fzf-lua die Vorschauhöhe als 2. Argument an die Preview-Funktion übergibt,
  ist nur aus dem Code gelesen. Fehlt sie, gilt der Fallback 20 Zeilen: Die Zielzeile ist
  sichtbar, aber nicht exakt mittig. **Live in nvim testen:** `:Markdown table list` mit
  fzf-lua, `<M-c>`, Größe ändern, `:FzfLua resume`.
- [ ] **pickers.nvim:** Der Kollisions-Spec für die Toggle-Taste vergleicht nur exakte
  Kleinschreibung (`<A-c>` würde durchrutschen), low.
- [ ] **Fix-Commits ohne erneutes Review** (laut Regel optional): gitsuite `0204d0f`,
  pickers `8aae5c5`, rules.nvim `a30ad08`, markdown.nvim `99255d3`, terminal.nvim `1f81ce3`
  und `a577b51`.

## Aufräumen / Kleinkram

- [ ] `E:/tmp_ir.json` löschen (Testrest eines Agenten, nicht im Repo).
- [ ] **terminal.nvim:** Die Doku-Map ist veraltet (`gen_map --check` meldet stale, schon vor
  diesem Chat). Die CI erzeugt sie nur neu und prüft sie nicht.
- [ ] **LuaLS** meldet `Undefined field with_rerun` in `terminal.nvim/lua/terminal/pin.lua:103`.
  luacheck und die Tests sind grün; vermutlich liest der Editor-LSP `@types` nicht ein.
  Ungeprüft.

## Info (kein Handlungsbedarf)

- Der Claim-Commit `608f64d2` hat eine fremde neue Task-Datei
  (`rules-desktop/…tasks-hub-volles-lto…`) mitgenommen, und der fremde Commit `52a8fc9b`
  (gitsuite done) wurde dabei mitgepusht.
- In `0dea2c1` (gitsuite) hat eine parallele Sitzung den Code der lazygit-Task in ihren
  eigenen Commit übernommen. Die Commit-Message nennt die Task nicht.
