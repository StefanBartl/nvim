# GS-27 — lazygit-Einstieg aus `reposcope`/`cmdlog`/`sandbox`

**Repos:** reposcope.nvim, cmdlog.nvim, sandbox.nvim (alle drei Konsumenten
von gitsuite) · **Nutzen** 3 · **Aufwand** 0,5 · **Risiko** niedrig ·
**Welle** 5 · Abhängigkeit `GS-03` (bereits vorher erledigt, liefert
`gitsuite.features.ui.lazygit(repo_dir?)`) · erledigt 2026-09-22.

## Ausgangslage

`gitsuite.features.ui.lazygit(repo_dir)` akzeptiert bereits seit `GS-03`
einen optionalen Repo-Pfad. Drei Schwesterplugins mit eigenem
Repo/Projekt-Kontext hatten dafür noch keine Einstiegstaste: reposcope.nvims
Dashboard (eine Zeile = ein Repo), cmdlogs Projekt-History-Picker (ein
Picker = ein Git-Root), sandbox.nvims Devcontainer-Workflow (ein
gemounteter Workspace = ein Repo).

## Umsetzung, je Repo

- **reposcope.nvim** (`532eb1b`): neue Zeilen-Aktion `L` im Dashboard
  (`ui/actions/dashboard_view.lua`s `ROW_KEYMAPS`), neben dem bestehenden
  `S` (Status) einsortiert — öffnet
  `gitsuite.features.ui.lazygit(record.path)` für das Repo unter dem
  Cursor. Optionale weiche Abhängigkeit, Notify statt Fehler ohne
  gitsuite.nvim.
- **cmdlog.nvim** (`e773aff`): neues `mappings.lazygit` (Default `<C-g>`),
  nur im Projekt-Picker gebunden (`opts.lazygit`-Flag in der geteilten
  `ui/mappings.lua`-Factory, dasselbe Muster wie `tag`/`reorder`) — öffnet
  lazygit für `project_history.get_git_root()`.
- **sandbox.nvim** (`b699e31`): neuer Befehl `:Sandbox devcontainer lazygit`
  — öffnet lazygit für `workspace_dir` (die **Host**-Verzeichnis, das in den
  Container gemountet wird, nicht ein Pfad *im* Container, da lazygit immer
  auf dem Host läuft).

## Tests

reposcope.nvim: `TESTS/dashboard_view_spec.lua` — `L` zur
Tastenkarte-Vollständigkeitsliste ergänzt, zwei neue Fälle (gefaktes
`gitsuite.features.ui.lazygit` wird mit dem Pfad des Repos unter dem Cursor
aufgerufen; ohne gitsuite.nvim installiert kein Fehler).
cmdlog.nvim: kein dedizierter neuer Test — folgt dem etablierten Muster
dieser Datei, in dem `tag`/`reorder`-Mappings ebenfalls nicht einzeln
funktional getestet werden (nur generische Config-Merge-Tests decken neue
Mapping-Schlüssel ab); volle `smoke_spec.lua`-Suite grün (385 passed, 0
failed, 1 skipped, unverändert).
sandbox.nvim: `TESTS/sandbox/bindings/usrcmds/commands_misc_spec.lua` (neuer
Block) und `routes_spec.lua` (`devcontainer_commands`-Liste um `lazygit`
ergänzt) — belegt den korrekten Workspace-Pfad und "nicht installiert"-
Meldung ohne gitsuite.nvim. `stylua`/`luacheck` grün in allen drei Repos,
volle Suiten grün.

## Ergebnis

CI grün auf allen Systemen aller drei Repos (`gh run view` bestätigt
`completed success` für reposcope.nvim `35760649534`, cmdlog.nvim
`35760678102`, sandbox.nvim `35760709710`).

## Dokumentation mitgezogen

reposcope.nvim: `docs/BINDINGS.md`, `docs/requirements.md`.
cmdlog.nvim: `docs/configuration.md` (neuer Abschnitt "Project: lazygit"),
`docs/installation.md`.
sandbox.nvim: `docs/BINDINGS.md`, `docs/GENERATED_COMMANDS.md` (manuell
nachgezogen — `:Sandbox docs generate` ließ sich in dieser Session nicht
zum Laufen bringen, `:Sandbox` registrierte sich nicht unter dem
Headless-Testaufbau; die Zeile folgt exakt dem bestehenden Format),
`docs/FEATURES/DEVCONTAINER.md`, `docs/installation.md`.
