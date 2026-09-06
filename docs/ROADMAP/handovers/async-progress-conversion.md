# Handover — Synchrone Multi-File-Operationen auf async + `lib.nvim.progress`

## Table of content

  - [Ausgangslage](#ausgangslage)
  - [Standard-Muster (bei jeder Umsetzung gleich)](#standard-muster-bei-jeder-umsetzung-gleich)
  - [Kandidaten-Liste (aus der Analyse)](#kandidaten-liste-aus-der-analyse)
  - [Fortschritt](#fortschritt)
  - [Noch offen](#noch-offen)
  - [Verworfen / kein Handlungsbedarf](#verworfen--kein-handlungsbedarf)
  - [Vorgeschichte: die 4 Pässe aus Juli 2026](#vorgeschichte-die-4-pässe-aus-juli-2026)

---

## Ausgangslage

Frage des Users: „Ich dachte, wir haben fast alles Synchrone, wo es Sinn
macht, schon auf async umgestellt." — Stimmt weitgehend (siehe
[Vorgeschichte](#vorgeschichte-die-4-pässe-aus-juli-2026)): fast jeder
`vim.fn.system` / `:wait()` in der Flotte ist heute ein `if not vim.system`-
Fallback für Neovim < 0.10.

**Was der damalige Sweep nicht erfasst hat:** In-Prozess-Schleifen über viele
Dateien (kein Shell-Aufruf). Genau die werden hier nachgezogen.

Der Statusline-Indikator existiert bereits fleetweit:
`wkdnvchad.ui.statusline.modules.plugin_progress` rendert alle
`lib.nvim.progress.styles.statusline.active()`-Handles. Integration eines
neuen Plugins = nur `style = "statusline"` bzw. `progress_style = "statusline"`
mitgeben.

## Standard-Muster (bei jeder Umsetzung gleich)

1. **Schwellwert, kein Blanket-Async.** Kleine Sets bleiben exakt synchron
   (gleiche Timings, Tests unverändert). Erst ab `> CHUNK` Dateien wird
   gechunkt. `CHUNK` je nach I/O-Gewicht pro Datei: 8–10 bei
   `bufload`/`writefile`, 20 bei `readfile`, 40–100 bei reinem Parse.
2. **Optionaler `on_done`-Callback.** Öffentliche Funktion behält ihre
   synchrone Signatur (Rückgabewerte für Tests / Nicht-Callback-Aufrufer).
   Mit `on_done` und großem Set → gechunkt, Totals kommen über den Callback.
   Der synchrone Return ist dann ein Best-Effort-Snapshot (erster Chunk).
3. **Chunk-Loop:** `step()` verarbeitet `CHUNK` Einheiten, `h:update({text,
   current, total})`, `vim.schedule(step)` wenn mehr, sonst `h:finish(...)` +
   `on_done(...)`.
4. **Abbruch:** `if h and h.cancelled then` → bereits geschriebene Dateien
   bleiben geschrieben (keine Transaktion), Teilstand wird trotzdem gemeldet.
5. **Progress soft:** `pcall(require, "lib.nvim.progress")` — auch wo lib.nvim
   harte Dep ist (das *Submodul* kann in älteren lib.nvim-Ständen fehlen).
   Style aus `cfg.progress_style` (bzw. `symbols.progress_style` etc.).
6. **Aufrufer:** Usercmd-Handler sind meist fire-and-forget → keine Änderung
   oberhalb nötig. Picker/Confirm-Ketten: Callback durchreichen.
7. **Test:** ein neuer Block pro Repo, der den gechunkten Pfad mit
   `> CHUNK` Fixture-Dateien fährt und per `vim.wait` auf den Callback wartet.
8. **Docs mitziehen** (`doc/*.txt`, `docs/*.md`, README), **stylua + luacheck**,
   **commit + push auf `main`**, **kein Co-Author-Trailer**, CI-Lauf abwarten.

## Kandidaten-Liste (aus der Analyse)

### Tier 1 — klare Fälle (Form wie `:Replace` cwd)

| # | Ort | Blocker |
|---|---|---|
| 1 | `replacer.nvim` `lua/replacer/apply.lua` → `apply_matches` | Apply-Phase: `bufadd`/`bufload`/`nvim_buf_set_text`/`:write` pro Datei |
| 2 | `filetree.nvim` `lua/filetree/refs/apply.lua` → `run` + `undo` | `:Filetree refs` Symbol-Rename: `nvim_buf_set_lines`/`writefile` pro Datei |
| 3 | `documentation.nvim` `lua/documentation/bindings/usrcmds/annotate.lua` → `M.run` | `:DocMap annotate --write`: readfile+parse + write pro Kandidat |

### Tier 2 — seltener, aber real

| # | Ort | Blocker |
|---|---|---|
| 4 | `markdown.nvim` `lua/markdown/commands/links.lua` → `collect` (cwd) + `do_sanitize` (cwd) | `:Markdown links show\|sanitize cwd`: readfile(+writefile) pro `*.md` |
| 5 | `insights.nvim` `lua/insights/imports/init.lua` → `build_unused_report` | `:Insights imports unused`: re-read pro importierende Datei |
| 6 | `filetree.nvim` `lua/filetree/refs/scan.lua:151` | Sync-Fallback ohne ripgrep: gedeckelte `for _, file in ipairs(all)`-Leseschleife |

### Tier 3 — vom User gestrichen

- ~~#7 `gopath.nvim` `providers/lsp.lua` `buf_request_sync` (gd/gp)~~ — **nicht machen** (UX-Abwägung)
- ~~#8 `open.nvim` `keywords.lua` `capture()` `:wait()`~~ — **nicht machen** (gecached, ~300 ms einmalig)

## Fortschritt

- [x] **#1 replacer.nvim** — `apply_matches(items, old, new, wc, cfg, on_done?)`,
      `APPLY_CHUNK_SIZE = 10`. `apply_func` + fzf/telescope/perfile-Call-Sites
      threaden den Callback. `doc/replacer.txt`, `docs/progress-indicator.md`
      aktualisiert. Neuer Test 5b (25 Dateien). **committet + gepusht, CI grün.**
- [x] **#2 filetree.nvim** — `refs/apply.lua` `run` **und** `undo` gechunkt
      (`APPLY_CHUNK_SIZE = 8`), `[filetree.refs]`-Indikator. `refs/ui.lua`
      `do_apply`, `refs/init.lua` Undo-Handler, 3 Trash-Call-Sites threaden den
      Callback. `docs/FEATURES/FILEOPS.md`. Neuer units.lua-Block (20 Dateien
      + Undo). **committet + gepusht, CI grün.**
- [x] **#3 documentation.nvim** — `bindings/usrcmds/annotate.lua` `M.run`:
      Plan- **und** Apply-Phase gechunkt (`CHUNK = 10`), `documentation.bindings
      .progress`-Indikator. Usercmd fire-and-forget → kein Aufrufer geändert.
      `doc/documentation.txt`, `docs/commands.md`. Neuer annotate_spec-Block
      (15 Dateien, Mini-`ctx`). `docs/map` mitregeneriert. **committet + gepusht,
      CI grün** (self-healing map-Job hat mitgezogen).
- [x] **#4 markdown.nvim** — `commands/links.lua` `collect` (jetzt
      callback-basiert) + `do_sanitize` cwd gechunkt (`CHUNK = 20`), neues
      `markdown/util/progress.lua` + Top-Level-Option `progress_style`.
      `do_show` threadet `collect`. **`core/file_refs.lua` war schon ok**:
      `find_references_async` existiert und wird von `link_delete` benutzt; die
      sync `find_references` ist nur öffentliche API. `docs/configuration.md`,
      `docs/commands.md`, `doc/markdown.nvim.txt`, `@types/init.lua`. Neuer
      link_sanitize_spec-Block (30 Dateien). **committet + gepusht, CI grün.**
- [x] **#5 insights.nvim** — **Scan war schon async** (`scan_cwd_async`,
      gechunkt) — meine Ursprungsanalyse war hier falsch. Ergänzt:
      (a) Indikator am `scan_cwd_async` (neue Option `imports.progress_style`),
      (b) `build_unused_report(data, filters, on_done?)` — die Re-Read-Schleife
      der „unused"-Heuristik gechunkt (`CHUNK = 100`). `run_unused` threadet
      den Callback. `docs/configuration.md`, `doc/insights.txt`. Neuer
      import_index_spec-Block (120 Entries). **committet + gepusht**
      (CI-Lauf lief noch beim Stopp — bitte prüfen).

## Noch offen

- [ ] **#6 filetree.nvim `refs/scan.lua:151`** — Sync-Fallback-Leseschleife
      (nur wenn `rg` fehlt), bereits gedeckelt (`"stopped at %d files"`).
      Gleiches Muster: batchen + `[filetree.refs]`-Indikator, oder klarer als
      „rg installieren"-Pfad kommunizieren.
- [ ] **CI-Lauf von #5 (insights.nvim)** verifizieren.

## Verworfen / kein Handlungsbedarf

- `diff.nvim` core/git.lua — git komplett async (Callback), `:wait()`-Zeilen
  sind historische Kommentare.
- `dap.nvim` validation.lua / rust.lua, `pdfport.nvim` ollama.lua,
  `debugging.nvim` tools/startup.lua — die verbliebenen `vim.fn.system` sind
  alle `if not vim.system`-Fallbacks (Neovim < 0.10).
- `sandbox.nvim` `run_blocking_captured` — nur für `compose ps`/`logs`
  (Snapshot, schnell); die langen Ops nutzen `run_async_captured`.
- `insights/conflicts`, `sessions/git`, `hover` — ebenfalls Fallback-only.
- `recommender.nvim` `project.lua`, `buffer-ctx.nvim` `table_fmt.lua` cwd —
  haben ihre cwd-Scope-Progress schon (Juli-Pässe).
- `markdown.nvim` `file_refs` single-file — zu schnell, damals schon abgelehnt.

## Vorgeschichte: die 4 Pässe aus Juli 2026

Siehe Memory `ui-decoupling-progress-bars-2026-07-21`. Damals: alle
Shell-Calls (rg, git, magick, ollama, docker, …) auf `vim.system` +
Callback; `lib.nvim.progress` als fertige Abstraktion in ~10 Plugins
verdrahtet; Statusline-Modul `plugin_progress` rendert alle aktiven Handles.

**KEY MECHANISM (nicht neu herleiten):** `lib.nvim.progress` wrappt seinen
Delay-Guard in `vim.schedule_wrap`, der statusline-Style schedult sein
`:redrawstatus`. Ein Handle um einen blockierenden Call ist nur *sichtbar*,
wenn dieser Call scheduled callbacks drained:

| Wait-Form | sichtbar |
|---|---|
| `vim.fn.system`/`systemlist` | 0 |
| `vim.system(...):wait()` | 0 |
| `vim.system` + `vim.wait` | 62 |

Bei den hier behandelten reinen Lua-Schleifen ist die Lösung `vim.schedule`
zwischen den Chunks — das drained die Callbacks.
