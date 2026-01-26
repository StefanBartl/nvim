# Meilensteine

## Table of content

- [Meilensteine](#meilensteine)
  - [**Phase 0: Foundation** (Woche 1)](#phase-0-foundation-woche-1)
  - [**Phase 1: Hot Path** (Woche 2)](#phase-1-hot-path-woche-2)
  - [**Phase 2: Frequent Events** (Woche 3–4)](#phase-2-frequent-events-woche-34)
  - [**Phase 3: Write Path** (Woche 5)](#phase-3-write-path-woche-5)
  - [**Phase 4: Lifecycle & Visual** (Woche 6)](#phase-4-lifecycle-visual-woche-6)
  - [**Phase 5: FileType Dispatcher** (Woche 7)](#phase-5-filetype-dispatcher-woche-7)
  - [**Phase 6: Cleanup & Migration** (Woche 8)](#phase-6-cleanup-migration-woche-8)

---

## **Phase 0: Foundation** (Woche 1)
- [ ] Context-Factory-Module (`buffer.lua`, `window.lua`)
- [ ] Cache-Infrastruktur (`cache.lua`)
- [ ] Test-Harness für Event-Simulation
- [ ] Baseline-Performance-Messung (siehe Metrics unten)

## **Phase 1: Hot Path** (Woche 2)
- [ ] `CursorMoved` → `events/hot_path/cursor_moved.lua`
- [ ] `CursorMovedI` → `events/hot_path/cursor_moved_i.lua`
- [ ] Handler:
  - `git/line_diff.lua`
  - `ui/cword_occurrences.lua`
  - `ui/indent_scope.lua`
  - `ui/breadcrumbs.lua`
- [ ] A/B-Test: Alter vs. neuer Code (siehe Benchmarks)

## **Phase 2: Frequent Events** (Woche 3–4)
- [ ] `BufEnter` → `events/frequent/buf_enter.lua`
- [ ] `BufWinEnter` → `events/frequent/buf_win_enter.lua`
- [ ] Handler:
  - `markdown/keymaps.lua`
  - `ui/neotree_sync.lua`
  - `ui/dashboard.lua`
  - `git/conflict_marks.lua`
  - `debugging/views.lua`

## **Phase 3: Write Path** (Woche 5)
- [ ] `BufWritePre` → `events/frequent/buf_write_pre.lua`
- [ ] Prioritäts-Pipeline:
  1. Auto-mkdir
  2. Trim whitespace
  3. LSP/Conform format
  4. ESLint fix
  5. Prettier format
- [ ] Conflict-Resolution-Strategie (User-Config)

## **Phase 4: Lifecycle & Visual** (Woche 6)
- [ ] `VimEnter`, `VimLeavePre` → `events/lifecycle/`
- [ ] `ColorScheme` → `events/visual/colorscheme.lua`
- [ ] Handler:
  - `ui/kitty_spacing.lua`
  - `sessions/autoload.lua`
  - Cache-Invalidierung für alle HL-Module

## **Phase 5: FileType Dispatcher** (Woche 7)
- [ ] `FileType` → `events/utils/filetype.lua`
- [ ] Filetype-to-Handler-Mapping:
  ```lua
  {
    markdown = { "markdown/keymaps", "markdown/usercmds" },
    gitcommit = { "git/commit_ft" },
    noice = { "mappings/noice" },
  }
  ```

## **Phase 6: Cleanup & Migration** (Woche 8)
- [ ] Alte Autocmd-Dateien entfernen
- [ ] `autocmds/init.lua` finalisieren
- [ ] Dokumentation (`docs/ARCHITECTURE.md`)
- [ ] Performance-Report (siehe Metrics)

---


