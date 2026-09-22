# GS-25 — Post-Action-Konsumenten (`filetree`, `fileops`)

**Repos:** filetree.nvim, fileops.nvim (beide Konsumenten von gitsuite) ·
**Nutzen** 3 · **Aufwand** 0,5 · **Risiko** niedrig · **Welle** 5 ·
Abhängigkeit `GS-06` (bereits vorher erledigt) · erledigt 2026-09-22.

## Ausgangslage

`GS-06` gab gitsuite.nvim zwei `User`-Events (`GitsuiteBranchSwitched`,
`GitsuiteConflictsResolved`), aber noch niemand hörte auf sie. Zwei
naheliegende Konsumenten: `filetree.nvim`s Git-Status-Dekoration (veraltet
bis zum nächsten `BufWritePost`/`FocusGained`) und `fileops.nvim`s
Explorer-Refresh (dieselbe Lücke).

## Umsetzung

- **filetree.nvim** (`2f59085`): `features/git/git_status/init.lua`s
  `M.setup()` registriert eine dritte `User`-Autocmd (neben
  `BufWinEnter`/`BufWritePost`/`FocusGained`) für beide gitsuite-Events, die
  denselben `debounce_refresh()` auslöst wie die bestehenden. Keine
  Abhängigkeit in beide Richtungen — reine `User`-Autocmds, feuern nie ohne
  gitsuite.nvim.
- **fileops.nvim** (`6ff74ce`): neues `bindings/autocmds.lua`s
  `M.attach_gitsuite_events(cfg)`, gated durch neue Config-Sektion
  `gitsuite_events.enable` (Default `true`) — lauscht auf beide Events und
  ruft `file.notify_change(action, path)` (denselben Pfad, den jede andere
  Tree-ändernde Operation schon nutzt): Branch-Wechsel → Action
  `git-checkout`, Repo-Root als `path`; Konflikt gelöst → Action
  `git-conflict-resolved`, der Buffer-eigene Dateiname als `path`.

## Tests

`filetree.nvim`: `TESTS/gaps.lua`, neuer Block mit gefaktem `vim.system`
— fasst nach, dass `setup()` genau eine Query auslöst und beide Events je
eine weitere Refresh-Query triggern.
`fileops.nvim`: `TESTS/autocmds_spec.lua`, neuer Block — prüft die
Autocmd-Registrierung und feuert beide Events synthetisch, belegt Action/
Pfad des resultierenden `User FileopsChanged`. `stylua`/`luacheck` grün in
beiden Repos, volle Suiten grün (filetree: alle sieben CI-Testdateien
inkl. `refs/run.lua`, 1389+ Checks; fileops: 922 Checks).

## Ergebnis

CI grün auf allen Systemen beider Repos (`gh run view` bestätigt
`completed success` für filetree.nvim `35757749638` und fileops.nvim
`35757778788`).

## Dokumentation mitgezogen

filetree.nvim: `docs/FEATURES/INTEGRATIONS.md` (neuer Abschnitt "Git
Status" um die Events ergänzt), `docs/installation.md`, `doc/filetree.txt`
(via `scripts/gen_vimdoc_reference.lua` neu generiert).
fileops.nvim: `docs/FEATURES/INTEGRATIONS.md` (neuer Abschnitt), `docs/
installation.md`, `doc/fileops.txt`.
