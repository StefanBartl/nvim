# Handover — Autocmds auf `lib.nvim.bindings.autocmd` umstellen

Stand: 2026-08-27. Alle unten genannten Repos sind **committet und auf `main`
gepusht**, kein Arbeitsstand hängt irgendwo.

---

## Was die Aufgabe ist

`lib.nvim.bindings.autocmd` führt ein **Register** jedes Autocmds, der durch
das Modul erzeugt wurde (Event, Gruppe, Pattern, `desc`, Datei:Zeile). Darauf
setzt `lib.nvim.bindings.autocmd.docs` auf und generiert daraus
`lua/<plugin>/bindings/autocmd/*.md`, eine Datei je Event-Familie.

Autocmds, die direkt über `vim.api.nvim_create_autocmd` erzeugt werden,
hinterlassen **keinen Record**. Sie feuern, stehen aber in keiner generierten
Tabelle. Eine Doku, die das verschweigt, ist nicht unvollständig sondern
falsch — der Leser hält die Tabelle für die ganze Liste.

**Die Arbeit:** diese Aufrufstellen auf `lib.nvim.bindings.autocmd` umstellen,
**Repo für Repo, jedes einzeln committen und auf `main` pushen.**

---

## Wie migriert wird

Vorher:

```lua
local grp = vim.api.nvim_create_augroup("myplugin_x", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  group = grp,
  pattern = "*.md",
  desc = "…",
  callback = on_enter,
})
```

Nachher:

```lua
local autocmd = require("lib.nvim.bindings.autocmd")
local grp = autocmd.group("myplugin_x", true)   -- true = clear
autocmd.create("BufEnter", on_enter, {
  group = grp,
  pattern = "*.md",
  desc = "…",
})
```

Der Callback ist **positional**, nicht `opts.callback`.

### Vier Fallen, jede davon schon einmal zugeschlagen

1. **`desc` fehlt oft.** Gleich mitschreiben — es ist die Spalte „What" in der
   generierten Tabelle, sonst steht dort `_(no desc)_`.

2. **Gruppe auch über lib leeren, nicht nur erzeugen.**
   `autocmd.group(name, true)` verwirft die alten *Records* zusammen mit den
   alten Autocmds. Wer weiter `vim.api.nvim_create_augroup(..., {clear=true})`
   benutzt, lässt veraltete Zeilen in der Doku stehen. Wichtig überall dort, wo
   im Doc-Kommentar „idempotent" oder „safe to call multiple times" steht —
   dann bitte auch einen Test dagegen (siehe `cmdlog.nvim`).

3. **`command = "…"` gibt es nicht.** lib's `create()` nimmt nur einen
   Callback. Ein String-Command muss in eine Funktion.

4. **Der Rückgabewert des Callbacks wird verworfen.** Nativ löscht ein
   Callback, der `true` zurückgibt, seinen eigenen Autocmd. Das geht durch
   lib's `pcall`-Wrapper verloren. Vor der Umstellung prüfen, ob der Callback
   etwas zurückgibt.

### Soft-Dependency-Fallbacks nicht umstellen

Manche Plugins haben einen Wrapper, der lib bevorzugt und nur bei fehlendem lib
nativ registriert. Diese native Stelle ist **richtig**. Sie bekommt stattdessen
den Marker, dann zählt lib sie nicht mehr:

```lua
-- lib-docs: fallback
vim.api.nvim_create_autocmd(event, opts)
```

---

## Erledigt

| Repo | was |
| --- | --- |
| `lib.nvim` | `docs.write()` ohne Argumente, `docs.write_all()`, `create_usercmd()`, Zähler für nicht-registrierte Stellen, Dispatcher-Benchmark in der README |
| nvim-config | `:LibAutocmdDocs`, `:LibAutocmdDocsCheck`, `:LibAutocmdDocsAll [dir] [--dry-run]` in `lua/bindings/usrcmds/autocmd_docs/` |
| `sessions.nvim` | Fallback markiert |
| `spotlight.nvim` | Fallback markiert |
| `cmdlog.nvim` | `CmdlineLeave` migriert, `desc` ergänzt, Test gegen doppeltes `setup()` |
| `open.nvim` | `BufReadCmd` migriert, Gruppe über lib geleert |

---

## Offen — 39 Stellen in 11 Repos

Ermittelt mit einem string- und kommentar-bewussten Scanner (siehe unten,
warum das nötig ist). Von klein nach groß:

