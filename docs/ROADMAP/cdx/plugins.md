# Plugin

## Table of content

  - [Top-Einzelkandidaten (groß, in sich geschlossen, klarer Trigger)](#top-einzelkandidaten-gro-in-sich-geschlossen-klarer-trigger)
  - [Thematische Bündel (mehrere Module → ein Plugin)](#thematische-bndel-mehrere-module-ein-plugin)
  - [Klein / optional (lazy als `cmd`, Auslagern lohnt nur gebündelt)](#klein-optional-lazy-als-cmd-auslagern-lohnt-nur-gebndelt)
  - [Bewusst **nicht** auslagern](#bewusst-nicht-auslagern)

---

## Top-Einzelkandidaten (groß, in sich geschlossen, klarer Trigger)

| Plugin | Quelle | LOC | Lazy-Trigger | Warum |
|---|---|---|---|---|
| **markdown.nvim** | `custom/markdown` (+ `mynotes`, + `line_marker`) | ~6.100 | `ft = "markdown"` | Größtes Subsystem, eigene `doc/`, rein ft-gebunden. Idealfall. |
| **pdfport.nvim** | `custom/pdfport` | 4.273 | `cmd = PdfPort*` | Schwergewichtig (Backends claude/ollama/pdfplumber), selten gebraucht, lädt aktuell eager. |
| **uv-doc.nvim** | `usrcmds/uv_doc` | 1.144 | `cmd = UVDoc*` | Netz-gebundener Doc-Fetcher, abgeschlossen. |
| **recommender.nvim** | `custom/recommender` | 1.142 | `keys`/`cmd = Recommender` | Eigenständiges Feature. |
| **migrate.nvim** | `usrcmds/migrate` | 2.212 | `cmd = Migrate*` | Einmal-/Wartungs-Tool — gehört evtl. gar nicht in die Laufzeit-Config (oder ganz raus). |

## Thematische Bündel (mehrere Module → ein Plugin)

| Plugin | Quelle | LOC | Trigger | Hinweis |
|---|---|---|---|---|
| **insert.nvim** (ggf. + `copy`) | `custom/insert` (+ `usrcmds/copy`) | ~2.850 | `cmd = Insert`/`Copy` + keys | Pfad/Modul/Timestamp/UUID/Boilerplate als Text. Teilen schon `get_module_path`. |
| **format-cmd.nvim** | `custom/format` | 2.886 | `cmd = Format` | Grenzfall — prüfen, wie stark mit LSP/conform verzahnt. |
| **buffer-nav.nvim** | `filecycle` + `tabufline` | ~685 | `keys` | Klein, aber rein keymap-getriggert. |

## Klein / optional (lazy als `cmd`, Auslagern lohnt nur gebündelt)
`diff` (706), `emojis` (520), `compress_dir` (180), `update_repos` (165), `newfile` (129), `reload` (135), `commands_keymaps` (99) → entweder ein gemeinsames **„utils.nvim"** oder einfach lokal auf `cmd=`-Lazy umstellen.

## Bewusst **nicht** auslagern
- `wkdoptions`, `wkdnvchad`, `wkddap` → NvChad-Anpassungen / DAP, eng mit dem Setup verwoben.
- `lsp`, `mappings`, `autocmds`, `sessions`, `options`, `system` → Kern-Config.

---
