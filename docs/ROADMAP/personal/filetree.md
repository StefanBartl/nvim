# `filetree.nvim`

- neotree, nvimtre, netrwq, oil, minifiles speziscfische features saammeln

## utils/ — Analyse

| Datei | Was drin | Für filetree.nvim? |
|-------|----------|-------------------|
| `utils/platform.lua` | `is_windows()`, `is_wsl()`, `is_macos()`, `has_executable()`, `get_cwd()` — gecacht | **JA** — wir haben Platform-Detection dreifach inline (open_in_fm, preview, shell_run). Gehört nach `filetree/util/platform.lua` |
| `utils/path.lua` | normalize, to_absolute, to_relative, ensure_dir, escape_shell_arg, quote_if_needed | **JA (teils)** — die reinen Pfad-Funktionen. `to_relative` hängt an `config.neotree.actions.project_root` → rauswerfen. Rest → `filetree/util/path.lua` |
| `utils/line_count.lua` | `TEXT_EXTS`/`BINARY_EXTS` Tabellen, `is_countable(ext)`, `count(path)`, `format(n)` — 5 MiB Guard, synchron | **JA** — exakt das was `node_info` und `preview` brauchen. Aktuell fehlt eine saubere `is_binary(path)`-Impl. → `filetree/util/line_count.lua` |
| `utils/buffer.lua` | `is_valid_file_buffer(bufnr)` (gecacht, 1s TTL), `get_buffer_context()`, `find_last_normal_buffer()`, `close_related_buffers()` | **JA** — `find_last_normal_buffer()` ist genau das was `buffer_save` und `open_replace` heute mit eigenem `find_adjacent_win()` lösen. Zentralisieren → `filetree/util/buffer.lua` |
| `utils/tree.lua` | `collect_recursive(path, "files"\|"folders")` — libuv-Stack, ignoriert `.git` etc. | **JA** — `copy_file_list` macht das heute selbst (vermutlich schlechter). → `filetree/util/fs.lua` |
| `utils/node.lua` | `get_path(node)`, `extract_paths(nodes)` — generisch; `collect_nodes(state)`, `get_current(state)` — neotree-intern | **TEILS** — `get_path` / `extract_paths` → neotree-Adapter. Rest skip |
| `utils/init.lua` | `safe_hide_preview()`, `is_neotree_open()` — neotree-spezifisch | **NEIN** — adapter deckt das ab |

---

## window/ — Analyse

folgende features wären denke ich kandidaten für den `/ui` modulfolder

| Datei | Was drin | Für filetree.nvim? |
|-------|----------|-------------------|
| `disable_statusline.lua` | `vim.wo[win].statusline = " "` auf neo-tree-Fenstern | **JA** — kleines Feature `window_style` mit `statusline = false`. Eine Zeile Logic, aber explizit als Feature konfigurierbar |
| `highlight.lua` | `NeoTreeNormal → Normal`, `NeoTreeNormalNC → NormalNC` — HL-Isolation | **VIELLEICHT** — sinnvoll als neotree-Adapter-Option `isolate_highlights = true`. Nicht als eigenes Feature |
| `only_lhs.lua` | Globale Keymaps `<M-c/f/l/r>` → neotree in verschiedenen Positionen (current/float/left/right) + reveal_force_cwd | **JA** — neues Feature `tree_open_keymaps` (oder `global_keymaps`): globale Normal-Mode-Keys für Tree-Toggle in versch. Positionen. Adapter-agnostisch implementierbar |

---

## Schlachtplan

**Gruppe 1 — Util-Infrastruktur (kein neues Feature, pure Verbesserung)**

Diese ersetzen Inline-Code der bereits existierenden Features:
1. `filetree/util/platform.lua` — aus `utils/platform.lua` adaptiert; `open_in_fm`, `shell_run`, `preview` refactoren
2. `filetree/util/path.lua` — reine Pfadfunktionen aus `utils/path.lua`; `project_root`-Abhängigkeit rauswerfen
3. `filetree/util/line_count.lua` — direkt aus `utils/line_count.lua`; `node_info` + `preview` (is_binary) nutzen es
4. `filetree/util/buffer.lua` — aus `utils/buffer.lua`; `buffer_save` + `open_replace` + `layout_guard` refactoren; `find_last_normal_buffer()` ersetzt `find_adjacent_win()`
5. `filetree/util/fs.lua` — `collect_recursive` aus `utils/tree.lua`; `copy_file_list` nutzt es

**Gruppe 2 — Neue Features**
1. `window_style` Feature — `statusline = false`, `highlights_isolate = false`; FileType-Autocmd setzt `vim.wo[win].statusline` + HL-Links
2. `tree_open_keymapss` Feature — globale Normal-Mode-Keys für `toggle position=left/right/float/current` mit `reveal_force_cwd`; adapter-agnostisch via `adapter.open_reveal()` + neotree-Command-Fallback

**Gruppe 3 — Neotree-Adapter-Erweiterungen (intern, kein eigenes Feature)**
1. `node.get_path` + `nod.extract_paths` in den neotree-Adapter bringen → `adapter.get_current_node()` robuster machen
2. `event_patch` Logik → in `watcher_quarantine` als neotree-spezifische EPERM-Unterdrückung integrieren

