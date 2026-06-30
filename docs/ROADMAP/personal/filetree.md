# `filetree.nvim`

1. `e:\repos\filetreepicker.nvim
2. neotree-fs-refactor.nvim

---

## Feature-Inventur

Du hast über **12 eigenständige Domänen** implementiert. Hier komprimiert:

| Domäne | Was es macht |
|---|---|
| **safety/** | Backup vor Delete/Move, Recovery-Points, Operation Queue, Dry-Run, Validation |
| **trash/ + undo/** | Platform-spezifischer Trash (Windows Recycle Bin, Linux gio, macOS), Undo mit History (50 Items), Open-Buffer-Detection |
| **watcher_quarantine/** | EPERM-Fehler-Fix auf Windows — stoppt libuv-Watchers vor Delete, per-path Granularität |
| **cwd_sync/** | Auto-reveal current file, Debouncing, User-Navigation-Pause, Window-Stability-Wait, Race-Condition-Protection |
| **current_hl/** | Aktuelle Datei + Parent-Dir farbig highlighten (hex/link/named), ColorScheme-persist |
| **layout_guard/** | Verhindert, dass Neotree als einziges Fenster übrigbleibt |
| **keymaps/** | 6 Sources × eigene Keymaps, 25+ Filesystem-Keys, 3-state Resize, Multi-action ESC |
| **commands/** | Clipboard cut/copy/paste (recursive + marks), Diff, Markdown-Links (single/dir/recursive/marked) |
| **actions/** | System-App-Opener (PDF/Images/Office), Path-to-require, Telescope/fzf-Integration, Tree-Traversal |
| **sources/ + icons/** | Lazy Source Registry, 3 Icon-Familien (nerd/codicons/common), responsive Größe |
| **@types/** | 17 LuaLS-Typ-Dateien, `Cfg.NeoTree.*`-Namespace, vollständige Funktionssignaturen |
| **checkhealth/** | `:checkhealth neotree` mit 4 Submodulen |

---

## Deine zwei Ideen

### Option B — `filetree.nvim` / `filetree-features.nvim` (agnostisch)

Das ist die richtige Idee, aber die Scope-Frage muss klar sein:

**Die 3 großen Filetree-Explorer** sind tatsächlich Neotree, nvim-tree, und Netrw — wobei [oil.nvim](https://github.com/stevearc/oil.nvim) inzwischen auch sehr verbreitet ist (buffer-as-filesystem Paradigma). Für ein Adapter-Pattern wären die 4 realistischen Targets: `neo-tree`, `nvim-tree`, `oil.nvim`, `netrw`.

Das Problem: die APIs sind fundamental verschieden.
- **nvim-tree** hat `api.tree.get_node_under_cursor()`, `api.fs.rename()` etc.
- **neo-tree** hat `state.tree`, `commands.*`, eigenes Event-System
- **oil.nvim** ist buffer-based — kein "Node"-Konzept
- **netrw** hat kaum public API

Ein sauberes Plugin würde **Port/Adapter-Interfaces** brauchen:

```lua
-- Konzept: filetree-features.nvim
require("filetree-features").setup({
  adapter = "neo-tree",   -- oder "nvim-tree", "oil"
  features = { "safety", "layout_guard", "cwd_sync", "current_hl" },
})
```

**Konkret portierbar aus deinem Code (JETZT, ohne viel Umbau):**
- `safety/` — keine Tree-API, reine Filesystem-Ops
- `watcher_quarantine/` — generisches libuv-Pattern
- `layout_guard/` — nur Window-Management
- `undo/` (Trash Restore Engine) — Platform-Logic ist isoliert
- `utils/path.lua` + `utils/platform.lua` — vollständig generisch

**Braucht Adapter-Interface:**
- `cwd_sync/` — Core-Logik generisch, aber Tree-Reveal muss abstrahiert werden
- `current_hl/` — Renderer-Integration Tree-spezifisch

---

