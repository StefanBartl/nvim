# Plugisn
Zuerst speichere ich mir die Sprachpräferenz dauerhaft.

The memory directory doesn't exist yet — I'll create it directly via the Write tool.

Gespeichert — ab jetzt antworte ich dir auf Deutsch.

Jetzt zur Analyse. Ich schaue mir die übrigen Top-Level-Verzeichnisse an (nicht nur `custom`/`usrcmds`), um Auslagerungs-Kandidaten über die ganze Config zu finden.

Jetzt prüfe ich, **wie** diese Module geladen werden (eager vs. lazy) — das ist für die Startup-Zeit entscheidend.

Ich habe genug Daten. Ein zentraler Befund noch — ich messe kurz die echte Startup-Last:

Ich habe die ganze Config kartiert (Größe, Lade-Mechanismus, Abhängigkeiten). Hier das Ergebnis.

## Table of content

- [Plugisn](#plugisn)
  - [Kernbefund zuerst (wichtig für die Erwartung)](#kernbefund-zuerst-wichtig-fr-die-erwartung)
  - [Top-Einzelkandidaten (groß, in sich geschlossen, klarer Trigger)](#top-einzelkandidaten-gro-in-sich-geschlossen-klarer-trigger)
  - [Thematische Bündel (mehrere Module → ein Plugin)](#thematische-bndel-mehrere-module-ein-plugin)
  - [Klein / optional (lazy als `cmd`, Auslagern lohnt nur gebündelt)](#klein-optional-lazy-als-cmd-auslagern-lohnt-nur-gebndelt)
  - [Bewusst **nicht** auslagern](#bewusst-nicht-auslagern)
  - [Empfohlene Reihenfolge](#empfohlene-reihenfolge)

---

## Kernbefund zuerst (wichtig für die Erwartung)

Deine `custom/init.lua` und `usrcmds/init.lua` laden **alle** Module **eager** — per `require().setup()`. Sie hängen nur an `vim.defer_fn` (Phase 1 = 10 ms, Phase 2 = 50 ms). Das heißt:

- Die **gemessene `--startuptime`** wird durch Auslagern kaum sinken — die Module laufen ohnehin *nach* VimEnter (die teuersten Posten sind externe Plugins: `cmp`, `telescope`, `neo-tree`, `luasnip`).
- Der echte Gewinn ist **Responsiveness** (markdown/pdfport/function_index/… werden nicht mehr in den ersten ~100 ms+ geladen, sondern erst bei Bedarf) und **eine kleinere Config**.

Der eigentliche Hebel ist also **Lazy-Loading via `ft=` / `cmd=` / `keys=`**. Das Auslagern als Plugin ist primär der saubere *Weg dorthin* (lazy.nvim übernimmt Trigger, Versionierung, `:help`-Docs).

⚠️ **Größter praktischer Aufwand:** Fast jedes Modul hängt an deiner internen `lua/lib/*` (`lib.notify`, `lib.map`, `lib.lua_ls`, …, 13 k LOC). Echte, getrennte Repos brauchen `lib` als **eigenes Basis-Plugin (Dependency)** oder müssen ihre lib-Nutzung vendor'n. Das solltest du zuerst entscheiden.

---

## Top-Einzelkandidaten (groß, in sich geschlossen, klarer Trigger)

| Plugin | Quelle | LOC | Lazy-Trigger | Warum |
|---|---|---|---|---|
| **markdown-suite.nvim** | `custom/markdown` (+ `mynotes`, + `line_marker`) | ~6.100 | `ft = "markdown"` | Größtes Subsystem, eigene `doc/`, rein ft-gebunden. Idealfall. |
| **pdfport.nvim** | `custom/pdfport` | 4.273 | `cmd = PdfPort*` | Schwergewichtig (Backends claude/ollama/pdfplumber), selten gebraucht, lädt aktuell eager. |
| **uv-doc.nvim** | `usrcmds/uv_doc` | 1.144 | `cmd = UVDoc*` | Netz-gebundener Doc-Fetcher, abgeschlossen. |
| **recommender.nvim** | `custom/recommender` | 1.142 | `keys`/`cmd = Recommender` | Eigenständiges Feature. |
| **migrate.nvim** | `usrcmds/migrate` | 2.212 | `cmd = Migrate*` | Einmal-/Wartungs-Tool — gehört evtl. gar nicht in die Laufzeit-Config (oder ganz raus). |

## Thematische Bündel (mehrere Module → ein Plugin)

| Plugin | Quelle | LOC | Trigger | Hinweis |
|---|---|---|---|---|
| **project-insight.nvim** | `function_index` + `lua_project_file_stats` + `project_tree` + `gather` + `fileinfo` | ~6.200 | `cmd` | Alle scannen Projekt/ripgrep und zeigen Aggregate → gemeinsame Scan-Infra. |
| **find-pickers.nvim** | `find_config` + `find_in_folder` + `dir_picker` + `repo_pickers` + `grep` + `search_all_drives` + `system_find` | ~3.450 | `cmd`/`keys` | **Erst konsolidieren** (Tier-1 aus der letzten Analyse: ein fzf/telescope-Engine-Layer), dann auslagern. |
| **pathtools.nvim** | `pathfinder` + `pathprobe` | ~1.300 | `keys`/`cmd` | Gehören ohnehin zusammen (gemeinsames Extract→Resolve→Open). |
| **insert.nvim** (ggf. + `copy`) | `custom/insert` (+ `usrcmds/copy`) | ~2.850 | `cmd = Insert`/`Copy` + keys | Pfad/Modul/Timestamp/UUID/Boilerplate als Text. Teilen schon `get_module_path`. |
| **format-cmd.nvim** | `custom/format` | 2.886 | `cmd = Format` | Grenzfall — prüfen, wie stark mit LSP/conform verzahnt. |
| **buffer-nav.nvim** | `filecycle` + `tabufline` | ~685 | `keys` | Klein, aber rein keymap-getriggert. |

## Klein / optional (lazy als `cmd`, Auslagern lohnt nur gebündelt)
`diff` (706), `emojis` (520), `compress_dir` (180), `update_repos` (165), `newfile` (129), `reload` (135), `commands_keymaps` (99) → entweder ein gemeinsames **„utils.nvim"** oder einfach lokal auf `cmd=`-Lazy umstellen.

## Bewusst **nicht** auslagern
- `lib/` → gemeinsame Basis; bleibt (oder wird *das* Dependency-Plugin).
- `config/*` → das sind Plugin-*Configs*, kein eigenständiger Code. **Ausnahme:** `config/neotree` (**13.833 LOC!**) ist faktisch ein eigener neo-tree-Fork/Extension — der größte Brocken überhaupt, aber stark mit dem neo-tree-Setup verzahnt → eigenes, aber aufwändigeres Thema.
- `wkdoptions`, `wkdnvchad`, `wkddap` → NvChad-Anpassungen / DAP, eng mit dem Setup verwoben.
- `lsp`, `mappings`, `autocmds`, `sessions`, `options`, `system` → Kern-Config.

---

## Empfohlene Reihenfolge
1. **Sofort & ohne Repos:** in `custom/init.lua`/`usrcmds/init.lua` die schweren, selten genutzten Module (`pdfport`, `uv_doc`, `migrate`, `format`, `function_index`) von eager auf **lokale lazy-Specs** (`dir=…` + `ft`/`cmd`/`keys`) umstellen. Bringt Responsiveness sofort, kein Code-Split nötig.
2. **`lib` als Dependency** klären (eigenes Basis-Plugin vs. vendor'n).
3. Dann die **Top-Einzelkandidaten** (markdown, pdfport, uv_doc) in echte Repos lösen.
4. Zuletzt die **Bündel** (find-pickers, project-insight) — nach der Konsolidierung.

Womit sollen wir weitermachen — Schritt 1 (Lazy-Umbau in der bestehenden Config) konkret ausarbeiten, oder einen der Top-Kandidaten (z. B. `markdown-suite`) als echtes Plugin herauslösen?
