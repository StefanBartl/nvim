# `filetree.nvim`

## Table of content

  - [Features](#features)
  - [Bug](#bug)
  - [Filetree Manager spezifische Features](#filetree-manager-spezifische-features)
    - [neotree spezifisch](#neotree-spezifisch)
      - [sources](#sources)

---

## Features

- [ ] Neue Keymap `C-M-w` - da,it springe ich in da sfiletre window mit dfme cursror und zwar genau zu filenode des buiffers (reveal)

---

## Bug

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


---

## Offen: `<leader>fm` — Fenster oeffnet ohne Fokus (Windows)

Stand 2026-08-07. `open_in_fm` delegiert seit heute an
`lib.nvim.cross.reveal_in_fm`, teilt sich den Bug also mit open.nvims
`:Open filemanager`. Vollstaendige Analyse dort:
[open.nvim.md](../open.nvim.md). Kurzfassung: das Explorer-Fenster entsteht,
kommt aber nicht in den Vordergrund — Fokus-Problem, kein Start-Problem.

Zusaetzlich hier offen:

- [ ] `reuse_existing` (Explorer-Fenster-Wiederverwendung via COM) ist laut
      eigenem Modulkommentar nie gegen eine echte Explorer-Instanz getestet
      worden. Wenn der Fokus-Fix ueber `SetForegroundWindow` laeuft, faellt
      dieser Test ohnehin an — dann gleich mit erledigen.
- [ ] Neu: `reveal = true` ist ab jetzt Default, ein Datei-Knoten wird also im
      Explorer selektiert statt nur den Ordner zu oeffnen. Im Alltag
      gegenpruefen, ob das fuer `<leader>fm` wirklich das gewuenschte
      Verhalten ist, oder ob der Ordner ohne Selektion angenehmer war.