---

## General

1. `e:\repos\filetreepicker.nvim
2. `e:\repos\neotree-fs-refactor.nvim`
3. Noch ein check: Alles Cross-Plattform? Cross-Filetree-Plugins?
4. Neotree: Keymaps auch als usrcmds implementieren, die in neotree aber auch nvim tree usw funktioenren, zb könte man dann alle folder eines ordnnenr pfad kopieren, und den rekuuriscen kevek angeben
5. [Keymaps](../../NOTES/neotree/Keymaps.md) && [Rest](./../../NOTES/neotree/Auto-Usrcmds-EventHandler.md): Gegenchecken, was noch fehlt
6. Features durchgehen
7. Alles aus der `nvim/config/lua/neotree/**` && `nvim/lua/plugins/neotree.lua` emtfernen, was bereits in `filetree.nvim` implementiert ist und eigentlich schon funkltioeren müsste, wenbn ich ews impleemntiere

---

## Features

## Feature-Inventur

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
| **@types/** | 17 LuaLS-Typ-Dateien, `Cfg.NeoTree.*`-Namespace, vollständige Funktionssignaturen |
| **checkhealth/** | `:checkhealth neotree` mit 4 Submodulen |
| **refresh**  | Small adapter to refresh Neo-tree safely with proper types and quarantine awareness. |
|               | `lua\config\neotree\refresh_adapter\init.lua` |


## window/ — Analyse

| Datei | Was drin | Für filetree.nvim? |
|-------|----------|-------------------|
| `disable_statusline.lua` | `vim.wo[win].statusline = " "` auf neo-tree-Fenstern | **JA** — kleines Feature `window_style` mit `statusline = false`. Eine Zeile Logic, aber explizit als Feature konfigurierbar |
| `highlight.lua` | `NeoTreeNormal → Normal`, `NeoTreeNormalNC → NormalNC` — HL-Isolation | **VIELLEICHT** — sinnvoll als neotree-Adapter-Option `isolate_highlights = true`. Nicht als eigenes Feature |
| `only_lhs.lua` | Globale Keymaps `<M-c/f/l/r>` → neotree in verschiedenen Positionen (current/float/left/right) + reveal_force_cwd | **JA** — neues Feature `tree_open_keymaps` (oder `global_keymaps`): globale Normal-Mode-Keys für Tree-Toggle in versch. Positionen. Adapter-agnostisch implementierbar |

Abner alle im idealfall agnoszisch, also so imeplemntieren, das es bei allen filetree amnaer klappt. wenn möglicvhl ansisnten zu den nur neoiteree spezifischen features


## neotree spezifisch


| Datei | Was drin | Für filetree.nvim? |
| ----- | -------- | ------------------ |
| `utils/selective_callback_guard.lua` | Monkey-patcht `neo-tree.events._handlers` für Event-Transitionen | **NEIN** — neotree-intern, aber inspiriert `watcher_quarantine` neotree-Adapter-Integration |
| `utils/event_patch.lua` | Patcht `neo-tree.sources.filesystem.lib.fs_watch` für EPERM-Suppression | **NEIN** — komplett neotree-intern |

### sources

| **sources/ + icons/** | Lazy Source Registry, 3 Icon-Familien (nerd/codicons/common), responsive Größe |

1. `sources` feature von neotree, kann wr das implementieren? Filetree spezifische features z uunterstützen ist auf dauewr sicherlich ein key zum Erfolg - es mus aber nicht 1:1 jedes feature sein, denn man kann als user ja auch in dedr seiner neotree config features aktiviren neben filetree.nvim... aber trotzdem wenn feaatures gut unterstützt werdden können wäre das super. Da wäre es toll, wenn wir Templates anbieten könnten, also zb: für das source feature in neotree verschiedenne source konfiguartionen,. anrodungen usw... ich weiß noch,. das war ein pain in the *peips* daie sources manuell einzurichten...
2. Explizit userkonfigurationen füür dasd filetree.nvim sammeln: Auf eigener developer seite kawnn ich einen Endppoint/Webppage bauen, bei der man konfigurationen posten und scrreenshots teilen kann. Diese Seite kan ich dann ihn der filetree.nvim README auf GIthub auch hinterlgen

---

## hooks

### state/windows.lua & state/tree.lua

- `state/windows.lua` — Window-State-Registry (open/position/source, Listener-Pattern, Snapshot-Cache). Das deckt `adapter.is_open()` / `adapter.get_winid()` in filetree.nvim bereits ab. Das Listener-Pattern wäre interessant, gehört aber in einen zentralen Event-Bus (filetree hat `hooks_api` dafür geplant).

lua\config\neotree\state\tree.lua

- `state/tree.lua` — Cursor-Position + expanded-Nodes speichern/restoren. Nutzt neotree-interne APIs (`tree.expand_batch`, `tree.set_selection`) — nicht übertragbar. Inspiration für `session`-Feature (adapter-spezifisch implementieren).

lua\config\neotree\state\tree.lua

---
