# Mighty UI - Architekturkonzept

Ein modulares, performantes UI-Framework für Neovim mit zentralem Event-System und strikter Trennung von Concerns.

## Table of content

- [Mighty UI - Architekturkonzept](#mighty-ui-architekturkonzept)
  - [Start Idee](#start-idee)
    - [Überlegungen](#berlegungen)
    - [Skizze](#skizze)
  - [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [1. Überblick und Zielsetzung](#1-berblick-und-zielsetzung)
    - [Kernfunktionalität](#kernfunktionalitt)
    - [Design-Ziele](#design-ziele)
  - [2. Architektur-Prinzipien](#2-architektur-prinzipien)
    - [2.1 Schichtenmodell](#21-schichtenmodell)
    - [2.2 Dependency Injection](#22-dependency-injection)
    - [2.3 Single Responsibility](#23-single-responsibility)
  - [3. Modulare Struktur](#3-modulare-struktur)
    - [3.1 Verzeichnisstruktur](#31-verzeichnisstruktur)
    - [3.2 Module-Beschreibungen](#32-module-beschreibungen)
      - [**core/controller.lua**](#corecontrollerlua)
      - [**core/event_bus.lua**](#coreevent_buslua)
      - [**actions/registry.lua**](#actionsregistrylua)
  - [4. Datenfluss und Event-System](#4-datenfluss-und-event-system)
    - [4.1 Event-Flow-Diagramm](#41-event-flow-diagramm)
    - [4.2 Event-Typen](#42-event-typen)
    - [4.3 State-Management](#43-state-management)
  - [5. Implementierungsdetails](#5-implementierungsdetails)
    - [5.1 Window-Lifecycle](#51-window-lifecycle)
    - [5.2 Action-Base-Class](#52-action-base-class)
    - [5.3 Find Files Action (Beispiel)](#53-find-files-action-beispiel)
    - [5.4 Layout-Berechnung](#54-layout-berechnung)
  - [6. Performance-Optimierungen](#6-performance-optimierungen)
    - [6.1 Debouncing-Strategie](#61-debouncing-strategie)
    - [6.2 Lazy Action Loading](#62-lazy-action-loading)
    - [6.3 Weak-Table Caching](#63-weak-table-caching)
    - [6.4 Table Pre-Allocation](#64-table-pre-allocation)
    - [6.5 String Concatenation](#65-string-concatenation)
  - [7. Sicherheit und Fehlerbehandlung](#7-sicherheit-und-fehlerbehandlung)
    - [7.1 Safe API Wrapper](#71-safe-api-wrapper)
    - [7.2 Standardized Error Wrapping](#72-standardized-error-wrapping)
    - [7.3 Type Guards](#73-type-guards)
  - [8. Testing-Strategie](#8-testing-strategie)
    - [8.1 Unit Tests (Busted)](#81-unit-tests-busted)
    - [8.2 Integration Tests](#82-integration-tests)
    - [8.3 Property-Based Tests (with quickcheck)](#83-property-based-tests-with-quickcheck)
  - [9. API und Erweiterbarkeit](#9-api-und-erweiterbarkeit)
    - [9.1 Public API (`init.lua`)](#91-public-api-initlua)
    - [9.2 Custom Action Example](#92-custom-action-example)
    - [9.3 Configuration Schema](#93-configuration-schema)
  - [10. Migration und Rollout](#10-migration-und-rollout)
    - [10.1 Entwicklungsphasen](#101-entwicklungsphasen)
    - [10.2 Kritische Pfade (Must-Have für MVP)](#102-kritische-pfade-must-have-fr-mvp)
- [Mighty UI - Architekturkonzept (Teil 2)](#mighty-ui-architekturkonzept-teil-2)
  - [10. Migration und Rollout (Fortsetzung)](#10-migration-und-rollout-fortsetzung)
    - [10.3 Backwards Compatibility & Migration](#103-backwards-compatibility-migration)
    - [10.4 Health-Check Implementation](#104-health-check-implementation)
  - [11. Detaillierte Implementierung: Core-Module](#11-detaillierte-implementierung-core-module)
    - [11.1 State Management (ui_state.lua)](#111-state-management-ui_statelua)
    - [11.2 Action State (action_state.lua)](#112-action-state-action_statelua)
    - [11.3 Event Bus (event_bus.lua)](#113-event-bus-event_buslua)
    - [11.4 Controller (controller.lua)](#114-controller-controllerlua)
  - [12. UI-Komponenten](#12-ui-komponenten)
    - [12.1 Window Manager (ui/windows.lua)](#121-window-manager-uiwindowslua)
    - [12.2 Rendering (ui/render.lua)](#122-rendering-uirenderlua)

---

## Start Idee

Ein UI-Window, dass wie ein Menü aufgebaut ist:
    - ACTIONS: links Buttons/Felder untereinander mit Aktionen wie Find, Grep, Mappings, Usercommands, Autocommands, usw...
        * Man kann sie per maus aktivieren oder per Ziffern (C-1, C-2, C-3..). Sie zeigen mit Highlight per farbe an, welche(r) Action/Modus gerade aktiv ist
        * Die Grße der Actions fields hängt davon ab, wieviele action fields registriert sind. mindestens müssen sie aber einen Zeile hoch sein. es soll kein vertikales scolling der gesamt UI geben (im preview window selbt natürlich schon). Würde zb nur ein Action registriert sein, dann würde sie die gesamte actions Spalt hoch sein. Werden zu viele Actions registiert (registered actions > (nvim höhe - statusline - tabline = inerre nvim buffer höhe)), dann jene, die nicht mehr hineinpassen skipped und der User per Notify informiert.
    - MASTER PROMPT: die erste zeile von Links nach rechts ist die Master-Prompt
        * hier werden die Prompts für alle Actions eingegeben. Jede Action hält state für "ihre" master prompt. wechselt man in die Action, wird der zuletzt eingegebener Text der Prompt geladen
    - PREVIEW: Mitte ist ein Preview/Info window
        * Während grep/find files wird es als
    - OPTS: rechts oben Feld indem man optionen/infos hat, zb kann man bei grep zwischen grepvarianten wie live grep oä. hin und herschalten
    - RESULTS: Hier wird die Result/File - Liste angezeigt

    - Special Mappings in der Trefferliste (mappings erstmal anglegen und bis die Logik implementiert ist ein notify mit "fired XY" ausgeben):
        * S-CR: Öffnet den Treffer im Background als Buffer ohne die UI zu schließen
        * m: Markiert Treffer
        * TAB: Wenn Multiselect möglich (grep/findfiles), Treffer markieren
        * D: Löscht die markierten Dateien (wie in config/neotree/trash)

    - Special Action Replace: Wie Replacer Plugin, zweite Prompt (old/new) unter der Master Prompt klapt auf (bei Archiktur darauf achten, dass dies möglich ist). Zu beginn diese ohne Logik implementieren, dasss machen wir dann später.
    - Actions Keymaps, Usercommands udn Autocmds zeigen entsprechend diese auf und man kann darin mit grep suchen

---

### Überlegungen

1. Da man die Actions per Maus oder Ziffern anwählt und das Preview window keinen Fokus braucht, kann man als User zwische der Prompt, den Options und der Resultliste springen, wie immer mit wincmd * oder mit mappings (entweder M-1, M-2, M-3 oder S-8, S-9, S-0, oder bessere.
2. Alle Mappings sollten vom User einstellbar sein
3. Actions können augetauscht oder hinzugefügt werden. Dazu muss eis eine API geben. Es muss Der Action Feld display name, das options feld, das infos feld sowie die action die ausgeführt wird definiert werden. Die default mappings sind auch über diese API implementiert. Die Möglichkeit, eine zweite Prompt "auszufahren" soll es auch für andere Actions geben wenn Bedarf besteht
4. Higlights, Farben, Border, usw sollen konfigurierbar sein
5. Es statt eionen Preview Window auch einen Mode geben, der statt einen preview window tatsächlich die file in einen buffer in diesem window ladet. mit einem mapping kann man den Preview mode dann beenden und man kann das window dann fokusieren und wie ein normales window/buffer behandeln. sobald man in der Treffer lsite aber weitergeht oder in einen andere action wehcselt, schaltet sich der preview mode automatisch wieder an und das window wird unfokusierbar und als reine preview window nue geladen. diese verhindert, dass wenn man durch die treferliste geht, dass dutzende/hunderte echte buffer im window geladen werden, die man gar nicht benötigt.
6. Zwei Template actions sollen erstellt werden. eine für find files und eine ür greop, bei denne man aber jeweils einen festen pfad übergebn kann. so kann man diese Templates verwenden, sie in die ui einbinden und ihnen zb stdpath('config') als pfad geben, damit man eine nvim config grep/find files hat. man kann das natürlich mit beliebeigen üfade dann manchen, aber diese zwei templates und die beiden jeweils mit dem cnvim config pfad vorbereitet sollten bereitstehen zum einsatz

---

### Skizze

```ascii
------------------------------------------------------------
|       |>               MASTER PROMPT            <|         |
| Find  |------------------------------------------|   OPTS  |
| Files |  optionale Prompt - nur im Replace Mode  |         |
|       |------------------------------------------|         |
|-------|                                          |---------|
|       |                                          |         |
| Grep  |                                          |         |
|       |                PREVIEW                   | Results |
|       |                                          |         |
|-------|                 WINDOW                   |         |
|       |                                          |         |
|  Key  |                                          |         |
|  Maps |                                          |         |
|       |                                          |         |
|-------|                                          |         |
|       |                                          |         |
|  Usr  |                                          |         |
|  Cmds |                                          |         |
|       |                                          |         |
|-------|                                          |         |
|       |                                          |         |
|  Auto |                                          |         |
|  Cmds |                                          |         |
|       |                                          |         |
|-------|                                          |         |
|       |                                          |         |
|  Repl |                                          |         |
|  ace  |------------------------------------------|         |
|       |                 Infos                    |         |
---------------------------------------------------------------
```

---

## 1. Überblick und Zielsetzung

### Kernfunktionalität

Ein UI-Framework, das:
- Multiple Actions (Find, Grep, Keymaps, etc.) in einer konsistenten Oberfläche vereint
- Live-Preview mit intelligentem Caching bietet
- Vollständig über API erweiterbar ist
- Performance-optimiert für große Datensätze arbeitet
- Accessibility und Keyboard-First-Workflow unterstützt

### Design-Ziele

| Ziel | Begründung | Priorität |
|------|------------|-----------|
| **Modularität** | Jede Action ist isoliert testbar und austauschbar | 🔴 KRITISCH |
| **Lazy Loading** | Nur aktive Actions werden geladen | 🔴 KRITISCH |
| **Zero Globals** | Kein globaler State, DI-basiert | 🔴 KRITISCH |
| **Event-Driven** | Zentrale Event-Koordination statt direkter Kopplung | 🔴 KRITISCH |
| **Performance** | Sub-50ms UI-Response, intelligentes Debouncing | 🟡 EMPFOHLEN |
| **Cross-Platform** | Windows/Linux/MacOS via `lib.cross` | 🔴 KRITISCH |

---

## 2. Architektur-Prinzipien

### 2.1 Schichtenmodell

```
┌─────────────────────────────────────────┐
│         User Commands & Keymaps         │  ← Entry Layer
├─────────────────────────────────────────┤
│          UI Controller (Core)           │  ← Orchestration
├──────────┬──────────┬───────────────────┤
│  Actions │   UI     │   Event System    │  ← Business Logic
│ Registry │ Manager  │   (PubSub)        │
├──────────┴──────────┴───────────────────┤
│     State Management (ui_state.lua)     │  ← Data Layer
├─────────────────────────────────────────┤
│   Neovim API Wrapper (safe_api.lua)     │  ← Platform Abstraction
└─────────────────────────────────────────┘
```

### 2.2 Dependency Injection

**Prinzip**: Keine Hard-Coded Dependencies, alles wird injiziert.

```lua
-- ❌ BAD: Hard-coded dependency
local function create_preview()
    local state = require("mighty.state.ui_state")
    -- ...
end

-- ✅ GOOD: Dependency injection
local function create_preview(state_provider, config)
    local state = state_provider.get_state()
    -- ...
end
```

### 2.3 Single Responsibility

| Modul | Eine Verantwortung |
|-------|--------------------|
| `ui/layout.lua` | Window-Layout-Berechnung |
| `ui/render.lua` | Buffer-Content-Rendering |
| `ui/windows.lua` | Window-Lifecycle (create/destroy) |
| `core/controller.lua` | Event-Koordination |
| `actions/registry.lua` | Action-Verwaltung |

---

## 3. Modulare Struktur

### 3.1 Verzeichnisstruktur

```
lua/mighty/
├── init.lua                    # Public API
├── config.lua                  # Configuration management
├── health.lua                  # :checkhealth mighty
│
├── types/                      # Type definitions
│   ├── init.lua
│   ├── action.lua
│   ├── ui.lua
│   └── event.lua
│
├── lib/                        # Shared utilities
│   ├── safe_api.lua           # vim.api wrapper with validation
│   ├── debounce.lua           # Debouncing utilities
│   └── cache.lua              # Weak-table caching
│
├── core/
│   ├── controller.lua         # Main orchestrator
│   ├── event_bus.lua          # PubSub event system
│   └── lifecycle.lua          # Startup/teardown logic
│
├── state/
│   ├── ui_state.lua           # UI state (windows, buffers)
│   ├── action_state.lua       # Per-action state (prompts, results)
│   └── session_state.lua      # Session persistence
│
├── ui/
│   ├── layout.lua             # Window dimension calculation
│   ├── windows.lua            # Window creation/destruction
│   ├── render.lua             # Buffer rendering
│   ├── highlight.lua          # Highlight management
│   └── components/
│       ├── prompt.lua
│       ├── actions_panel.lua
│       ├── preview.lua
│       ├── results.lua
│       └── opts.lua
│
├── actions/
│   ├── registry.lua           # Action registration API
│   ├── base.lua               # BaseAction class
│   └── builtin/
│       ├── find_files.lua
│       ├── grep.lua
│       ├── keymaps.lua
│       ├── usercommands.lua
│       ├── autocommands.lua
│       └── replace.lua
│
├── keymaps.lua                # Default keymaps
└── commands.lua               # User commands
```

### 3.2 Module-Beschreibungen

#### **core/controller.lua**

```lua
---@module 'mighty.core.controller'
---@brief Zentraler Orchestrator für alle UI-Events
---@description
--- Koordiniert:
--- - Action-Wechsel
--- - Prompt-Updates
--- - Preview-Rendering
--- - Result-Liste-Updates
---
--- Nutzt Event-Bus für lose Kopplung.
--- Injiziert Dependencies (state, event_bus, ui_manager).

---@class MightyController
local M = {}

---@param deps MightyControllerDeps
---@return MightyController
function M.new(deps)
    local self = setmetatable({}, { __index = M })
    self.deps = deps
    self.current_action = nil
    return self
end

---@param action_id string
---@return boolean success
---@return string? error
function M:switch_action(action_id)
    local ok, err = pcall(function()
        -- Validate action exists
        -- Persist current state
        -- Load new action
        -- Emit event
    end)
    return ok, err
end
```

#### **core/event_bus.lua**

```lua
---@module 'mighty.core.event_bus'
---@brief Zentrales PubSub-System für lose Kopplung

---@class EventBus
---@field _handlers table<string, function[]>
local M = {}

---@param event_name string
---@param handler function
function M:subscribe(event_name, handler)
    -- Store handler in weak table
end

---@param event_name string
---@param data any
function M:emit(event_name, data)
    -- Call all handlers with pcall
end
```

#### **actions/registry.lua**

```lua
---@module 'mighty.actions.registry'
---@brief Action-Registry mit Lazy-Loading

---@class ActionRegistry
local M = {}

---@class ActionDefinition
---@field id string Unique identifier
---@field label string Display name
---@field module string Module path for lazy loading
---@field keybind? string Optional keybind (e.g., "<C-1>")
---@field config? table Custom configuration

local _actions = {} -- Weak table: { [id] = instance }

---@param def ActionDefinition
function M.register(def)
    -- Validate definition
    -- Store lazy loader
end

---@param id string
---@return BaseAction? instance
function M.get(id)
    if not _actions[id] then
        -- Lazy load via require
    end
    return _actions[id]
end
```

---

## 4. Datenfluss und Event-System

### 4.1 Event-Flow-Diagramm

```
User Input (Keypress/Mouse)
    │
    ├─→ [Keymaps] ──→ Controller.switch_action()
    │                      │
    │                      ├─→ EventBus.emit("action:changed")
    │                      │       │
    │                      │       ├─→ UI.update_highlights()
    │                      │       └─→ UI.render_action_panel()
    │                      │
    │                      └─→ ActionState.restore_prompt()
    │
    ├─→ [Prompt Edit] ──→ Controller.on_prompt_change()
    │                      │
    │                      ├─→ Debounce(100ms) ──→ Action.search()
    │                      │                           │
    │                      │                           ├─→ Results.update()
    │                      │                           └─→ Preview.update()
    │                      │
    │                      └─→ EventBus.emit("prompt:changed")
    │
    └─→ [Result Select] ──→ Action.on_select()
                               │
                               ├─→ Preview.load_file()
                               └─→ EventBus.emit("result:selected")
```

### 4.2 Event-Typen

```lua
---@alias MightyEvent
---| "action:changed"      # { action_id: string }
---| "prompt:changed"      # { action_id: string, text: string }
---| "result:selected"     # { action_id: string, item: ResultItem }
---| "preview:loaded"      # { bufnr: integer }
---| "ui:ready"            # { }
---| "ui:closing"          # { }
---| "multiselect:toggled" # { items: ResultItem[] }
```

### 4.3 State-Management

```lua
---@class UIState
---@field windows MightyWindows
---@field buffers MightyBuffers
---@field layout LayoutDimensions

---@class ActionState
---@field [string] ActionInstanceState  # Key: action_id

---@class ActionInstanceState
---@field prompt string
---@field results ResultItem[]
---@field selected_indices integer[]
---@field cursor_pos integer
---@field preview_bufnr? integer
```

**Zugriffsmuster**:

```lua
-- ❌ BAD: Direct global access
local state = require("mighty.state.ui_state")
state.windows.preview = new_win

-- ✅ GOOD: Getter/Setter
ui_state.set_preview_window(new_win)
local win = ui_state.get_preview_window()
```

---

## 5. Implementierungsdetails

### 5.1 Window-Lifecycle

```lua
---@module 'mighty.ui.windows'

local M = {}

---@class WindowConfig
---@field relative "editor"
---@field row integer
---@field col integer
---@field width integer
---@field height integer
---@field border string
---@field focusable boolean

---@param config WindowConfig
---@return integer? win
---@return string? error
function M.create_window(config)
    -- Validate config
    local ok, win_or_err = pcall(vim.api.nvim_open_win, 0, false, config)
    if not ok then
        return nil, win_or_err
    end

    -- Validate window
    if not vim.api.nvim_win_is_valid(win_or_err) then
        return nil, "Window creation succeeded but handle invalid"
    end

    return win_or_err, nil
end

---@param win integer
---@return boolean success
function M.close_window(win)
    if not win or not vim.api.nvim_win_is_valid(win) then
        return false
    end

    local ok = pcall(vim.api.nvim_win_close, win, true)
    return ok
end
```

### 5.2 Action-Base-Class

```lua
---@module 'mighty.actions.base'
---@class BaseAction
---@field id string
---@field label string
---@field config table

local M = {}

---@param opts ActionDefinition
---@return BaseAction
function M.new(opts)
    local self = setmetatable({}, { __index = M })
    self.id = opts.id
    self.label = opts.label
    self.config = opts.config or {}
    return self
end

---Called when action becomes active
---@param prompt string
function M:activate(prompt)
    -- Override in subclass
end

---Called on prompt change (debounced)
---@param prompt string
function M:search(prompt)
    -- Override in subclass
end

---Called when result is selected
---@param item ResultItem
---@param mode "open"|"background"
function M:on_select(item, mode)
    -- Override in subclass
end

---Cleanup when action deactivates
function M:deactivate()
    -- Override if needed
end
```

### 5.3 Find Files Action (Beispiel)

```lua
---@module 'mighty.actions.builtin.find_files'

local BaseAction = require("mighty.actions.base")
local M = setmetatable({}, { __index = BaseAction })

---@param opts ActionDefinition
function M.new(opts)
    local self = BaseAction.new(opts)
    setmetatable(self, { __index = M })

    -- Action-specific state
    self.root_dir = opts.config.root_dir or vim.fn.getcwd()
    self.cache = setmetatable({}, { __mode = "v" }) -- Weak cache

    return self
end

---@param prompt string
function M:search(prompt)
    local cache_key = self.root_dir .. ":" .. prompt

    -- Check cache
    if self.cache[cache_key] then
        return self.cache[cache_key]
    end

    -- Execute find (async via vim.loop or vim.system)
    local results = self:_find_files_async(prompt)

    -- Cache results
    self.cache[cache_key] = results

    -- Emit event
    self.deps.event_bus:emit("result:updated", {
        action_id = self.id,
        results = results
    })
end

---@param prompt string
---@return ResultItem[]
function M:_find_files_async(prompt)
    -- Implementation with vim.system or vim.loop
    -- Return standardized ResultItem[]
end
```

### 5.4 Layout-Berechnung

```lua
---@module 'mighty.ui.layout'

local M = {}

---@class LayoutDimensions
---@field actions { row: integer, col: integer, width: integer, height: integer }
---@field prompt { row: integer, col: integer, width: integer, height: integer }
---@field preview { row: integer, col: integer, width: integer, height: integer }
---@field opts { row: integer, col: integer, width: integer, height: integer }
---@field results { row: integer, col: integer, width: integer, height: integer }
---@field info { row: integer, col: integer, width: integer, height: integer }

---@param num_actions integer
---@return LayoutDimensions
function M.calculate(num_actions)
    local editor_height = vim.o.lines - vim.o.cmdheight
    local editor_width = vim.o.columns

    -- Define proportions
    local actions_width = 12  -- Fixed width
    local opts_width = 20
    local results_width = 25
    local preview_width = editor_width - actions_width - opts_width - results_width - 4 -- borders

    local prompt_height = 1
    local info_height = 3

    -- Calculate action panel height
    local available_height = editor_height - prompt_height - info_height - 2 -- borders
    local action_height = math.max(1, math.floor(available_height / num_actions))

    -- Validate: Skip actions if overflow
    local max_actions = math.floor(available_height / 1) -- Min 1 line per action
    if num_actions > max_actions then
        lib.notify(
            string.format("Too many actions (%d). Showing first %d.", num_actions, max_actions),
            "warn"
        )
        num_actions = max_actions
    end

    return {
        actions = { row = 1, col = 0, width = actions_width, height = available_height },
        prompt = { row = 0, col = actions_width, width = preview_width + opts_width, height = 1 },
        preview = { row = 1, col = actions_width, width = preview_width, height = available_height },
        opts = { row = 1, col = actions_width + preview_width, width = opts_width, height = math.floor(available_height / 2) },
        results = { row = 1, col = actions_width + preview_width + opts_width, width = results_width, height = available_height },
        info = { row = editor_height - info_height, col = actions_width + preview_width, width = opts_width, height = info_height },
    }
end
```

---

## 6. Performance-Optimierungen

### 6.1 Debouncing-Strategie

```lua
---@module 'mighty.lib.debounce'

local M = {}

---@param fn function
---@param delay_ms integer
---@return function debounced
function M.debounce(fn, delay_ms)
    local timer = nil

    return function(...)
        local args = { ... }

        if timer then
            vim.fn.timer_stop(timer)
        end

        timer = vim.fn.timer_start(delay_ms, function()
            fn(unpack(args))
            timer = nil
        end)
    end
end
```

**Anwendung**:

```lua
-- In controller.lua
self.on_prompt_change = debounce(function(prompt)
    self.current_action:search(prompt)
end, 100) -- 100ms delay
```

### 6.2 Lazy Action Loading

```lua
-- In registry.lua
function M.register(def)
    _action_defs[def.id] = {
        label = def.label,
        module = def.module,
        config = def.config,
    }
    -- NOT loaded yet
end

function M.get(id)
    if _actions[id] then
        return _actions[id]
    end

    local def = _action_defs[id]
    if not def then
        return nil
    end

    -- Lazy load NOW
    local ok, module = pcall(require, def.module)
    if not ok then
        lib.notify("Failed to load action: " .. id, "error")
        return nil
    end

    _actions[id] = module.new({ id = id, label = def.label, config = def.config })
    return _actions[id]
end
```

### 6.3 Weak-Table Caching

```lua
---@module 'mighty.lib.cache'

local M = {}

---@return table cache
function M.create_cache()
    return setmetatable({}, { __mode = "v" }) -- Values are weak
end

---Example usage in action
self.cache = M.create_cache()
self.cache["some_key"] = expensive_result
```

### 6.4 Table Pre-Allocation

```lua
-- ❌ BAD: No pre-allocation
local results = {}
for i = 1, 10000 do
    table.insert(results, process(i))
end

-- ✅ GOOD: Pre-allocate
local results = { [10000] = false } -- Reserve space
for i = 1, 10000 do
    results[i] = process(i)
end
```

### 6.5 String Concatenation

```lua
-- ❌ BAD: Concatenation in loop
local text = ""
for _, line in ipairs(lines) do
    text = text .. line .. "\n"
end

-- ✅ GOOD: table.concat
local buffer = {}
for i, line in ipairs(lines) do
    buffer[i] = line
end
local text = table.concat(buffer, "\n")
```

---

## 7. Sicherheit und Fehlerbehandlung

### 7.1 Safe API Wrapper

```lua
---@module 'mighty.lib.safe_api'

local M = {}

---@param bufnr integer
---@return boolean is_valid
function M.buf_is_valid(bufnr)
    return bufnr and type(bufnr) == "number" and vim.api.nvim_buf_is_valid(bufnr)
end

---@param win integer
---@return boolean is_valid
function M.win_is_valid(win)
    return win and type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

---@param bufnr integer
---@param lines string[]
---@return boolean success
---@return string? error
function M.buf_set_lines(bufnr, lines)
    if not M.buf_is_valid(bufnr) then
        return false, "Invalid buffer"
    end

    local ok, err = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, lines)
    if not ok then
        return false, tostring(err)
    end

    return true, nil
end
```

### 7.2 Standardized Error Wrapping

```lua
---@module 'mighty.lib.error'

local M = {}

---@class MightyResult
---@field ok boolean
---@field result any?
---@field error string?

---@param fn function
---@param ... any
---@return MightyResult
function M.safe_call(fn, ...)
    local ok, result = pcall(fn, ...)

    if ok then
        return { ok = true, result = result, error = nil }
    else
        return { ok = false, result = nil, error = tostring(result) }
    end
end

---Example usage
local result = safe_call(function()
    return vim.api.nvim_open_win(0, false, config)
end)

if not result.ok then
    lib.notify("Window creation failed: " .. result.error, "error")
end
```

### 7.3 Type Guards

```lua
---Before every API call
function M:update_preview(file_path)
    -- Type guards
    if type(file_path) ~= "string" or file_path == "" then
        return false, "Invalid file path"
    end

    local win = self.state.get_preview_window()
    if not safe_api.win_is_valid(win) then
        return false, "Preview window invalid"
    end

    -- Proceed safely
    -- ...
end
```

---

## 8. Testing-Strategie

### 8.1 Unit Tests (Busted)

```lua
-- tests/unit/actions/registry_spec.lua

describe("ActionRegistry", function()
    local registry

    before_each(function()
        registry = require("mighty.actions.registry")
        registry._reset() -- Test helper
    end)

    it("registers action with valid definition", function()
        local def = {
            id = "test_action",
            label = "Test",
            module = "mighty.actions.builtin.find_files",
        }

        local ok = registry.register(def)
        assert.is_true(ok)
    end)

    it("rejects duplicate action ID", function()
        local def = { id = "test", label = "Test", module = "..." }

        registry.register(def)
        local ok, err = pcall(registry.register, def)

        assert.is_false(ok)
        assert.matches("already registered", err)
    end)

    it("lazy loads action on first get", function()
        local def = { id = "find", label = "Find", module = "mighty.actions.builtin.find_files" }
        registry.register(def)

        local action = registry.get("find")
        assert.is_not_nil(action)
        assert.equals("find", action.id)
    end)
end)
```

### 8.2 Integration Tests

```lua
-- tests/integration/ui_lifecycle_spec.lua

describe("UI Lifecycle", function()
    local controller

    before_each(function()
        controller = require("mighty.core.controller").new({
            state = require("mighty.state.ui_state"),
            event_bus = require("mighty.core.event_bus").new(),
        })
    end)

    it("opens UI and creates all windows", function()
        controller:open()

        local state = controller.deps.state
        assert.is_not_nil(state.get_prompt_window())
        assert.is_not_nil(state.get_preview_window())
        assert.is_not_nil(state.get_results_window())
    end)

    it("switches actions without errors", function()
        controller:open()

        local ok = controller:switch_action("grep")
        assert.is_true(ok)

        ok = controller:switch_action("find_files")
        assert.is_true(ok)
    end)
end)
```

### 8.3 Property-Based Tests (with quickcheck)

```lua
describe("Layout calculation", function()
    it("never produces negative dimensions", function()
        for _ = 1, 100 do
            local num_actions = math.random(1, 50)
            local layout = require("mighty.ui.layout").calculate(num_actions)

            assert.is_true(layout.preview.width >= 0)
            assert.is_true(layout.preview.height >= 0)
            -- etc.
        end
    end)
end)
```

---

## 9. API und Erweiterbarkeit

### 9.1 Public API (`init.lua`)

```lua
---@module 'mighty'
---@brief Public API for Mighty UI

local M = {}

---Setup Mighty with user configuration
---@param opts? MightyConfig
function M.setup(opts)
    local config = require("mighty.config")
    config.setup(opts or {})

    -- Register default actions
    require("mighty.actions.builtin.find_files").register()
    require("mighty.actions.builtin.grep").register()
    -- etc.

    -- Setup commands and keymaps
    require("mighty.commands").setup()
    require("mighty.keymaps").setup()
end

---Open Mighty UI
---@param action_id? string Optional initial action
function M.open(action_id)
    local controller = require("mighty.core.controller")
    controller.open(action_id)
end

---Close Mighty UI
function M.close()
    local controller = require("mighty.core.controller")
    controller.close()
end

---Register a custom action
---@param def ActionDefinition
function M.register_action(def)
    local registry = require("mighty.actions.registry")
    registry.register(def)
end

return M
```

### 9.2 Custom Action Example

```lua
-- In user config: ~/.config/nvim/lua/my_actions/git_status.lua

local BaseAction = require("mighty.actions.base")
local M = setmetatable({}, { __index = BaseAction })

function M.new(opts)
    local self = BaseAction.new(opts)
    setmetatable(self, { __index = M })
    return self
end

function M:search(prompt)
    -- Execute git status
    local results = vim.fn.systemlist("git status --short")

    -- Transform to ResultItem[]
    local items = {}
    for i, line in ipairs(results) do
        items[i] = {
            text = line,
            path = line:match("%s+(.+)$"),
        }
    end

    self.deps.event_bus:emit("result:updated", {
        action_id = self.id,
        results = items,
    })
end

return M
```

**Registration**:

```lua
-- In user init.lua
require("mighty").setup()

require("mighty").register_action({
    id = "git_status",
    label = "Git Status",
    module = "my_actions.git_status",
    keybind = "<C-9>",
})
```

### 9.3 Configuration Schema

```lua
---@class MightyConfig
---@field actions ActionDefinition[] Custom actions to register
---@field keymaps MightyKeymaps Custom keybindings
---@field ui MightyUIConfig UI appearance
---@field preview MightyPreviewConfig Preview behavior

---@class MightyUIConfig
---@field border "single"|"double"|"rounded"|"solid"|"shadow"
---@field highlights table<string, table> Custom highlight groups

---@class MightyPreviewConfig
---@field max_file_size integer Max file size in KB for preview
---@field syntax_highlight boolean Enable syntax highlighting

---@class MightyKeymaps
---@field open string Open Mighty UI (default: "<leader>m")
---@field close string Close UI (default: "<Esc>")
---@field select string Select result (default: "<CR>")
---@field select_bg string Select in background (default: "<S-CR>")
---@field toggle_multi string Toggle multiselect (default: "<Tab>")
---@field mark string Mark item (default: "m")
---@field delete string Delete marked (default: "D")
```

---

## 10. Migration und Rollout

### 10.1 Entwicklungsphasen

| Phase | Deliverables | Zeitrahmen |
|-------|--------------|------------|
| **1. Foundation** | Event-Bus, State, Safe-API, Layout | Woche 1-2 |
| **2. Core UI** | Windows, Rendering, Controller | Woche 3-4 |
| **3. Actions** | Registry, BaseAction, Find/Grep | Woche 5-6 |
| **4. Features** | Multiselect, Preview, Keymaps | Woche 7-8 |
| **5. Polish** | Replace-Mode, Templates, Config | Woche 9-10 |
| **6. Testing** | Unit/Integration/E2E Tests | Woche 11-12 |

### 10.2 Kritische Pfade (Must-Have für MVP)

- ✅ Window-Lifecycle ohne Memory Leaks
- ✅ Action-Wechsel ohne Buffer-Leaks
- ✅ Prompt-Debouncing funktioniert
- ✅ Find Files Action (basic)
- ✅ Grep Action (basic)
- ✅ Keymaps
- ...

# Mighty UI - Architekturkonzept (Teil 2)

## 10. Migration und Rollout (Fortsetzung)

### 10.3 Backwards Compatibility & Migration

Da dies ein neues Plugin ist, keine Migrations-Strategie nötig. Jedoch:

```lua
---@module 'mighty.compat'
---@brief Compatibility layer für zukünftige Breaking Changes

local M = {}

---Version-Check für API-Änderungen
---@param required_version string Minimum version (e.g., "1.0.0")
---@return boolean is_compatible
function M.check_version(required_version)
    local current = require("mighty").version
    return M._compare_versions(current, required_version) >= 0
end

---Deprecated API mit Warning
---@param old_name string
---@param new_name string
---@param removal_version string
function M.deprecate(old_name, new_name, removal_version)
    lib.notify(
        string.format(
            "%s is deprecated. Use %s instead. Will be removed in v%s",
            old_name, new_name, removal_version
        ),
        "warn"
    )
end

return M
```

### 10.4 Health-Check Implementation

```lua
---@module 'mighty.health'
---@brief :checkhealth mighty

local M = {}

function M.check()
    vim.health.start("Mighty UI Health Check")

    -- Check Neovim version
    local nvim_version = vim.version()
    if nvim_version.major < 0 or (nvim_version.major == 0 and nvim_version.minor < 10) then
        vim.health.error("Neovim 0.10+ required", {
            "Current version: " .. vim.fn.execute("version"):match("NVIM v([%d%.]+)"),
            "Please upgrade Neovim"
        })
    else
        vim.health.ok("Neovim version: " .. tostring(nvim_version))
    end

    -- Check lib dependencies
    local ok, lib = pcall(require, "lib")
    if not ok then
        vim.health.error("Custom lib not found", {
            "Mighty requires custom lib utilities",
            "Check /nvim/lua/lib/ directory"
        })
    else
        vim.health.ok("lib utilities available")
    end

    -- Check registered actions
    local registry = require("mighty.actions.registry")
    local actions = registry.get_all()

    if #actions == 0 then
        vim.health.warn("No actions registered", {
            "Run :lua require('mighty').setup() first"
        })
    else
        vim.health.ok(string.format("%d actions registered", #actions))

        -- Verify each action can be loaded
        for _, action_def in ipairs(actions) do
            local action_ok, _ = pcall(registry.get, action_def.id)
            if action_ok then
                vim.health.ok("  ✓ " .. action_def.label)
            else
                vim.health.error("  ✗ " .. action_def.label .. " failed to load")
            end
        end
    end

    -- Check UI state cleanup
    local ui_state = require("mighty.state.ui_state")
    if ui_state.get_prompt_window() then
        vim.health.warn("UI windows still open", {
            "Run :MightyClose to cleanup"
        })
    else
        vim.health.ok("No dangling UI windows")
    end

    -- Check configuration
    local config = require("mighty.config")
    local cfg_ok, cfg_err = pcall(config.validate)
    if cfg_ok then
        vim.health.ok("Configuration valid")
    else
        vim.health.error("Invalid configuration: " .. cfg_err)
    end
end

return M
```

---

## 11. Detaillierte Implementierung: Core-Module

### 11.1 State Management (ui_state.lua)

```lua
---@module 'mighty.state.ui_state'
---@brief Zentrale UI-State-Verwaltung mit Getter/Setter-Pattern

---@class MightyWindows
---@field prompt integer?
---@field preview integer?
---@field results integer?
---@field actions integer?
---@field opts integer?
---@field info integer?

---@class MightyBuffers
---@field prompt integer?
---@field preview integer?
---@field results integer?
---@field actions integer?
---@field opts integer?
---@field info integer?

---@class UIState
local M = {}

-- Private state (nicht direkt exportiert)
local _state = {
    windows = {},
    buffers = {},
    layout = nil,
    is_open = false,
}

---Get window by name
---@param name "prompt"|"preview"|"results"|"actions"|"opts"|"info"
---@return integer? win
function M.get_window(name)
    local win = _state.windows[name]

    -- Validate before returning
    if win and vim.api.nvim_win_is_valid(win) then
        return win
    end

    -- Cleanup invalid reference
    _state.windows[name] = nil
    return nil
end

---Set window handle
---@param name string
---@param win integer
---@return boolean success
function M.set_window(name, win)
    if not win or not vim.api.nvim_win_is_valid(win) then
        return false
    end

    _state.windows[name] = win
    return true
end

---Get buffer by name
---@param name string
---@return integer? bufnr
function M.get_buffer(name)
    local bufnr = _state.buffers[name]

    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        return bufnr
    end

    _state.buffers[name] = nil
    return nil
end

---Set buffer handle
---@param name string
---@param bufnr integer
function M.set_buffer(name, bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    _state.buffers[name] = bufnr
    return true
end

---Get current layout
---@return LayoutDimensions? layout
function M.get_layout()
    return _state.layout
end

---Set layout dimensions
---@param layout LayoutDimensions
function M.set_layout(layout)
    _state.layout = layout
end

---Check if UI is currently open
---@return boolean is_open
function M.is_open()
    return _state.is_open
end

---Mark UI as open/closed
---@param open boolean
function M.set_open(open)
    _state.is_open = open
end

---Cleanup all state (called on close)
function M.cleanup()
    -- Close all windows
    for name, win in pairs(_state.windows) do
        if vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_close, win, true)
        end
    end

    -- Delete all buffers
    for name, bufnr in pairs(_state.buffers) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        end
    end

    -- Reset state
    _state.windows = {}
    _state.buffers = {}
    _state.layout = nil
    _state.is_open = false
end

---Snapshot state for testing/debugging
---@return table snapshot
function M.snapshot()
    return vim.deepcopy(_state)
end

---Restore state from snapshot (testing only)
---@param snapshot table
function M.restore(snapshot)
    _state = vim.deepcopy(snapshot)
end

return M
```

### 11.2 Action State (action_state.lua)

```lua
---@module 'mighty.state.action_state'
---@brief Per-Action State Management

---@class ActionInstanceState
---@field prompt string Current prompt text
---@field results ResultItem[] Search results
---@field selected_indices integer[] Multiselect indices
---@field cursor_pos integer Cursor position in results
---@field preview_bufnr integer? Preview buffer
---@field opts_data table Action-specific options

local M = {}

-- Private storage: { [action_id] = ActionInstanceState }
local _action_states = {}

---Get state for action
---@param action_id string
---@return ActionInstanceState
function M.get(action_id)
    if not _action_states[action_id] then
        _action_states[action_id] = {
            prompt = "",
            results = {},
            selected_indices = {},
            cursor_pos = 1,
            preview_bufnr = nil,
            opts_data = {},
        }
    end

    return _action_states[action_id]
end

---Update prompt for action
---@param action_id string
---@param prompt string
function M.set_prompt(action_id, prompt)
    local state = M.get(action_id)
    state.prompt = prompt
end

---Update results for action
---@param action_id string
---@param results ResultItem[]
function M.set_results(action_id, results)
    local state = M.get(action_id)
    state.results = results

    -- Reset cursor if results changed
    state.cursor_pos = 1
end

---Toggle multiselect for index
---@param action_id string
---@param index integer
function M.toggle_select(action_id, index)
    local state = M.get(action_id)
    local selected = state.selected_indices

    -- Check if already selected
    for i, idx in ipairs(selected) do
        if idx == index then
            table.remove(selected, i)
            return
        end
    end

    -- Add to selection
    table.insert(selected, index)
end

---Clear all selections
---@param action_id string
function M.clear_selections(action_id)
    local state = M.get(action_id)
    state.selected_indices = {}
end

---Get selected items
---@param action_id string
---@return ResultItem[]
function M.get_selected_items(action_id)
    local state = M.get(action_id)
    local items = {}

    for _, idx in ipairs(state.selected_indices) do
        if state.results[idx] then
            table.insert(items, state.results[idx])
        end
    end

    return items
end

---Cleanup state for action
---@param action_id string
function M.cleanup(action_id)
    local state = _action_states[action_id]
    if not state then return end

    -- Cleanup preview buffer
    if state.preview_bufnr and vim.api.nvim_buf_is_valid(state.preview_bufnr) then
        pcall(vim.api.nvim_buf_delete, state.preview_bufnr, { force = true })
    end

    _action_states[action_id] = nil
end

return M
```

### 11.3 Event Bus (event_bus.lua)

```lua
---@module 'mighty.core.event_bus'
---@brief Zentrales PubSub-System mit Error Handling

---@alias EventHandler fun(data: any): nil

---@class EventBus
local M = {}

---Create new event bus instance
---@return EventBus
function M.new()
    local self = setmetatable({}, { __index = M })

    -- Weak table: handlers can be garbage collected
    self._handlers = setmetatable({}, { __mode = "v" })
    self._debug = false

    return self
end

---Subscribe to event
---@param event_name string
---@param handler EventHandler
---@return function unsubscribe
function M:subscribe(event_name, handler)
    if type(handler) ~= "function" then
        error("Handler must be a function")
    end

    if not self._handlers[event_name] then
        self._handlers[event_name] = {}
    end

    table.insert(self._handlers[event_name], handler)

    -- Return unsubscribe function
    return function()
        local handlers = self._handlers[event_name]
        if not handlers then return end

        for i, h in ipairs(handlers) do
            if h == handler then
                table.remove(handlers, i)
                return
            end
        end
    end
end

---Emit event to all subscribers
---@param event_name string
---@param data any
function M:emit(event_name, data)
    if self._debug then
        lib.notify(
            string.format("[EventBus] Emitting: %s", event_name),
            "info"
        )
    end

    local handlers = self._handlers[event_name]
    if not handlers or #handlers == 0 then
        return
    end

    -- Call each handler with pcall
    for _, handler in ipairs(handlers) do
        local ok, err = pcall(handler, data)
        if not ok then
            lib.notify(
                string.format(
                    "Event handler error (%s): %s",
                    event_name,
                    tostring(err)
                ),
                "error"
            )
        end
    end
end

---Enable debug logging
function M:set_debug(enabled)
    self._debug = enabled
end

---Clear all handlers (testing)
function M:clear()
    self._handlers = setmetatable({}, { __mode = "v" })
end

return M
```

### 11.4 Controller (controller.lua)

```lua
---@module 'mighty.core.controller'
---@brief Hauptsteuerung für UI-Lifecycle und Action-Koordination

---@class MightyControllerDeps
---@field ui_state UIState
---@field action_state ActionState
---@field event_bus EventBus
---@field ui_manager UIManager
---@field action_registry ActionRegistry

---@class MightyController
local M = {}

---Create controller instance
---@param deps MightyControllerDeps
---@return MightyController
function M.new(deps)
    -- Validate dependencies
    assert(deps.ui_state, "ui_state required")
    assert(deps.event_bus, "event_bus required")
    assert(deps.action_registry, "action_registry required")

    local self = setmetatable({}, { __index = M })
    self.deps = deps
    self.current_action_id = nil

    -- Setup event subscriptions
    self:_setup_events()

    return self
end

---Open Mighty UI
---@param initial_action_id? string
---@return boolean success
---@return string? error
function M:open(initial_action_id)
    if self.deps.ui_state.is_open() then
        return false, "UI already open"
    end

    -- Get registered actions
    local actions = self.deps.action_registry.get_all()
    if #actions == 0 then
        return false, "No actions registered. Run setup() first."
    end

    -- Calculate layout
    local layout = require("mighty.ui.layout").calculate(#actions)
    self.deps.ui_state.set_layout(layout)

    -- Create UI windows/buffers
    local ok, err = self.deps.ui_manager.create_ui(layout, actions)
    if not ok then
        return false, "Failed to create UI: " .. tostring(err)
    end

    self.deps.ui_state.set_open(true)

    -- Activate initial action
    local action_id = initial_action_id or actions[1].id
    ok, err = self:switch_action(action_id)
    if not ok then
        self:close()
        return false, "Failed to activate action: " .. tostring(err)
    end

    -- Emit event
    self.deps.event_bus:emit("ui:ready", {})

    return true, nil
end

---Close Mighty UI
function M:close()
    if not self.deps.ui_state.is_open() then
        return
    end

    -- Emit closing event
    self.deps.event_bus:emit("ui:closing", {})

    -- Deactivate current action
    if self.current_action_id then
        local action = self.deps.action_registry.get(self.current_action_id)
        if action and action.deactivate then
            pcall(action.deactivate, action)
        end
    end

    -- Cleanup UI
    self.deps.ui_state.cleanup()

    self.current_action_id = nil
end

---Switch to different action
---@param action_id string
---@return boolean success
---@return string? error
function M:switch_action(action_id)
    -- Validate action exists
    local action = self.deps.action_registry.get(action_id)
    if not action then
        return false, "Action not found: " .. action_id
    end

    -- Deactivate current action
    if self.current_action_id then
        local current = self.deps.action_registry.get(self.current_action_id)
        if current and current.deactivate then
            pcall(current.deactivate, current)
        end
    end

    -- Update current
    self.current_action_id = action_id

    -- Restore prompt
    local state = self.deps.action_state.get(action_id)
    self:_update_prompt(state.prompt)

    -- Activate new action
    local ok, err = pcall(action.activate, action, state.prompt)
    if not ok then
        return false, "Activation failed: " .. tostring(err)
    end

    -- Emit event
    self.deps.event_bus:emit("action:changed", {
        action_id = action_id,
    })

    return true, nil
end

---Handle prompt change
---@param text string
function M:on_prompt_change(text)
    if not self.current_action_id then
        return
    end

    -- Update state
    self.deps.action_state.set_prompt(self.current_action_id, text)

    -- Trigger search (debounced)
    local action = self.deps.action_registry.get(self.current_action_id)
    if action and action.search then
        self._debounced_search(action, text)
    end

    -- Emit event
    self.deps.event_bus:emit("prompt:changed", {
        action_id = self.current_action_id,
        text = text,
    })
end

---Handle result selection
---@param index integer
---@param mode "open"|"background"
function M:on_select(index, mode)
    if not self.current_action_id then
        return
    end

    local state = self.deps.action_state.get(self.current_action_id)
    local item = state.results[index]

    if not item then
        return
    end

    -- Update cursor
    state.cursor_pos = index

    -- Call action handler
    local action = self.deps.action_registry.get(self.current_action_id)
    if action and action.on_select then
        local ok, err = pcall(action.on_select, action, item, mode)
        if not ok then
            lib.notify("Selection failed: " .. tostring(err), "error")
        end
    end

    -- Emit event
    self.deps.event_bus:emit("result:selected", {
        action_id = self.current_action_id,
        item = item,
        mode = mode,
    })
end

---Setup event listeners
---@private
function M:_setup_events()
    local debounce = require("mighty.lib.debounce")

    -- Debounced search (100ms)
    self._debounced_search = debounce.debounce(function(action, text)
        local ok, err = pcall(action.search, action, text)
        if not ok then
            lib.notify("Search failed: " .. tostring(err), "error")
        end
    end, 100)

    -- Listen to result updates
    self.deps.event_bus:subscribe("result:updated", function(data)
        if data.action_id == self.current_action_id then
            self.deps.action_state.set_results(data.action_id, data.results)
            -- Trigger UI update
            self.deps.ui_manager.render_results(data.results)
        end
    end)
end

---Update prompt buffer
---@private
---@param text string
function M:_update_prompt(text)
    local bufnr = self.deps.ui_state.get_buffer("prompt")
    if not bufnr then return end

    local ok = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, { text })
    if not ok then
        lib.notify("Failed to update prompt", "error")
    end
end

return M
```

---

## 12. UI-Komponenten

### 12.1 Window Manager (ui/windows.lua)

```lua
---@module 'mighty.ui.windows'
---@brief Window-Lifecycle-Verwaltung

local safe_api = require("mighty.lib.safe_api")

local M = {}

---Create floating window
---@param bufnr integer
---@param config WindowConfig
---@return integer? win
---@return string? error
function M.create_float(bufnr, config)
    if not safe_api.buf_is_valid(bufnr) then
        return nil, "Invalid buffer"
    end

    -- Add default options
    config.style = config.style or "minimal"
    config.relative = config.relative or "editor"
    config.focusable = config.focusable ~= false

    local ok, win_or_err = pcall(vim.api.nvim_open_win, bufnr, false, config)

    if not ok then
        return nil, "Window creation failed: " .. tostring(win_or_err)
    end

    if not safe_api.win_is_valid(win_or_err) then
        return nil, "Window handle invalid after creation"
    end

    return win_or_err, nil
end

---Close window safely
---@param win integer
---@return boolean success
function M.close(win)
    if not safe_api.win_is_valid(win) then
        return false
    end

    local ok = pcall(vim.api.nvim_win_close, win, true)
    return ok
end

---Set window options
---@param win integer
---@param opts table<string, any>
---@return boolean success
function M.set_opts(win, opts)
    if not safe_api.win_is_valid(win) then
        return false
    end

    for opt, value in pairs(opts) do
        local ok = pcall(vim.api.nvim_set_option_value, opt, value, { win = win })
        if not ok then
            lib.notify(string.format("Failed to set option %s", opt), "warn")
        end
    end

    return true
end

return M
```

### 12.2 Rendering (ui/render.lua)

```lua
---@module 'mighty.ui.render'
---@brief Buffer-Content-Rendering mit Performance-Optimierung

local M = {}

---Render lines to buffer
---@param bufnr integer
---@param lines string[]
---@return boolean success
function M.render_lines(bufnr, lines)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    -- Make buffer modifiable
    pcall(vim.api.nvim_set_option_value, "modifiable", true, { buf = bufnr })

    -- Set lines
    local ok = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, lines)

    -- Reset to non-modifiable
    pcall(vim.api.nvim_set_option_value, "modifiable", false, { buf = bufnr })

    return ok
end

---Render results list
---@param bufnr integer
---@param results ResultItem[]
---@param cursor_pos integer
---@param selected_indices integer[]
---@return boolean success
function M.render_results(bufnr, results, cursor_pos, selected_indices)
    -- Pre-allocate buffer
    local lines = { [#results] = "" }

    -- Build selected lookup (faster than table.contains)
    local selected_map = {}
    for _, idx in ipairs(selected_indices) do
        selected_map[idx] = true
    end

    -- Render each line
    for i, item in ipairs(results) do
        local prefix = ""

        if i == cursor_pos then
            prefix = "> "
        elseif selected_map[i] then
            prefix = "✓ "
        else
            prefix = "  "
        end

        lines[i] = prefix .. item.text
    end

    return M.render_lines(bufnr, lines)
end

---Render action panel
---@param bufnr integer
---@param actions ActionDefinition[]
---@param active_id string
---@return boolean success
function M.render_actions(bufnr, actions, active_id)
    local lines = { [#actions] = "" }

    for i, action in ipairs(actions) do
        local marker = (action.id == active_id) and "▶" or " "
        local keybind = action.keybind or ""

        lines[i] = string.format("%s [%s] %s", marker, keybind, action.label)
    end

    return M.render_lines(bufnr, lines)
end

return M
```
