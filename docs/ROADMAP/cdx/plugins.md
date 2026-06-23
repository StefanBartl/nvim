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
| **migrate.nvim** | `usrcmds/migrate` | 2.212 | `cmd = Migrate*` | Einmal-/Wartungs-Tool — gehört evtl. gar nicht in die Laufzeit-Config (oder ganz raus). |

## Thematische Bündel (mehrere Module → ein Plugin)

| Plugin | Quelle | LOC | Trigger | Hinweis |
|---|---|---|---|---|
| **format-cmd.nvim** | `custom/format` | 2.886 | `cmd = Format` | Grenzfall — prüfen, wie stark mit LSP/conform verzahnt. |

| **buffer-nav.nvim** | `filecycle` + `tabufline` | ~685 | `keys` | Klein, aber rein keymap-getriggert. |
lua\custom\commands_keymaps\delete_current_file\init.lua


/usrcmds/newfile bereits alle features in `fileops.nvim` enthalten?

linemarker gehört in die ui

## Klein / optional (lazy als `cmd`, Auslagern lohnt nur gebündelt)
`compress_dir` (180), `update_repos` (165), `newfile` (129), `reload` (135), → entweder ein gemeinsames **„utils.nvim"** oder einfach lokal auf `cmd=`-Lazy umstellen.

## Bewusst **nicht** auslagern
- `wkdoptions`, `wkdnvchad`, `wkddap` → NvChad-Anpassungen / DAP, eng mit dem Setup verwoben.
- `lsp`, `mappings`, `autocmds`, `sessions`, `options`, `system` → Kern-Config.

---
