# Claude-Worktrees und -Branches: offene Reste

> Stand 2026-09-21 (nachmittags, nach dem zweiten Lauf). Aufräumlauf über die 39
> Plugin-Repos unter `E:\repos` und diese Config. Diese Liste enthält **nur**, was
> danach noch eine Entscheidung oder Handlung braucht: uncommittete Änderungen,
> Commits, die nicht in `main` sind, und zwei Worktrees, die sich nicht entfernen
> ließen. Was verlustfrei weg konnte, ist weg und steht hier nicht.
> Verglichen wurde gegen `origin/main` (nach `git fetch`), „nicht in main“ nach
> Patch-ID (`git cherry`), nicht nur nach SHA.

## Table of content

- [1. Uncommittete Änderungen](#1-uncommittete-änderungen)
- [2. Commits, die nicht in main sind](#2-commits-die-nicht-in-main-sind)
- [3. Nichts Offenes, aber gerade in Benutzung](#3-nichts-offenes-aber-gerade-in-benutzung)
- [Hinweise](#hinweise)

---

## 1. Uncommittete Änderungen

- [ ] **ui.nvim, Tabline-Umbau (laufende Session)**
  - Worktree `E:\repos\ui.nvim\.claude\worktrees\rules-nvim-review-277-071e53`,
    zuletzt gesehen auf Branch `claude/tableiste-tab-context-menu-f812d9` (bei
    Lauf-Ende noch detached bei `3890818`, dann von der Session angelegt).
    Beim ersten Lauf war er sauber; die Änderungen kamen erst danach, dort wird
    gerade gearbeitet.
  - Zuletzt 10 Änderungen (Zahl wächst), darunter: geändert `TESTS/tabufline_state_spec.lua`, `lua/ui/@types/init.lua`,
    `lua/ui/bindings/keymaps/tabufline/state.lua`, `lua/ui/tabline/modules.lua`,
    `lua/ui/tabline/utils.lua`; neu und untracked `lua/ui/tabline/drag.lua`,
    `lua/ui/tabline/layout.lua`, `lua/ui/tabline/menu.lua`.
  - Task: nach Abschluss der Session committen und nach `main` bringen (stylua,
    luacheck und `bash scripts/test.sh` vorher grün), **oder** bewusst verwerfen.
    Erst danach den Worktree entfernen
    (`git -C E:\repos\ui.nvim worktree remove <worktree>`). Der Branch der Session
    (`claude/tableiste-tab-context-menu-f812d9`) gehört danach ebenfalls bereinigt.

- [ ] **runtime-analysis.nvim, Telemetry-Status**
  - Worktree `E:\repos\runtime-analysis.nvim\.claude\worktrees\ratelemetry-status-46d39e`,
    Branch `claude/ratelemetry-status-46d39e` (gepusht, 0 Commits vor main, Basis
    165 h alt).
  - 4 geänderte Dateien, +162/−16: `TESTS/telemetry_spec.lua`,
    `lua/runtime-analysis/telemetry/@types/init.lua`,
    `lua/runtime-analysis/telemetry/command.lua`,
    `lua/runtime-analysis/telemetry/init.lua`. Nach Branch-Name ein `status`-Befehl
    für die Telemetrie; der Inhalt wurde nicht geprüft.
  - Task: Änderung ansehen, dann committen und pushen (Specs und Lint laufen
    lassen) **oder** verwerfen (`git -C <worktree> checkout -- .`). Danach den
    Worktree entfernen:
    `git -C E:\repos\runtime-analysis.nvim worktree remove <worktree>`, und den
    Branch löschen.

- [ ] **mdview.nvim, Wegwerfdatei**
  - Worktree `E:\repos\mdview.nvim\.claude\worktrees\mdview-nvim-replacement-cb13d0`,
    Branch `claude/mdview-nvim-replacement-cb13d0` (gepusht, 0 Commits vor main).
  - Einzige Änderung: `help_out.txt` (untracked, 69 KB), ein Dump von
    `:help cmdline`, also Abfall. Die Datei wurde gestern 20:09 geschrieben,
    deshalb wurde der Worktree als möglicherweise aktive Session nicht angefasst.
  - Task: Datei löschen, Worktree entfernen (wie oben), Branch löschen.

## 2. Commits, die nicht in main sind

Alle hier im Config-Repo (`C:\Users\bartl\AppData\Local\nvim`), alle **nicht auf
einem Remote**. In den Plugin-Repos gibt es keine.

- [ ] **Dispatcher-Report, zweite Runde** (Commit `6f3c5f313`, +160/−32 in
  `docs/ROADMAP/reports/Autocmd-Dispatcher-Nutzung-und-Nutzen.md`)
  - Derselbe Commit steht auf vier Branches (Aliase): `claude/autocmd-dispatcher-roadmap-22c9ba`,
    `claude/externe-plugins-nachbau-88158c`, `claude/mdview-autocmds-registry-f4f0ce`,
    `claude/regel-audit-review-521280`.
  - `main` hat den Report inzwischen entfernt (zuletzt angefasst in `1ede45835`,
    die Datei existiert dort nicht mehr), daher würde ein Merge konfliktieren.
  - Task: Inhalt retten
    (`git show 6f3c5f313:docs/ROADMAP/reports/Autocmd-Dispatcher-Nutzung-und-Nutzen.md`,
    z. B. in die WKDBooks) **oder** verwerfen. Danach die vier Branches löschen.
  - Die zwei Vorgänger-Commits derselben Kette sind der Wirkung nach schon in
    `main`: der Aufwand-Nutzen-Report ist dort gelöscht, B7 aus der `ROADMAP.md`
    entfernt. Kein Handlungsbedarf.

- [ ] **`claude/roadmap-aufwand-nutzen-update-9e7906`** (Commit `d4b9f9e5c`)
  - Löscht den Report `Roadmap-Aufwand-Nutzen.md` (auf main schon weg) und ändert
    5 Zeilen in `Regel-Audit-Tasks.md` und `Tasks-offene-Punkte.md`. Beide Dateien
    hat `main` mit `807e921e4` ins WKDBooks-Backlog verschoben.
  - Task: prüfen, ob die verschobenen Kopien noch auf den gelöschten Report
    verweisen; wenn nicht, Branch löschen.

- [ ] **`claude/zen-panini-183f41`** (Commits `4f72bdee0`, `fcc068ff6`)
  - Klären die offene Frage SEC-42 (documentation.nvim, Parameter `snapshot`) in
    `docs/ROADMAP/reports/Regel-Audit-Befunde.md`, +4 Zeilen plus Korrekturen.
  - Die Datei ist auf main durch `94f1709fd` (drei Regel-Audit-Reports
    zusammengeführt) weg, und „SEC-42“ kommt in `docs/` auf main nirgends mehr vor.
  - Task: prüfen, ob die Klärung im konsolidierten Report fehlt und übernommen
    werden muss (`git show 4f72bdee0 fcc068ff6`); sonst Branch löschen.

## 3. Nichts Offenes, aber gerade in Benutzung

Beide Worktrees sind sauber und ihr Inhalt steckt vollständig in `main`. Sie ließen
sich nicht entfernen, weil eine laufende Session sie als Arbeitsverzeichnis hält.

- [ ] **ui.nvim `roadmap-regeln-nvim-manual-0f8fb4`**, Branch
  `claude/ui-sticky-context-12370f` (auf `main`, außerdem als Backup gepusht).
  Das ist die Session, die diesen Lauf gemacht hat. Ein Worktree lässt sich unter
  Windows nicht löschen, solange ein Prozess darin steht. Task, nach Ende der
  Session aus einem anderen Verzeichnis:
  `git -C E:\repos\ui.nvim worktree remove E:\repos\ui.nvim\.claude\worktrees\roadmap-regeln-nvim-manual-0f8fb4`
  und `git -C E:\repos\ui.nvim branch -D claude/ui-sticky-context-12370f`.

- [ ] **Config `menu-integration-ui-kit-712771`**, Branch
  `claude/ci-hardening-nvim-ced241` (steht auf `84eb9778b`, gleich `main`).
  Beim zweiten Lauf brach das Entfernen mit „Permission denied“ ab, nachdem git
  die Registrierung und alle Dateien schon gelöscht hatte; vier Shell-Prozesse
  (`bash.exe`, `powershell.exe`) hielten das Verzeichnis, dort läuft also eine
  Session. Der Worktree wurde am Branch-Tip wiederhergestellt (sauber, kein
  Inhalt ging verloren; die Session muss ggf. ihr Verzeichnis neu betreten).
  Task: nach Ende dieser Session entfernen und den Branch löschen.

## Hinweise

- `E:\repos\documentation.nvim\.claude\worktrees\lib.nvim` ist eine **Junction**
  auf `E:\repos\lib.nvim`, kein Worktree-Rest. Nicht löschen: sie lässt die
  Geschwister-Suche der Tests im Worktree `lib.nvim` finden.
- Auf GitHub liegen weiterhin alle bereits gepushten `claude/*`-Branches. Es
  wurden nur lokale Branches gelöscht; Remote-Branches sind unberührt.
- Löschkriterium der Läufe. Worktrees: sauber (oder nur generierter Abfall) und
  jeder Commit per Patch-ID schon in `origin/main`, bzw. nichts Ungepushtes.
  Lokale Branches: nirgends ausgecheckt und vollständig auf einem Remote, oder
  nachweislich inhaltlich schon in main. Vor jedem Löschen wurde der Zustand
  erneut geprüft, kein `--force` außer für den `$SCRATCH`-Abfall.
- Für künftige Läufe: **vor** dem Entfernen prüfen, ob ein Prozess den Worktree
  hält (`Get-CimInstance Win32_Process | Where-Object CommandLine -like '*<name>*'`),
  nicht erst am Fehler. Sauber und Patch-ID-in-main heißt „nichts geht verloren“,
  aber nicht „keiner arbeitet gerade darin“.