| Repo | n | Dateien |
| --- | ---: | --- |
| `documentation.nvim` | 1 | `core/bindings.lua` |
| `runtime-analysis.nvim` | 1 | `startup/init.lua:152` — **aliasiert**: `local au = vim.api.nvim_create_autocmd`, danach `au(...)` mehrfach |
| `fileops.nvim` | 2 | `features/on_hold.lua:389,421` |
| `filetree.nvim` | 2 | `util/autocmd.lua:50,68` — eigener Wrapper, deckt viele Autocmds ab |
| `sandbox.nvim` | 2 | `ui/list_actions.lua:425`, `ui/log_follow_view.lua:42` |
| `color_my_ascii.nvim` | 3 | `commands/fence/open.lua:105,113`, `commands/schemes.lua:175` |
| `language.nvim` | 4 | `bindings/autocmds/init.lua:93`, `spell/providers/cspell_server.lua:232`, `translate/window.lua:259,265` |
| `pickers.nvim` | 4 | `bindings/autocmds.lua:34`, `engines/when_loaded.lua:53`, `smart/frecency.lua:162,163` |
| `markdown.nvim` | 10 | `core/table_mode.lua:108,114`, `hover/float.lua:148`, `hover/init.lua:351,362,369`, `hover/preview/media.lua:305`, `scope/init.lua:191`, `tableview/renderer.lua:457`, `util/image_preview.lua:92` |
| `mdview.nvim` | 13 | `adapter/preview_tab.lua:197`, `bindings/autocmds/{breadcrumbs:40, bufenter:59, buffer_switch:141, bufwrite:35, live_push:166+186, on_text_change:35, preview_tab_sync:34+46, scroll_sync:134, vim_leave:11+36}` |

`filetree.nvim` und `runtime-analysis.nvim` haben eigene Wrapper bzw. Aliase —
dort reicht **eine** Änderung für viele Autocmds.

### Zwei Repos, die auf der alten Liste standen und dort nicht hingehören

- **`debugging.nvim`** — nannte `nvim_create_autocmd` dreizehnmal und erzeugt
  **keinen einzigen**. Es ist ein Modul, das nach Autocmds *sucht*; alle
  Vorkommen sind String-Literale.
- **`buffer-ctx.nvim`** — die eine Stelle steht in einem Boilerplate-*Template*,
  also in generiertem Text.

Die ursprüngliche Zahl **74 war ein naiver Substring-Count** und hat genau
diese zwei saubersten Repos als die zwei schlimmsten ausgewiesen. Echt sind
**45**, davon 2 legitime Fallbacks (erledigt) und 4 bereits migriert → **39
offen**. Der Zähler in lib ist inzwischen string-, kommentar- und
fallback-bewusst; er verlangt bewusst **keine** Aufruf-Klammer, sonst fällt
der Alias in `runtime-analysis.nvim` durch.

---

## Danach

- **`filetree.nvim` auf den Dispatcher** (`BufEnter`, 10 Handler) plus die
  dort fehlenden `desc`. Die Messung spricht dafür — siehe
  `personal/All/FINISH/Merged_Finished.md`, Abschnitt vom 2026-08-27.
- **Dedup nach lib**, Liste steht in `personal/All/FINISH/MERGED.md`:
  Markdown-Tabellen-Renderer (buffer-ctx ↔ markdown) zuerst, **lib-Doku nicht
  vergessen**; dann `deep_merge`/`config.get` (cascade ↔ spotlight); dann
  Kleinkram. `config.M.get` und `try_require` bewusst **nicht** — Begründung
  steht dort.
- Später: Telemetrie-Daten → `TO_CHECK_FEATURES`.

---

## Arbeitsregeln aus diesem Chat

- Commit/Push/Pull **immer auf `main`**, pro Repo einzeln.
- Commit-Messages **ohne** `Co-Authored-By: Claude`.
- Code, Kommentare und Doku in den Repos **englisch**; Konversation deutsch.
- Vor jedem Commit: `stylua lua && luacheck lua`, dann der Test-Runner des
  Repos — der heißt **nicht überall gleich** (`TESTS/run.lua`,
  `TESTS/smoke_spec.lua`, `TESTS/pickers_spec.lua`, plenary-Ordner). Wenn
  „cannot open" kommt, ist das **kein bestandener Test**.
  `docs/ROADMAP/tools/run_all_tests.sh` findet den jeweiligen Runner.
- **Kein bare `git stash`** — der Stash-Stack ist über Worktrees geteilt.
