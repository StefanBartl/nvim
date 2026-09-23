# GS-15 — `ui.nvim`s `git_clickable` auf lib-Primitive, plus `lib.nvim.git.checkout`

**Repos:** ui.nvim, lib.nvim (`checkout` ergänzt), gitsuite.nvim
(`branch.switch` konsumiert `checkout` mit) · **Nutzen** 3 · **Risiko**
niedrig · **Welle** 3 (Duplikate) · erledigt 2026-09-22.

## Ausgangslage

`ui/statusline/modules/git_clickable/init.lua` ist laut eigenem Docstring
die Quelle, aus der gitsuites `branch`-Feature extrahiert wurde, wurde aber
selbst nie auf `lib.nvim.git` umgestellt: `list_branches()`/`checkout()`
riefen weiterhin `vim.fn.systemlist` direkt — ohne `-C`/`opts.dir`-Unterstützung
(das Modul konnte nie ein anderes Repo als das cwd der Editor-Session
ansteuern), und `systemlist` faltet `stderr` eines fehlgeschlagenen Aufrufs
in seine Ausgabe, während `lib.nvim.git`s Lese-Helfer grundsätzlich nur
`stdout` erfassen.

`lib.nvim.git` hatte außerdem noch keinen `checkout`-Wrapper — gitsuites
eigenes `branch.switch()` rief `run_blocking_captured({"git","checkout",...})`
direkt auf, mit demselben `stdout`-only-Problem: ein fehlgeschlagener
Checkout meldete "failed: " mit leerem Rest, weil `git checkout`s
Fehlertext auf stderr steht.

K-5c verlangte außerdem eine Lösung für den drohenden Zyklus `ui.nvim` ↔
gitsuite: `GS-09` (gitsuite → `ui.contextmenu`) und ein `ui.nvim` →
`gitsuite.branch`-Verweis hätten sich sonst gegenseitig referenziert.

## Umsetzung, je Repo

- **lib.nvim** (`ac87743`): `M.checkout(name, opts, git_cmd)` ergänzt —
  `git checkout <name>`, aber über `run_blocking` (nicht `run_blocking_captured`
  wie der Rest des Moduls), weil `run_blocking` tatsächlich `stderr` erfasst.
  Ein fehlgeschlagener Checkout liefert damit Gits echten Grund
  ("pathspec '<name>' did not match any file(s) known to git", "Your local
  changes ... would be overwritten"), nicht nur `ok = false`. Kein `--` vor
  `name`: das würde `git checkout` den Namen als Pfadspezifikation lesen
  lassen (Datei aus dem Index wiederherstellen) statt als Branch — genau das
  Gegenteil. Ein führender `-` wird stattdessen verweigert, derselbe Guard
  wie bei `show`s `rev`. Real-Fixture-Spec
  (`TESTS/git_checkout_spec.lua`): echter Branch-Wechsel, ein unbekannter
  Branch (Gits eigener "did not match"-Text übersteht den Aufruf), die
  `-`-Ablehnung rührt HEAD nicht an.
- **ui.nvim** (`9e4d64d`): `git_clickable` nutzt jetzt `lib.nvim.git.refs`/
  `current_branch` für die Branch-Liste, `lib.nvim.git.checkout` zum
  Wechseln. Die "kein Branch gefunden"-Unterscheidung (echter Git-Fehler vs.
  leeres, aber gültiges Repo) lief vorher über `vim.v.shell_error` +
  `systemlist`s gefaltete Fehlermeldung; `lib.nvim.git.refs`/`current_branch`
  geben das nicht mehr her, ersetzt durch einen expliziten
  `git.in_git_repo()`-Check (dokumentiert, nicht stillschweigend verloren).
  Linksklick delegiert an `gitsuite.features.branch.switch()`, wenn
  gitsuite.nvim geladen ist (`ui.util.soft_require`, als elfter Eintrag in
  dessen `PROBED`-Liste registriert — taucht damit auch in
  `:checkhealth ui` auf) — nie hart, nur `pcall`. Ohne gitsuite bleibt der
  ursprüngliche, unveränderte `vim.ui.select`-Picker als Fallback. Der
  Rechtsklick-Menüpunkt "Details" (`git status --short --branch`) blieb
  bewusst unangetastet: kein `lib.nvim.git`-Äquivalent für diese
  menschenlesbare Form, und der Plan-Umfang nannte nur
  `list_branches()`/`checkout()` als Problem.
- **gitsuite.nvim** (`c8c6ca7`): `branch.switch()`s lokaler `checkout()`-Helfer
  delegiert jetzt an `lib.nvim.git.checkout` statt einen eigenen
  `run_blocking_captured`-Aufruf zu duplizieren — zwei Konsumenten
  (`ui.nvim`, gitsuite), also gehört der Wrapper nach `lib.nvim`
  (`TOOL-PLACEMENT.md` Fall 4). Nebenwirkung, kein Zufallsgewinn: die alte
  Implementierung sah wegen `run_blocking_captured` nie `stderr`, jede
  bisherige Checkout-Fehlermeldung hier endete faktisch mit "failed: " und
  leerem Rest — `git.checkout` (via `run_blocking`) behebt das.

## Tests

`TESTS/statusline_clickable_spec.lua` (ui.nvim) mockt jetzt `vim.system`
(nach `cmd[2]`, dem Git-Subbefehl, geroutet) statt `vim.fn.systemlist`, plus
ein neuer Fall für die gitsuite-Delegation. Der ERR-11-Abschnitt (echtes
Git in echtem Temp-Verzeichnis, unterscheidet "kein Commit" von "kein
Repo") blieb unverändert — der mockte `vim.fn.systemlist` nie.
`TESTS/gitsuite/branch_spec.lua` (gitsuite.nvim) brauchte keine Änderung:
die acht Fälle prüfen echtes Git-Verhalten dieses Repos end-to-end, nicht
Interna des alten Helfers.

## Ergebnis

Alle drei Commits einzeln CI-grün auf allen drei Systemen
(`lib.nvim` zuerst, `ci-verified` abgewartet, dann `ui.nvim` und
gitsuite.nvim, K-6). Lokale Suiten grün: `LIB_TESTS_OK`, 59 Spec-Dateien in
ui.nvim, gitsuite.nvims volle `TESTS/gitsuite/`-Suite. `stylua`/`luacheck`
sauber in allen drei Repos.

## Dokumentation mitgezogen

`lib.nvim/lua/lib/nvim/git/README.md` (neuer Abschnitt "Checking out a
branch", `checkout` als einzige nicht seiteneffektfreie Funktion markiert),
`docs/API/commands-and-infra.md`, `docs/FEATURES/INFRA.md`;
`ui.nvim/docs/modules.md` (git_clickable-Zeile), `docs/health.md` ("Elf
soft dependencies" statt "Zehn", `gitsuite.features.branch` als
Sonderfall erklärt — degradiert eine Klick-Aktion, keinen Segment-Render).

## Nachwirkung

K-5c ist damit vollständig geschlossen: beide Richtungen zwischen `ui.nvim`
und gitsuite (`GS-09` und `GS-15`) sind strikt weich, keine harte Kante.
`lib.nvim.git.checkout` ist jetzt öffentliche API für jeden weiteren
Konsumenten, der einen Branch wechseln will, ohne einen eigenen Shellout zu
bauen.
