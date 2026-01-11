# Refactoring-Plan für ui/ und nvchad/-Modul-Integration

Man beginnt mit Phase 1, da `lsp_based/init.lua` die größte Datei ist und die Modularisierung dort den größten Effekt hat. Nach jedem Commit führt man `:checkhealth` und `:Lazy sync` aus, um sicherzustellen, dass keine Abhängigkeiten fehlen.

## Table of content

- [Refactoring-Plan für ui/ und nvchad/-Modul-Integration](#refactoring-plan-fr-ui-und-nvchad-modul-integration)
  - [Ausgangslage](#ausgangslage)
  - [Zielarchitektur](#zielarchitektur)
  - [Detaillierter Migrationsplan](#detaillierter-migrationsplan)
    - [Phase 1: Kern-Modularisierung (ui/stl_modules/lsp_based)](#phase-1-kern-modularisierung-uistl_moduleslsp_based)
    - [Phase 2: chadrc.lua → nvchad/config/chadrc.lua](#phase-2-chadrclua-nvchadconfigchadrclua)
    - [Phase 3: Menu-Modul-Migration](#phase-3-menu-modul-migration)
    - [Phase 4: Tabufline + Mappings](#phase-4-tabufline-mappings)
    - [Phase 5: Type-System-Konsolidierung](#phase-5-type-system-konsolidierung)
    - [Phase 6: Finaler Clean-up](#phase-6-finaler-clean-up)
  - [Checkliste pro Phase](#checkliste-pro-phase)
    - [Phase 1 (lsp_based Modularisierung)](#phase-1-lsp_based-modularisierung)
    - [Phase 2 (chadrc.lua Wrapper)](#phase-2-chadrclua-wrapper)
    - [Phase 3 (Menu-Migration)](#phase-3-menu-migration)
    - [Phase 4 (Tabufline + Mappings)](#phase-4-tabufline-mappings-1)
    - [Phase 5 (Type-Konsolidierung)](#phase-5-type-konsolidierung)
    - [Phase 6 (Clean-up)](#phase-6-clean-up)
  - [Vorteile der neuen Struktur](#vorteile-der-neuen-struktur)
  - [Risiken und Mitigationen](#risiken-und-mitigationen)
  - [Migrations-Reihenfolge (Empfehlung)](#migrations-reihenfolge-empfehlung)
  - [Nächste Schritte](#nchste-schritte)

---

## Ausgangslage

Die aktuelle Struktur zeigt mehrere Problembereiche:

* `ui/` enthält sehr lange Dateien (z. B. `stl_modules/lsp_based/init.lua` mit ~850 Zeilen)
* `chadrc.lua` ist direkt mit UI-Modulen verdrahtet, aber die Beziehung ist nicht explizit strukturiert
* NvChad-spezifische Module sind über mehrere Ordner verstreut (`config/menu`, `custom/tabufline`, `mappings/nvchad`, `ui/`)
* Bei Entfernung von NvChad müsste man manuell mehrere Ordner durchsuchen und entfernen

---

## Zielarchitektur

Man erstellt einen zentralen `nvchad/`-Ordner, der alle NvChad-abhängigen Module kapselt:

```
lua/
├── nvchad/
│   ├── @types/
│   │   └── init.lua              -- zentrale Typdeklarationen
│   ├── config/
│   │   ├── base.lua              -- Basiswerte, die chadrc.lua überschreiben kann
│   │   └── chadrc.lua            -- öffentliche API + Setup-Logik
│   ├── menu/
│   │   ├── @types/
│   │   ├── core/                 -- custom_menu.lua, mappings.lua
│   │   └── neotree/              -- entries.lua, init.lua
│   ├── tabufline/
│   │   └── init.lua              -- buffer navigation ohne centering
│   ├── mappings/
│   │   └── init.lua              -- nvchad-spezifische Keymaps
│   └── ui/
│       ├── @types/
│       ├── stl_modules/
│       │   ├── lsp_based/
│       │   │   ├── @types/
│       │   │   ├── init.lua      -- Haupt-Renderer (modularisiert)
│       │   │   ├── paths.lua
│       │   │   ├── symbols.lua   -- LSP + Treesitter Context (neu extrahiert)
│       │   │   └── formatters.lua -- Pfad-Komprimierung, Ellipsize (neu extrahiert)
│       │   └── custom_stl_module.lua
│       ├── CursorCtl/
│       │   ├── @types.lua
│       │   ├── init.lua
│       │   ├── progress_calculators.lua
│       │   └── renderer.lua
│       └── base_config.lua
└── chadrc.lua → Symlink oder require("nvchad.config.chadrc")
```

---

## Detaillierter Migrationsplan

---

### Phase 1: Kern-Modularisierung (ui/stl_modules/lsp_based)

**Ziel:** Die ~850-Zeilen-Datei `lsp_based/init.lua` aufteilen in:

1. **symbols.lua** – Treesitter- und LSP-Context-Logik
2. **formatters.lua** – Pfad-Komprimierung, Ellipsize, Breadcrumb-Assembly
3. **init.lua** – Hauptrenderer, Public API

**Schritte:**

```lua
-- nvchad/ui/stl_modules/lsp_based/symbols.lua
---@module 'nvchad.ui.stl_modules.lsp_based.symbols'
local M = {}

-- Alle Treesitter-Funktionen hierher verschieben:
-- - symbol_context_ts()
-- - ts_identifier_of()
-- LSP-Funktionen:
-- - symbol_context_lsp()
-- - request_doc_symbols_async()
-- - get_cached_doc_symbols()
-- Smart-Wrapper:
-- - symbol_context_smart()

return M
```

```lua
-- nvchad/ui/stl_modules/lsp_based/formatters.lua
---@module 'nvchad.ui.stl_modules.lsp_based.formatters'
local M = {}

-- Pfad-Hilfsfunktionen verschieben:
-- - ellipsize_middle()
-- - ellipsize_path_components()
-- - compact_breadcrumb_line()
-- - stl_escape()
-- Icon-Helfer:
-- - file_icon_segment()
-- - file_icon_segment_inherit()
-- - devicon_for_path()

return M
```

```lua
-- nvchad/ui/stl_modules/lsp_based/init.lua (reduziert)
---@module 'nvchad.ui.stl_modules.lsp_based'
local Symbols = require("nvchad.ui.stl_modules.lsp_based.symbols")
local Formatters = require("nvchad.ui.stl_modules.lsp_based.formatters")
local Paths = require("nvchad.ui.stl_modules.lsp_based.paths")

local M = {}
M.cfg = { ... } -- Config bleibt hier

-- Public API (delegiert an Submodule):
function M.symbol_context_smart()
  return Symbols.symbol_context_smart()
end

function M.render_breadcrumbs_lspfirst()
  local ctx = Symbols.symbol_context_smart()
  local rel = Paths.display_path(...)
  return Formatters.compact_breadcrumb_line(rel, ctx, sep, maxw)
end

return M
```

**Prüfung nach Phase 1:**

* `lsp_based/init.lua` < 200 Zeilen
* Alle Funktionen haben `@nodiscard`, `@param`, `@return`
* Keine direkten vim.api-Aufrufe ohne Guards in symbols.lua

---

### Phase 2: chadrc.lua → nvchad/config/chadrc.lua

**Ziel:** `chadrc.lua` wird zum Thin-Wrapper, der nur Setup-Logik aus `nvchad/config/chadrc.lua` aufruft.

**Schritte:**

```lua
-- nvchad/config/base.lua
---@module 'nvchad.config.base'
---@class NvChad.Config.Base
local M = {}

M.defaults = {
  ui = {
    statusline = {
      theme = "vscode_colored",
      order = { "mode", "git", "%=", "breadcrumbs", "%=", "diagnostics", "lsp", "cursor", "progress", "cwd" },
    },
    tabufline = {
      bufwidth = 21,
      bufwidth_cur = 27,
    },
  },
  base46 = {
    transparency = true,
    theme_toggle = { "rosepine", "rosepine" },
    theme = "rosepine",
  },
}

return M
```

```lua
-- nvchad/config/chadrc.lua
---@module 'nvchad.config.chadrc'
local Base = require("nvchad.config.base")
local CursorCtl = require("nvchad.ui.CursorCtl")

local M = {}

---@param user_config? table
---@return table
function M.setup(user_config)
  user_config = user_config or {}

  -- Deep merge user_config über Base.defaults
  local config = vim.tbl_deep_extend("force", Base.defaults, user_config)

  -- Modul-Registrierung (statusline overrides)
  M.register_statusline_modules(config.ui.statusline)

  return config
end

---@param stl_config table
function M.register_statusline_modules(stl_config)
  stl_config.modules = stl_config.modules or {}

  stl_config.modules.breadcrumbs = function()
    local ok, mod = pcall(require, "nvchad.ui.stl_modules.lsp_based")
    if not ok then return "" end
    local band = mod.mode_band_group()
    return mod.hl_open(band) .. mod.render_breadcrumbs_inherit_lspfirst(band)
  end

  stl_config.modules.cursor = function()
    local band = require("nvchad.ui.stl_modules.lsp_based").mode_band_group()
    local mode = CursorCtl.get_mode()
    if mode == "off" then return "" end

    local renderer = require("nvchad.ui.CursorCtl.renderer")
    local pct = require("nvchad.ui.CursorCtl.progress_calculators")
    local pieces = { renderer.cursor_classic() }

    if mode == "row_progress" then
      pieces[#pieces + 1] = renderer.pct_token(pct.compute_row_pct(), "R")
    elseif mode == "col_progress" then
      pieces[#pieces + 1] = renderer.pct_token(pct.compute_col_pct(), "C")
    elseif mode == "rows_cols_progress" then
      pieces[#pieces + 1] = renderer.pct_token(pct.compute_row_pct(), "R")
      pieces[#pieces + 1] = renderer.pct_token(pct.compute_col_pct(), "C")
    end

    local utl = require("nvchad.ui.stl_modules.lsp_based")
    return utl.hl_wrap(band, table.concat(pieces, ""))
  end
end

-- Public API für User
M.set_cursor_progress_mode = CursorCtl.set_mode
M.toggle_cursor_progress_mode = CursorCtl.toggle_mode
M.get_cursor_progress_mode = CursorCtl.get_mode

return M
```

```lua
-- lua/chadrc.lua (neuer Thin-Wrapper)
---@module 'chadrc'
local NvChadConfig = require("nvchad.config.chadrc")

-- User-Anpassungen (optional)
local user_overrides = {
  ui = {
    statusline = {
      -- Anpassungen hier
    },
  },
}

return NvChadConfig.setup(user_overrides)
```

**Prüfung nach Phase 2:**

* `lua/chadrc.lua` < 30 Zeilen
* Alle NvChad-Logik in `nvchad/config/`
* User kann `user_overrides` via Deep-Merge anpassen

---

### Phase 3: Menu-Modul-Migration

**Ziel:** `config/menu/` → `nvchad/menu/`

**Schritte:**

```lua
-- nvchad/menu/core/custom_menu.lua (verschoben von config/menu/custom_menu.lua)
---@module 'nvchad.menu.core.custom_menu'
-- ... bestehender Code ...
```

```lua
-- nvchad/menu/core/mappings.lua (verschoben von config/menu/mappings.lua)
---@module 'nvchad.menu.core.mappings'
-- ... bestehender Code ...
```

```lua
-- nvchad/menu/init.lua (neuer Orchestrator)
---@module 'nvchad.menu'
local M = {}

---@param opts? table
function M.setup(opts)
  local custom_menu = require("nvchad.menu.core.custom_menu")
  local menu_table = custom_menu(opts)

  package.loaded["menus.custom"] = menu_table
  package.preload["menus.custom"] = function() return menu_table end
  vim.g._menu_custom_registered = true

  -- Mappings registrieren
  require("nvchad.menu.core.mappings").setup()
end

return M
```

**Integration in init.lua:**

```lua
-- lua/init.lua
require("nvchad.menu").setup({
  enable_format = true,
  enable_lsp_section = true,
  -- ...
})
```

---

### Phase 4: Tabufline + Mappings

**Schritte:**

```lua
-- nvchad/tabufline/init.lua (verschoben von custom/tabufline/init.lua)
---@module 'nvchad.tabufline'
-- ... bestehender Code ...
```

```lua
-- nvchad/mappings/init.lua (verschoben von mappings/nvchad.lua)
---@module 'nvchad.mappings'
local M = {}

function M.setup()
  local map = vim.g.__map_helper
  -- ... alle mappings ...
end

return M
```

**Integration:**

```lua
-- lua/init.lua
require("nvchad.mappings").setup()
```

---

### Phase 5: Type-System-Konsolidierung

**Ziel:** Alle `@types/` in jeweilige Subordner verschieben + zentrale `nvchad/@types/init.lua`

```lua
-- nvchad/@types/init.lua
---@meta
---@module 'nvchad.types'

-- Cursor Progress Types
---@alias CursorProgressMode '"classic"'|'"row_progress"'|'"col_progress"'|'"rows_cols_progress"'|'"off"'

-- Menu Types
---@class custom_neotree_entry
---@field key string
---@field enabled boolean
---@field label? string
---@field icon? string
---@field rtxt? string
---@field hl? string

-- LSP-based Statusline Types
---@alias UI.Stl_Modules.LSP_Based.PathMode_t '"auto"'|'"repo"'|'"cwd"'|'"absolute"'|'"home"'

---@class UI.Stl_Modules.LSP_Based.LspCfg
---@field debounce_ms integer
---@field update_events string[]
---@field center_width_frac number
---@field path_mode UI.Stl_Modules.LSP_Based.PathMode_t
---@field path_home_tilde boolean

return {}
```

**Submodul-Types bleiben lokal:**

```lua
-- nvchad/ui/stl_modules/lsp_based/@types/init.lua
---@meta
---@module 'nvchad.ui.stl_modules.lsp_based.types'

-- Detaillierte Types nur für dieses Submodul
---@class LspDocSymCache
---@field version integer
---@field items table[]|nil
---@field hierarchical boolean

return {}
```

---

### Phase 6: Finaler Clean-up

**Zu entfernen:**

```
lua/
├── config/menu/           → gelöscht (nach nvchad/menu/)
├── custom/tabufline/      → gelöscht (nach nvchad/tabufline/)
├── mappings/nvchad.lua    → gelöscht (nach nvchad/mappings/)
└── ui/                    → gelöscht (nach nvchad/ui/)
```

**Neue Ordnerstruktur:**

```
lua/
├── nvchad/
│   ├── @types/
│   ├── config/
│   ├── menu/
│   ├── tabufline/
│   ├── mappings/
│   └── ui/
├── chadrc.lua             → require("nvchad.config.chadrc").setup()
└── init.lua               → lädt alle nvchad-Module via require("nvchad.X").setup()
```

---

## Checkliste pro Phase

---

### Phase 1 (lsp_based Modularisierung)

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | symbols.lua erstellt | Alle TS/LSP-Funktionen verschoben |
| `[ ]` | formatters.lua erstellt | Ellipsize, Icon-Helfer extrahiert |
| `[ ]` | init.lua reduziert | < 200 Zeilen, delegiert an Submodule |
| `[ ]` | Type Guards vorhanden | pcall vor jedem vim.api-Aufruf |
| `[ ]` | @nodiscard auf allen Pure Functions | Keine fehlenden Annotationen |

---

### Phase 2 (chadrc.lua Wrapper)

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | base.lua mit Defaults | Deep-mergeable Struktur |
| `[ ]` | chadrc.lua als Setup-Funktion | User-Config via Parameter |
| `[ ]` | Statusline-Modul-Registrierung | Breadcrumbs, Cursor, Progress |
| `[ ]` | Public API exportiert | set/toggle/get_cursor_progress_mode |
| `[ ]` | lua/chadrc.lua < 30 Zeilen | Nur Thin-Wrapper |

---

### Phase 3 (Menu-Migration)

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | nvchad/menu/core/ erstellt | custom_menu.lua, mappings.lua |
| `[ ]` | nvchad/menu/neotree/ verschoben | entries.lua, init.lua |
| `[ ]` | nvchad/menu/init.lua Setup | Orchestriert alle Submodule |
| `[ ]` | config/menu/ gelöscht | Keine alten Files mehr |

---

### Phase 4 (Tabufline + Mappings)

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | nvchad/tabufline/init.lua | Buffer-Navigation ohne Centering |
| `[ ]` | nvchad/mappings/init.lua | Alle NvChad-Keymaps |
| `[ ]` | custom/tabufline/ gelöscht | |
| `[ ]` | mappings/nvchad.lua gelöscht | |

---

### Phase 5 (Type-Konsolidierung)

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | nvchad/@types/init.lua | Zentrale Public Types |
| `[ ]` | Submodul-@types/ lokal | Nur interne Types |
| `[ ]` | @module-Tags aktualisiert | 'nvchad.X' statt 'ui.X' |

---

### Phase 6 (Clean-up)

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | Alte Ordner gelöscht | config/menu, custom/tabufline, ui/ |
| `[ ]` | init.lua aktualisiert | require("nvchad.X").setup() |
| `[ ]` | Keine toten Requires | Grep nach alten Pfaden |
| `[ ]` | :checkhealth | Keine Fehler |

---

## Vorteile der neuen Struktur

* **Single Point of Removal:** `rm -rf lua/nvchad/` entfernt alle NvChad-Abhängigkeiten
* **Modularität:** `lsp_based/init.lua` von 850 auf ~150 Zeilen reduziert
* **Explizite API:** `nvchad/config/chadrc.lua` als Setup-Funktion → User-Config via Parameter
* **Type-Safety:** Zentrale `@types/` + lokale Submodul-Types
* **Performance:** Keine Änderung, da nur Umstrukturierung (keine Logikänderungen)

---

## Risiken und Mitigationen

| Risiko | Mitigation |
|--------|------------|
| Breaking Changes bei Pfad-Änderungen | Git-Branch für Migration, schrittweise Umstellung |
| Vergessene Requires in alten Modulen | Grep nach `require("ui\\.` und `require("config\\.menu` |
| Type-Fehler durch veraltete Pfade | Lua LS mit strictness-Checks |
| Statusline-Fehler nach Umzug | Fallback in base_config.lua beibehalten |

---

## Migrations-Reihenfolge (Empfehlung)

1. Phase 1 (lsp_based) → Commit
2. Phase 2 (chadrc) → Commit + Test mit `:checkhealth`
3. Phase 3 (Menu) → Commit + Test RightClick
4. Phase 4 (Tabufline + Mappings) → Commit + Test Buffer-Navigation
5. Phase 5 (Types) → Commit + Lua LS Check
6. Phase 6 (Clean-up) → Final Commit + `:PackerSync` (falls Lazy.nvim nicht automatisch aufräumt)

---
