# CI-Sofortmaßnahmen — Stand und Wiederaufnahme

> Ausgelagert aus [testing.md §D.9.0](testing.md#d90-sofortmaßnahmen-ohne-specnvim-je--1-tag)
> am 2026-09-20, als der Flotten-Rollout auf Zuruf gestoppt wurde. **In die
> 38 Plugin-Repos wurde noch nichts geschrieben** — nur Dry-Runs. Erledigt ist
> allein Maßnahme 6 (config-lokal). Der Rollout-Transformer liegt fertig und
> geprüft unter [`scripts/ci_hardening.py`](../../../../scripts/ci_hardening.py).

## Table of content

- [Status je Maßnahme](#status-je-maßnahme)
- [Befunde der Bestandsaufnahme (2026-09-20)](#befunde-der-bestandsaufnahme-2026-09-20)
- [Was der Transformer tut](#was-der-transformer-tut)
- [Wiederaufnahme: Ablauf](#wiederaufnahme-ablauf)
- [Runde 2: ci-verified für ui/documentation/pickers](#runde-2-ci-verified-für-uidocumentationpickers)
- [Offene Entscheidungen und Risiken](#offene-entscheidungen-und-risiken)

## Status je Maßnahme

| # | Maßnahme | Status | Umsetzung |
|---|---|---|---|
| 1 | `timeout-minutes` in allen Workflows | **offen** | Transformer: 15 min je Job, 30 min bei Build-Jobs (`cargo`, `wasm-pack`, `npm ci/install`, `tree-sitter build`, `goreleaser`, `apt-get`) |
| 2 | `-n -i NONE` in allen Runner-Aufrufen | **offen** | Transformer: `ci.yml`-`run:`-Zeilen, `scripts/test.sh`, `scripts/ci.sh`; zusätzlich `vim.o.swapfile = false` + `vim.o.shadafile = "NONE"` in jeder `minimal_init.lua`, damit auch plenarys **Kind-Prozesse** (die dieselbe Datei laden) abgedeckt sind |
| 3 | Log-Artefakt bei Fehlschlag | **offen** | Transformer: Test-Steps werden zu `run: \|`-Blöcken mit `exec > >(tee -a "$RUNNER_TEMP/test-output.log") 2>&1` als erster Zeile, plus `actions/upload-artifact@v4` mit `if: failure()` je Job; nur in `ci.yml`, nur in Jobs mit `shell: bash` oder ohne Windows |
| 4 | `docs/TESTS/` → `TESTS/` (NEW-48) | **erledigt (war schon)** | kein Repo hat mehr `docs/TESTS/` — die Zahl „9×" in §A.1 stammt vom Scan 2026-08-17 und ist überholt |
| 5 | `.deps/`-Refs pinnen | **offen, zweistufig** | Transformer pinnt `lib.nvim`/`runtime-analysis.nvim`/`hover.nvim` auf `ci-verified` und Third-Party auf den HEAD-SHA vom 2026-09-20; `ui.nvim`/`documentation.nvim`/`pickers.nvim` **haben keinen `ci-verified`-Branch** → Runde 2 |
| 6 | `run_all_tests.sh`: `$NVIM` streichen, `-n` | **erledigt** | `env -u NVIM -u NVIM_LISTEN_ADDRESS`, `nvim -n --clean …` (`--clean` impliziert `-i NONE`) |

## Befunde der Bestandsaufnahme (2026-09-20)

- **38 Workflow-Dateien**: 37× `ci.yml` plus `color_my_ascii.nvim/.github/workflows/lint.yml`
  (dort heißt die Datei anders, hat aber dieselben drei Jobs). Weitere
  Workflows (`pages.yml`, `release-engine.yml` in documentation.nvim,
  `pages.yml` in runtime-analysis.nvim) bekommen nur Timeouts.
- **Kein einziges `timeout-minutes`** in der Flotte. **Kein Log-Artefakt**
  (mdview.nvims einziges `upload-artifact` ist das WASM-Build-Artefakt).
- **Alle 38 Arbeitsbäume waren sauber** (kein `git status`-Rauschen) —
  Zustand kann sich bis zur Wiederaufnahme ändern (andere Sessions arbeiten
  in denselben Checkouts), vor dem Commit je Repo erneut prüfen.
- **Job-Formen variieren**: Job-IDs `stylua/luacheck/tests`, `lint/test`,
  `smoke`, `docs`, `map`, `standalone`, `nvim-specs`; Checkouts nach
  `.deps/<name>` **oder** als Sibling (`path: lib.nvim`); `run:` ein- oder
  mehrzeilig; `with: { neovim: true }` inline. Deshalb ist der Transformer
  zeilenbasiert (PyYAML würde alle Kommentare verwerfen) und wurde gegen
  lib, casedesk, filetree, cmdlog, lsp, mdview, documentation und
  color_my_ascii per Dry-Run geprüft.
- **`ci-verified` existiert** für `lib.nvim`, `runtime-analysis.nvim`,
  `hover.nvim`; **fehlt** für `ui.nvim` (16 Consumer-Jobs), `documentation.nvim`
  (2: hover, rules) und `pickers.nvim` (1: recommender). filetree.nvim
  dokumentiert das sogar im Kommentar („No `ref:` pin: ui.nvim does not
  publish a ci-verified branch").
- **Third-Party-Checkouts** (13× plenary, je 1× nui, neo-tree, telescope,
  nvim-tree) sind alle ungepinnt. HEAD-SHAs vom 2026-09-20, im Transformer
  hinterlegt: plenary `74b06c6c…`, nui `10fc3618…`, neo-tree `162f9b95…`,
  telescope `40aedd8a…`, nvim-tree `8d814495…`.
- **`exec > >(tee -a …) 2>&1` funktioniert in Git Bash unter Windows**
  (lokal geprüft: stdout+stderr landen in der Datei, Exit-Code 3 bleibt 3).
  Alle Matrix-Jobs setzen `defaults.run.shell: bash`, also gilt das auch für
  die Windows-Runner.

## Was der Transformer tut

`scripts/ci_hardening.py` (Python 3, keine Abhängigkeiten):

```bash
python scripts/ci_hardening.py --dry-run E:/repos/*.nvim   # Diffs + NOTEs, schreibt nichts
python scripts/ci_hardening.py --apply   E:/repos/lib.nvim   # schreibt, ein Repo
```

Je Repo: `.github/workflows/*.yml` (Timeouts, Pins, nvim-Flags; Artefakt nur
in `ci.yml`), `scripts/test.sh`, `scripts/ci.sh` (nvim-Flags),
`TESTS/minimal_init.lua` bzw. `scripts/minimal_init.lua` (swapfile/shada).
Idempotent: ein zweiter Lauf ändert nichts mehr. `NOTE`-Zeilen melden, was
bewusst ungepinnt bleibt. Zeilenenden werden beibehalten.

Bekannte, akzeptierte Nebeneffekte im Dry-Run: in documentation.nvims
`map`-Job wird auch der Self-Heal-Step gewrappt und der Hinweistext
`run 'nvim --headless -l scripts/gen_map.lua'` bekommt ebenfalls
`-n -i NONE` (harmlos); filetree.nvims `lint`-Job bekommt 30 min, weil er
luacheck per `apt-get` installiert.

## Wiederaufnahme: Ablauf

1. `git -C E:/repos/<repo> status --porcelain` — nur weiterarbeiten, wenn
   die vom Transformer berührten Dateien nicht bereits fremd geändert sind.
2. `python scripts/ci_hardening.py --dry-run E:/repos/<repo>` lesen,
   dann `--apply`.
3. `luacheck` + `stylua --check` auf die geänderte `minimal_init.lua`
   (nur die Repos mit einer solchen Datei: ai, casedesk, dap, data,
   github_stats, hover, lsp, mdview, my, rules, sandbox, ui).
4. Nur die geänderten Dateien stagen (nie `git add -A`), Commit ohne
   Co-Authorship, z. B.
   `ci: add job timeouts, failure log artifacts, swap/shada-free nvim runs, pinned deps`,
   dann `git fetch origin main`, bei Bedarf `git rebase origin/main`, push.
5. **ui.nvim nur über ein Worktree** (`ui.nvim/.claude/worktrees/…`), nie im
   Primär-Checkout: dort anwenden, committen, `git push origin HEAD:main`.
6. In Batches pushen (z. B. 8 Repos), danach
   `scripts/ci_status.sh --red` — jeder Push startet drei Matrix-Jobs, 38
   Repos auf einmal sind ~150 Jobs.
7. Zum Schluss `scripts/ci_hardening.py` löschen (Einmal-Werkzeug im Sinne
   von TOOL-PLACEMENT; der Commit bleibt als Beleg) und diese Datei auf
   „erledigt" setzen.

## Runde 2: ci-verified für ui/documentation/pickers

Reihenfolge ist zwingend — ein `ref: ci-verified` auf einen Branch, den es
noch nicht gibt, bricht den Checkout:

1. In `ui.nvim`, `documentation.nvim`, `pickers.nvim` je einen
   `publish-ci-verified`-Job ergänzen (Vorlage: lib.nvims `ci.yml`, Job
   `publish-ci-verified`; `needs:` = alle Gate-Jobs des Repos: ui.nvim
   `[stylua, luacheck, tests]`, documentation.nvim
   `[stylua, luacheck, tests, map, standalone]`, pickers.nvim `[lint, test]`).
2. Push auf `main`, CI grün abwarten, dann prüfen:
   `git ls-remote --heads https://github.com/StefanBartl/ui.nvim ci-verified`.
3. Im Transformer `PIN_BRANCH` um die drei Repos erweitern und erneut
   `--dry-run`/`--apply` über die Flotte (idempotent, ändert nur die noch
   offenen Pins). filetree.nvims Kommentar zum fehlenden ui.nvim-Pin dabei
   von Hand entfernen.

## Offene Entscheidungen und Risiken

- **Timeout-Werte** (15/30) sind Heuristik; ein Repo mit langsamem
  macOS-Runner kann bei 15 min knapp werden — dann gezielt hochsetzen, nicht
  global.
- **Artefakt-Namen** `test-output-<job>-<os>`; bei mehreren gewrappten Steps
  in einem Job wird angehängt (`tee -a`), ein Artefakt je Job.
- **`TESTS/run.lua`-Kopfkommentare** nennen weiterhin die alten Aufrufe ohne
  `-n` — Dokumentationsdrift, kein Funktionsproblem; bei Gelegenheit
  nachziehen.
- **Third-Party-Pins veralten bewusst** (Kommentar „bump deliberately, not
  by drifting"); ein späteres Anheben ist ein eigener, sichtbarer Commit.
- **Blast radius**: eine fehlerhafte YAML-Änderung würde in allen Repos
  zugleich rot; deshalb Batches und `ci_status.sh` nach jedem Batch.
