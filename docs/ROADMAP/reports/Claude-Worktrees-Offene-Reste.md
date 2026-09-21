# Claude-Worktrees und -Branches: offene Reste

> Stand 2026-09-21 (nachmittags). Aufräumlauf über die 39 Plugin-Repos unter
> `E:\repos` und diese Config. Diese Liste enthält **nur**, was nach dem Lauf noch
> eine Entscheidung braucht: uncommittete Änderungen und Commits, die nicht in
> `main` sind. Was verlustfrei weg konnte, ist weg und steht hier nicht.
> Verglichen wurde gegen `origin/main` (nach `git fetch`), „nicht in main“ nach
> Patch-ID (`git cherry`), nicht nur nach SHA.

## Table of content

- [1. Uncommittete Änderungen](#1-uncommittete-änderungen)
- [2. Commits, die nicht in main sind](#2-commits-die-nicht-in-main-sind)
- [3. Nichts Offenes, nur noch nicht entfernt](#3-nichts-offenes-nur-noch-nicht-entfernt)
- [Hinweise](#hinweise)

---

## 1. Uncommittete Änderungen

- [ ] **runtime-analysis.nvim, Telemetry-Status**
  - Worktree `E:\repos\runtime-analysis.nvim\.claude\worktrees\ratelemetry-status-46d39e`,
    Branch `claude/ratelemetry-status-46d39e` (gepusht, 0 Commits vor main, Basis
    165 h alt).
  - 4 geänderte Dateien, +162/−16: `TESTS/telemetry_spec.lua`,
    `lua/runtime-analysis/telemetry/@types/init.lua`,
    `lua/runtime-analysis/telemetry/command.lua`,
    `lua/runtime-analysis/telemetry/init.lua`. Nach Branch-Name ein `status`-Befehl
    für die Telemetrie; der Inhalt wurde nicht geprüft.
  - Entscheiden: committen und pushen (dann Specs und Lint laufen lassen) **oder**
    verwerfen (`git -C <worktree> checkout -- .`). Danach den Worktree entfernen:
    `git -C E:\repos\runtime-analysis.nvim worktree remove <worktree>`.

- [ ] **mdview.nvim, Wegwerfdatei**
  - Worktree `E:\repos\mdview.nvim\.claude\worktrees\mdview-nvim-replacement-cb13d0`,
    Branch `claude/mdview-nvim-replacement-cb13d0` (gepusht, 0 Commits vor main).
  - Einzige Änderung: `help_out.txt` (untracked, 69 KB), ein Dump von
    `:help cmdline`, also Abfall. Die Datei wurde gestern 20:09 geschrieben, deshalb
    wurde der Worktree als möglicherweise aktive Session nicht angefasst.
  - Datei löschen, dann Worktree entfernen (wie oben).

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
  - Entscheiden: Inhalt retten
    (`git show 6f3c5f313:docs/ROADMAP/reports/Autocmd-Dispatcher-Nutzung-und-Nutzen.md`,
    z. B. in die WKDBooks) **oder** verwerfen. Danach die vier Branches löschen.
  - Die zwei Vorgänger-Commits derselben Kette sind der Wirkung nach schon in
    `main`: der Aufwand-Nutzen-Report ist dort gelöscht, B7 aus der `ROADMAP.md`
    entfernt. Kein Handlungsbedarf.

- [ ] **`claude/roadmap-aufwand-nutzen-update-9e7906`** (Commit `d4b9f9e5c`)
  - Löscht den Report `Roadmap-Aufwand-Nutzen.md` (auf main schon weg) und ändert
    5 Zeilen in `Regel-Audit-Tasks.md` und `Tasks-offene-Punkte.md`. Beide Dateien
    hat `main` mit `807e921e4` ins WKDBooks-Backlog verschoben.
  - Prüfen, ob die verschobenen Kopien noch auf den gelöschten Report verweisen;
    wenn nicht, Branch löschen.

- [ ] **`claude/zen-panini-183f41`** (Commits `4f72bdee0`, `fcc068ff6`)
  - Klären die offene Frage SEC-42 (documentation.nvim, Parameter `snapshot`) in
    `docs/ROADMAP/reports/Regel-Audit-Befunde.md`, +4 Zeilen plus Korrekturen.
  - Die Datei ist auf main durch `94f1709fd` (drei Regel-Audit-Reports
    zusammengeführt) weg, und „SEC-42“ kommt in `docs/` auf main nirgends mehr vor.
  - Prüfen, ob die Klärung im konsolidierten Report fehlt und übernommen werden
    muss (`git show 4f72bdee0 fcc068ff6`); sonst Branch löschen.

## 3. Nichts Offenes, nur noch nicht entfernt

Diese Worktrees sind sauber und alles darin steckt in `main`. Sie blieben nur
stehen, weil in den letzten 24 h ein Commit oder eine Dateiänderung war (mögliche
laufende Session). Beim nächsten Aufräumlauf sind sie löschbar.

| Repo | Worktree | Branch |
|---|---|---|
| filetree.nvim | `filetree-checkmarks-persist-16f23c` | detached |
| gitsuite.nvim | `gitsuite-implementierungsplan-f6be05` | `claude/gitsuite-implementierungsplan-f6be05` |
| images.nvim | `nvim-image-plugins-review-d6d0c2` | `claude/nvim-image-plugins-review-d6d0c2` (1 Commit nach SHA ungepusht, Inhalt per Patch-ID in main) |
| lib.nvim | `lib-nvim-deps-analysis-963af9`, `lib-nvim-quick-wins-dc99ed` | detached |
| markdown.nvim | `integrations-menu-layout-0794ed`, `lspsaga-lsp-nvim-features-f492d1`, `markdown-headline-formatting-5407a6` | `claude/markdown-breadcrumbs-links-a5e193`, `claude/lspsaga-lsp-nvim-features-f492d1`, `claude/markdown-breadcrumbs-toggle-a043c2` |
| media.nvim | `media-nvim-handover-roadmap-2b7c97` | detached (Datei-Aktivität: `.github/workflows/ci.yml`) |
| reposcope.nvim | `reposcope-status-dashboard-rename-421b8d` | detached |
| ui.nvim | `rules-nvim-review-277-071e53` | detached |
| ui.nvim | `roadmap-regeln-nvim-manual-0f8fb4` (Session, in der dieser Lauf lief) | `claude/ui-sticky-context-12370f`, komplett in main |
| Config | `ai-loomai-handover-tasks-6dcab4`, `buffer-write-framerate-2c6a85`, `nvim-plugins-quality-review-30b806` | detached |
| Config | `externe-plugins-nachbau-88158c` | `claude/gitsuite-nvim-plugin-c4fcb8` |
| Config | `menu-integration-ui-kit-712771` | `claude/ci-hardening-nvim-ced241` (1 Commit nach SHA ungepusht, Inhalt per Patch-ID in main) |

## Hinweise

- `E:\repos\documentation.nvim\.claude\worktrees\lib.nvim` ist eine **Junction**
  auf `E:\repos\lib.nvim`, kein Worktree-Rest. Nicht löschen: sie lässt die
  Geschwister-Suche der Tests im Worktree `lib.nvim` finden.
- Auf GitHub liegen weiterhin alle bereits gepushten `claude/*`-Branches. Es
  wurden nur lokale Branches gelöscht; Remote-Branches sind unberührt.
- Löschkriterium des Laufs. Worktrees: sauber (oder nur generierter Abfall),
  nichts Ungepushtes, letzter Commit älter als 24 h und keine Dateiänderung der
  letzten 24 h darin. Lokale Branches: nirgends ausgecheckt und vollständig auf
  einem Remote, oder nachweislich inhaltlich schon in main. Vor jedem Löschen
  wurde der Zustand erneut geprüft.
