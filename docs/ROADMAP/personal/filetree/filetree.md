# `filetree.nvim`

## Table of content

  - [Bug](#bug)
  - [General](#general)
  - [Filetree Manager spezifische Features](#filetree-manager-spezifische-features)
    - [neotree spezifisch](#neotree-spezifisch)
      - [sources](#sources)
  - [Später](#spter)

---

## Bug

[ ] filetree.nvim handle_guard: seit 2026-07-21 08:36  aktiv (Windows watcher-lock fix).
    Über 1-2 Tage prüfen: tritt der sporadische "kann Ordner/File nach move/rename
    nicht löschen" EPERM-Lock nochmal auf? Falls nein → fix bestätigt. Falls ja →
    handle_guard release greift nicht in dem Fall, Details an Claude.

---

## General

1. Alle keymaps prüfen

---

## Filetree Manager spezifische Features

1. neotree, nvimtre, netrwq, oil, minifiles spezifische features sammeln (features, die diese plugins selbst anbieten)
2. `commands/markdown/links.lua`, `actions/path/to_require/init.lua`, `actions/grep_picker/init.lua` — ✅ **verifiziert, bereits vollständig in filetree.nvim implementiert**: `features/paths/markdown_links`, `features/paths/lua_require_copy`, `features/search/{find_files,grep_in_dir}` (kombiniert im `search`-Menü-Block von `integrations/menu.lua`). Alle drei alten neotree-Configs waren bereits in vorherigen Commits (`71fef4a2`, `ba47a088`, beide schon auf `origin/cdxV2`) entfernt — keine Code-Änderung nötig, keine Doku-Lücke in filetree.nvim (README + vimdoc decken alle drei bereits ab).

---

### neotree spezifisch

| Datei | Was drin | Für filetree.nvim? |
| ----- | -------- | ------------------ |
| `utils/selective_callback_guard.lua` | Monkey-patcht `neo-tree.events._handlers` für Event-Transitionen | **NEIN** — neotree-intern, aber inspiriert `watcher_quarantine` neotree-Adapter-Integration |
| `utils/event_patch.lua` | Patcht `neo-tree.sources.filesystem.lib.fs_watch` für EPERM-Suppression | **NEIN** — komplett neotree-intern |

---

#### sources

| **sources/ + icons/** | Lazy Source Registry, 3 Icon-Familien (nerd/codicons/common), responsive Größe |

`sources`-Feature von neotree nachbilden — 🔲 **Phase 4, niedrige Priorität.** Verifiziert: `lua/config/neotree/sources/registry.lua` ist aktuell ein simpler Lazy-Loader (register/load/is_loaded/list), kein Template-System — der Wunsch existiert im Code noch nicht. Statt eines vollen Template-Engines: erstmal eine kleine Recipe-/Copy-Paste-Config-Sammlung (2-3 gängige Source-Setups) im `filetree.nvim`-README oder `docs/` — deckt den eigentlichen Schmerzpunkt ("Einrichtung war Pain") günstiger ab als ein neues System.

---

## Später

1. `?`-Cheatsheet mit allen Keymaps — ✅ **Phase 2 umgesetzt.**
   - neotree: ✅ FIXED (native `?`/show_help bereits vollständig über `attach.lua`s `window.mappings`-Injection).
   - **Recherche (Quellcode von nvim-tree.lua geklont und gelesen):** `g?`/`toggle_help` baut seine Liste, indem es `on_attach` erneut auf einem **Scratch-Buffer** ausführt und dessen Keymaps ausliest (`nvim-tree/keymap.lua:generate_keymap`) — keine Live-Buffer-Introspektion. filetree.nvim's Keys (separat per `FileType`-Autocmd gebunden) tauchen dort grundsätzlich nie auf, außer man hängt sich in nvim-trees `on_attach`-Callback selbst ein — das wäre ein Umbau der kompletten Keymap-Architektur des nvimtree-Adapters, kein Cheatsheet-Feature mehr. Netrw's `?` ist zudem eine statische Hilfeseite; oil/minifiles nicht verifiziert.

---

