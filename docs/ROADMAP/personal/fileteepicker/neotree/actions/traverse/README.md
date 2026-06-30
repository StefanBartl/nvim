# traverse

Bi-directionale Verzeichnisnavigation für Neo-tree mit automatischer CWD-Synchronisation.

## Table of content

- [traverse](#traverse)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Quick Start](#quick-start)
  - [API](#api)
    - [`up(state)`](#upstate)
    - [`down(state)`](#downstate)
  - [Behavior](#behavior)
    - [Navigation Up (Parent Directory)](#navigation-up-parent-directory)
    - [Navigation Down (Into Directory)](#navigation-down-into-directory)
    - [CWD Handling](#cwd-handling)
    - [Position-Aware Commands](#position-aware-commands)
  - [Integration](#integration)
    - [With cwd_sync](#with-cwd_sync)
    - [With updir (Legacy)](#with-updir-legacy)
  - [Error Handling](#error-handling)
  - [Best Practices](#best-practices)
    - [✅ DO](#do)
    - [❌ DON'T](#dont)
  - [Examples](#examples)
    - [Basic Keymaps](#basic-keymaps)
    - [Advanced: Custom Wrappers](#advanced-custom-wrappers)
  - [See Also](#see-also)

---

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [API](#api)
  - [`up(state)`](#upstate)
  - [`down(state)`](#downstate)
- [Behavior](#behavior)
  - [Navigation Up (Parent Directory)](#navigation-up-parent-directory)
  - [Navigation Down (Into Directory)](#navigation-down-into-directory)
  - [CWD Handling](#cwd-handling)
  - [Position-Aware Commands](#position-aware-commands)
- [Integration](#integration)
  - [With cwd_sync](#with-cwd_sync)
  - [With updir (Legacy)](#with-updir-legacy)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Examples](#examples)
  - [Basic Keymaps](#basic-keymaps)
  - [Advanced: Custom Wrappers](#advanced-custom-wrappers)
- [See Also](#see-also)

---

## Features

- **Bi-directional Navigation**: Aufwärts (Parent) und abwärts (Into) in einem Modul
- **CWD Synchronisation**: Automatisches Update von `:pwd` mit Position-Awareness
- **Smart Selection**: Automatische Auswahl des vorherigen Verzeichnisses nach Up-Navigation
- **Integration**: Nahtlose Integration mit `cwd_sync` (3s Pause bei manueller Navigation)
- **Position-Aware**: Verwendet `lcd` für Float/Current, `cd` für Sidebars
- **Error Safe**: Robuste Fehlerbehandlung mit `pcall` und klaren Notifications

---

## Quick Start

```lua
-- In keymaps/filesystem.lua:
["+"] = {
  function(state)
    require("config.neotree.actions.traverse").down(state)
  end,
  desc = "Navigate into directory and set as root (cwd sync)",
},

["-"] = {
  function(state)
    require("config.neotree.actions.traverse").up(state)
  end,
  desc = "Navigate up one level (cwd sync)",
},
```

---

## API

### `up(state)`

Navigiert eine Verzeichnisebene nach oben (wie `cd ..`).

**Parameter:**
```lua
---@param state Cfg.NeoTree.State Neo-tree internal state
```

**Returns:** `boolean` — `true` bei Erfolg, `false` bei Fehler

**Behavior:**
1. Pausiert `cwd_sync` für 3 Sekunden
2. Ermittelt aktuelles Root-Verzeichnis
3. Berechnet Parent-Directory (`fnamemodify(path, ":h")`)
4. Ändert CWD (window-local oder global je nach Position)
5. Navigiert Tree-Root zu Parent
6. Selektiert das vorherige Verzeichnis im Parent-View
7. Refresht Tree-Display

**Example:**
```lua
-- In filesystem.lua:
["-"] = {
  function(state)
    local traverse = require("config.neotree.actions.traverse")
    traverse.up(state)
  end,
  desc = "Up one level (in-place) and adjust CWD",
}
```

---

### `down(state)`

Navigiert in das selektierte Verzeichnis und setzt es als neues Root.

**Parameter:**
```lua
---@param state Cfg.NeoTree.State Neo-tree internal state
```

**Returns:** `boolean` — `true` bei Erfolg, `false` bei Fehler

**Behavior:**
1. Pausiert `cwd_sync` für 3 Sekunden
2. Validiert dass Node ein Verzeichnis ist
3. Ändert CWD zum Verzeichnis
4. Führt `neo-tree.command.execute({ dir = ..., reveal = true })` aus
5. Refresht Tree-Display

**Example:**
```lua
-- In filesystem.lua:
["+"] = {
  function(state)
    local traverse = require("config.neotree.actions.traverse")
    traverse.down(state)
  end,
  desc = "Set Neovim cwd to node and focus Neo-tree there",
}
```

---

## Behavior

### Navigation Up (Parent Directory)

**Flow:**

```
Current:  /home/user/projects/myapp/src
            ↓ (up)
Target:   /home/user/projects/myapp
```

**Implementation Details:**

1. **Root Detection:**
   - Priorität: `state.path` → `current_node.path` → `current_node:get_id()`
   - Falls File-Node: `fnamemodify(path, ":h")` für Parent

2. **Parent Calculation:**
   ```lua
   local parent = vim.fn.fnamemodify(current_root, ":h")
   ```
   - Edge-Case: Bereits bei `/` → Warning, kein Navigieren

3. **Tree Navigation:**
   - Priorität: `navigate_up()` → `set_root()` → `manager.navigate()`

4. **Selection:**
   - Nach 100ms Delay: Suche alte Root in Parent-Children
   - Fokussierung via `tree:set_selection(child_path)`

---

### Navigation Down (Into Directory)

**Flow:**

```
Current:  /home/user/projects/myapp
            ↓ (down on "src/")
Target:   /home/user/projects/myapp/src
```

**Implementation Details:**

1. **Node Validation:**
   - Prüfung: `is_directory()` oder File → Parent
   - Falls File: Nutze Parent-Verzeichnis

2. **Neo-tree Command:**
   ```lua
   neo-tree.command.execute({
     source = "filesystem",
     dir = target_dir,
     reveal = true
   })
   ```

3. **Fallback:**
   - Falls `neo-tree.command` nicht verfügbar: `manager.navigate()`

---

### CWD Handling

**Position-Aware Commands:**

```lua
-- Float/Current → Window-local
local cd_cmd = "lcd"

-- Left/Right Sidebar → Global
local cd_cmd = "cd"
```

**Rationale:**
- Float/Current sind temporär → lokale CWD vermeidet globale Seiteneffekte
- Sidebar ist persistent → globale CWD ist erwünscht

**Execution:**
```lua
vim.cmd(string.format("%s %s", cd_cmd, vim.fn.fnameescape(dir)))
```

---

### Position-Aware Commands

**Detection:**

```lua
local function get_cd_command(state)
  local position = state.window.position
    or require("config.neotree").get_default_position()

  return (position == "current" or position == "float")
    and "lcd"
    or "cd"
end
```

**Mapping:**

| Position  | Command | Scope           | Reason                    |
|-----------|---------|-----------------|---------------------------|
| `float`   | `lcd`   | Window-local    | Temporary view            |
| `current` | `lcd`   | Window-local    | Buffer-specific context   |
| `left`    | `cd`    | Global          | Persistent sidebar        |
| `right`   | `cd`    | Global          | Persistent sidebar        |
| `top`     | `cd`    | Global          | Horizontal persistent     |
| `bottom`  | `cd`    | Global          | Horizontal persistent     |

---

## Integration

### With cwd_sync

**Pause Mechanism:**

```lua
-- Both up() and down() pause cwd_sync for 3 seconds
pause_cwd_sync(3000)
```

**Why 3 seconds?**
- Länger als Buffer-Switch (2000ms in `cwd_sync`)
- Gibt User Zeit für weitere manuelle Navigation
- Verhindert dass `cwd_sync` sofort zurück-synct

**Behavior:**
```lua
-- User navigates manually
traverse.down(state)  -- Pauses 3s

-- Within 3s: cwd_sync is suppressed
-- After 3s: cwd_sync resumes normal operation
```

---

### With updir (Legacy)

**Migration:**

```lua
-- Old (separate updir module):
local updir = require("config.neotree.updir")
updir.up_one_level(state)

-- New (unified traverse):
local traverse = require("config.neotree.actions.traverse")
traverse.up(state)
```

**Compatibility:**
- `traverse.up()` ist funktional identisch zu `updir.up_one_level()`
- Kann als Drop-In Replacement verwendet werden
- Bietet zusätzlich `down()` Funktionalität

---

## Error Handling

**All Operations Use pcall:**

```lua
-- CWD change
local ok, err = pcall(function()
  vim.cmd(string.format("%s %s", cd_cmd, escaped))
end)

if not ok then
  vim.notify(("CWD change failed: %s"):format(err), vim.log.levels.ERROR)
  return false
end
```

**Common Error Cases:**

| Error                     | Cause                          | Handling                   |
|---------------------------|--------------------------------|----------------------------|
| "No node under cursor"    | Cursor auf Empty-Line          | Warn + return false        |
| "No path under cursor"    | Virtual Node ohne Path         | Warn + return false        |
| "Already at top-level"    | Current root ist `/`           | Warn + return false        |
| "CWD change failed"       | Permissions / Invalid Path     | Error + return false       |
| "Failed to navigate tree" | Neo-tree internals unavailable | Error + return false       |

---

## Best Practices

### ✅ DO

```lua
-- Use with clear keymaps
["+"] = { traverse.down, desc = "Into directory (set root)" }
["-"] = { traverse.up, desc = "Up one level" }

-- Combine with other navigation
["<C-Up>"] = { traverse.up, desc = "Parent directory" }
["<C-Down>"] = { traverse.down, desc = "Into directory" }

-- Use in custom commands
vim.api.nvim_create_user_command("NeoTreeUp", function()
  local state = get_neotree_state()
  traverse.up(state)
end, {})
```

---

### ❌ DON'T

```lua
-- NICHT: In tight loop aufrufen
for i = 1, 10 do
  traverse.up(state)  -- ❌ Chaos, CWD-Konflikte
end

-- NICHT: Ohne State aufrufen
traverse.up()  -- ❌ Fehler: state required

-- NICHT: Pause-Duration ändern ohne Grund
-- (3000ms ist abgestimmt mit cwd_sync)
```

---

## Examples

### Basic Keymaps

```lua
-- In keymaps/filesystem.lua:
local traverse = require("config.neotree.actions.traverse")

return {
  -- Navigate up one level
  ["-"] = {
    function(state) traverse.up(state) end,
    desc = "Up one level (in-place) and adjust CWD",
  },

  -- Navigate into directory
  ["+"] = {
    function(state) traverse.down(state) end,
    desc = "Set Neovim cwd to node and focus Neo-tree there",
  },
}
```

---

### Advanced: Custom Wrappers

```lua
-- Navigate up N levels
local function up_n_levels(state, n)
  local traverse = require("config.neotree.actions.traverse")

  for i = 1, n do
    local ok = traverse.up(state)
    if not ok then break end

    -- Wait for tree to update
    vim.wait(150, function() return false end)
  end
end

-- Navigate to project root
local function to_project_root(state)
  local root = require("config.neotree.actions.project_root").get()

  vim.api.nvim_set_current_dir(root)

  local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
  if ok_cmd then
    neo_cmd.execute({
      source = "filesystem",
      dir = root,
      reveal = true
    })
  end
end
```

---

## See Also

- [updir/README.md](../updir/README.md) — Legacy updir implementation
- [cwd_sync/README.md](../../cwd_sync/README.md) — CWD synchronization system
- [project_root/README.md](../project_root/README.md) — Project root detection

---
