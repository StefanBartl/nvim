# GS-14 — Sammel-Swaps: `insights`/`buffer-ctx`/`diff`/`fileops` → `lib.nvim.git`

**Repos:** insights.nvim, buffer-ctx.nvim, diff.nvim, fileops.nvim,
lib.nvim (`head_hash`/`describe` ergänzt) · **Nutzen** 4 · **Risiko** niedrig
· **Welle** 3 (Duplikate) · erledigt 2026-09-22.

## Ausgangslage

Vier Schwesterplugins liefen eigene Git-Shellouts statt `lib.nvim.git` zu
nutzen — die letzten vier der „sieben parallelen Git-Shellouts" aus dem
Cross-Feature-Report (`GS-12`/`GS-13` hatten die anderen drei geschlossen).
`K-5b` verlangte für `insights.conflicts` ausdrücklich eine Umstellung
**nach unten** zu `lib.nvim`, nicht seitwärts zu gitsuite — die zwei hätten
sonst per `pcall` aneinander delegiert (Endlosschleife).

## Umsetzung, je Repo

- **lib.nvim** (`f841f6f`): `head_hash` (Geschwister von `head_short_hash`)
  und `describe` (`git describe --tags --always`, bisher nur in `info()`s
  Drei-Prozess-Snapshot eingebacken) als eigenständige Funktionen ergänzt.
- **insights.nvim** (`6471483`): `conflicts/init.lua` ersetzt zwei Prozesse
  (`rev-parse --is-inside-work-tree` + `diff --name-only --diff-filter=`)
  durch einen `status_porcelain`/`_async`-Aufruf, client-seitig auf die
  sieben echten Unmerged-XY-Codes gefiltert (UU/AA/DD/AU/UD/UA/DU — nicht auf
  „enthält U" reduzierbar, AA/DD tragen kein U). Maß: ~120 ms
  Main-Loop-Block auf Windows für den asynchronen VimEnter-Pfad, jetzt ein
  Aufruf statt zwei. `cfg.diff_filter` (Default `"U"`) matcht jetzt eine
  XY-Spalte statt als `--diff-filter=`-Argument an `git diff` zu gehen.
- **buffer-ctx.nvim** (`563d601`): `hash`/`short`/`branch`/`tag` nutzen
  `head_hash`/`head_short_hash`/`current_branch`/`describe` direkt.
  `is_detached_head()` bleibt als eigener Check bestehen (die spezifische
  „detached HEAD"-Meldung hängt nicht an `current_branch()`s generischem
  `nil`).
- **diff.nvim** (`f96c198`): `core.git.resolve()` geht über
  `lib.nvim.git.show_async` statt eines selbst gebauten `vim.system`-Aufrufs;
  `repo_root()` blieb unverändert (reiner `vim.fs.find`-Walk, kein Shellout).
  Die explizite „Neovim 0.10+"-Guard entfiel: `run_async_captured`
  degradiert selbst auf `vim.fn.system`, wenn `vim.system` fehlt.
- **fileops.nvim** (`c4fa9cf`): `is_tracked` delegiert an
  `lib.nvim.git.is_tracked`. `mv`/`rm` bleiben lokal (kein
  `lib.nvim.git`-Äquivalent, fileops ist einziger Konsument —
  `TOOL-PLACEMENT.md` Fall 4 noch nicht erfüllt); `is_tracked_async` bleibt
  unangetastet (kein produktiver Aufrufer, `lib.nvim.git.is_tracked` ist
  ohnehin nur synchron).

## Dokumentierte Verhaltensänderungen

Nicht stillschweigend verloren: alle vier Module quotierten früher Gits
eigene stderr-Meldung in ihrer Fehlermeldung (z. B.
`"fatal: not a git repository"`); `lib.nvim.git`s blockierende Aufrufe
fangen nur stdout, Fehlermeldungen sind jetzt generisch (z. B.
`"git: could not resolve <mode>"` statt Gits Original-Text). In jedem
Commit einzeln vermerkt und in den jeweiligen Specs nachgezogen — kein Test
prüfte den exakten Git-Text, nur Präfixe/Sonderfälle (z. B. „detached HEAD").

## Ergebnis

Alle fünf Commits einzeln CI-grün auf allen drei Systemen,
`stylua`/`luacheck` sauber, lokale Suiten grün (`INSIGHTS_TESTS_OK`,
`BUFFER_CTX_TESTS_OK`, `DIFF_NVIM_TESTS_OK`, `FILEOPS_TESTS_OK`). `K-5b`
damit umgesetzt wie empfohlen (nach unten, nicht seitwärts).

## Nachwirkung

`lib.nvim.git.head_hash`/`describe` sind jetzt öffentliche API — der nächste
Konsument kann direkt darauf aufsetzen, ohne eigenen Shellout.
