# updir

Navigate up one directory level in Neo-tree while maintaining context and selection.

## Table of content

  - [Features](#features)
  - [Quick Start](#quick-start)
  - [API](#api)
    - [`up_one_level(state)`](#up_one_levelstate)
  - [Behavior](#behavior)
    - [1. Position Detection](#1-position-detection)
    - [2. Root Determination](#2-root-determination)
    - [3. Parent Calculation](#3-parent-calculation)
    - [4. Navigation Execution](#4-navigation-execution)
    - [5. Context Preservation](#5-context-preservation)
    - [6. Sync Coordination](#6-sync-coordination)
  - [Error Handling](#error-handling)
  - [Integration](#integration)
    - [With cwd_sync](#with-cwd_sync)
    - [With reveal_manager](#with-reveal_manager)
    - [Position Handling](#position-handling)
  - [Performance](#performance)
  - [Troubleshooting](#troubleshooting)
    - [Problem: Selection not working after updir](#problem-selection-not-working-after-updir)
    - [Problem: CWD not changing](#problem-cwd-not-changing)
    - [Problem: Conflicts with cwd_sync](#problem-conflicts-with-cwd_sync)
  - [Best Practices](#best-practices)
    - [✅ DO](#do)
    - [❌ DON'T](#dont)
  - [Advanced Usage](#advanced-usage)
    - [Custom Selection Logic](#custom-selection-logic)
    - [Multiple Levels Up](#multiple-levels-up)
  - [Testing](#testing)
  - [See Also](#see-also)

---

## Features

* **In-Place Navigation**: Updates tree root without spawning new windows
* **Context Preservation**: Selects the previous directory after navigating up
* **CWD Management**: Updates window-local or global CWD appropriately
* **Position-Aware**: Handles float/current/sidebar positions correctly
* **Sync Integration**: Pauses cwd_sync to prevent conflicts

---

## Quick Start

```lua
-- In keymaps/init.lua or similar:
["-"] = {
  function(state)
    require("config.neotree.updir").up_one_level(state)
  end,
  desc = "Up one level (in-place) and adjust CWD",
}
```

**Usage:** Press `-` in Neo-tree to go up one directory.

---

## API

### `up_one_level(state)`

Navigate up one directory level from current Neo-tree root.

**Parameter:**
```lua
---@param state table  -- Neo-tree internal state
```

**Returns:** `nil` (side-effects only)

**Example:**
```lua
local updir = require("config.neotree.updir")

-- In Neo-tree mapping callback:
function(state)
  updir.up_one_level(state)
end
```

---

## Behavior

### 1. Position Detection

Determines appropriate CWD command based on Neo-tree position:

```lua
local position = state.window.position or "left"

-- Float/Current → window-local CWD
local cd_cmd = (position == "current" or position == "float")
  and "lcd"   -- Local to window
  or "cd"     -- Global
```

**Rationale:**
- Float/Current windows are temporary → use `lcd` to avoid global side-effects
- Sidebar (left/right) is persistent → global `cd` is acceptable

---

### 2. Root Determination

Resolves current root from various sources:

```lua
-- Priority order:
1. state.path                    -- Explicit root
2. node.path (if directory)      -- Current node
3. node.path:h (if file)         -- Parent of file
```

**Edge-Cases:**
- Empty buffer → Warning, no operation
- Already at filesystem root (`/`) → Warning

---

### 3. Parent Calculation

```lua
local parent = vim.fn.fnamemodify(current_root, ":h")

if parent == current_root then
  -- Already at top (e.g., "/" or "C:\")
  vim.notify("already at top-level directory", vim.log.levels.WARN)
  return
end
```

---

### 4. Navigation Execution

Uses Neo-tree's built-in commands when available:

```lua
-- Priority order:
if state.commands.navigate_up then
  state.commands.navigate_up(state)  -- ✅ Best: Built-in
elseif state.commands.set_root then
  state.commands.set_root(state, parent)  -- ✅ Good: Direct set
else
  manager.navigate(state, parent)  -- ⚠️ Fallback
end
```

---

### 5. Context Preservation

Selects the previous directory in the parent view:

```lua
-- After navigation completes:
vim.defer_fn(function()
  local tree = state.tree
  local parent_node = tree:get_node()

  if parent_node.children then
    for _, child in ipairs(parent_node.children) do
      if child.path == old_path then
        tree:set_selection(child:get_id())  -- ✅ Select old dir
        break
      end
    end
  end
end, 100)
```

**Example:**
```
Before:              After:
  project/             project/
    src/  ← current      src/  ← SELECTED
      foo.lua            bar/
      bar.lua          tests/
```

---

### 6. Sync Coordination

Pauses `cwd_sync` to prevent immediate re-sync:

```lua
local cwd_sync = require("config.neotree.cwd_sync")
cwd_sync.pause_sync(3000)  -- Pause 3 seconds
```

**Why 3000ms?**
- User needs time to navigate/browse
- Longer than typical buffer-switch (which uses 2000ms)
- Prevents cwd_sync from fighting with manual navigation

---

## Error Handling

All critical operations are wrapped in `pcall`:

```lua
-- CWD change
local ok_cd, cd_err = pcall(function()
  vim.cmd(string.format("%s %s", cd_cmd, esc))
end)
if not ok_cd then
  vim.notify(("cwd change failed: %s"):format(tostring(cd_err)), vim.log.levels.ERROR)
  return
end

-- Tree refresh
local ok_mod, refresher = pcall(require, "config.neotree.refresh_adapter")
if ok_mod then
  refresher.refresh(state)
end
```

---

## Integration

### With cwd_sync

```lua
-- updir pauses cwd_sync
updir.up_one_level(state)  -- Pauses 3s

-- After 3s, cwd_sync resumes normal operation
-- If user switches buffer during pause, sync is skipped
```

---

### With reveal_manager

```lua
-- updir does NOT use reveal_manager
-- Instead, directly selects node after navigation
-- This is intentional: updir is manual navigation, not reveal
```

---

### Position Handling

```lua
-- Float/Current: Window-local CWD
-- Reason: These are temporary views, avoid global side-effects

-- Left/Right: Global CWD
-- Reason: Persistent sidebar, user expects project-wide effect
```

---

## Performance

| Operation | Complexity | Notes |
|-----------|-------------|-------|
| Root calculation | O(1) | Simple path manipulation |
| Navigation | O(log n) | Neo-tree internal tree update |
| Selection | O(n) | Linear search in children (typically <100) |
| CWD change | O(1) | Single vim command |

**Total:** Very fast, typically <10ms even for large directories.

---

## Troubleshooting

### Problem: Selection not working after updir

**Diagnose:**
```lua
vim.defer_fn(function()
  print("Children:", #parent_node.children)
  for _, child in ipairs(parent_node.children) do
    print("Child:", child.path)
  end
end, 100)
```

**Possible causes:**
- Tree not fully loaded yet (increase delay from 100ms)
- Path mismatch (normalized paths different)
- Node is hidden/filtered

**Solution:**
```lua
-- Increase delay
vim.defer_fn(function() ... end, 200)

-- Or force refresh before selection
refresher.refresh(state)
vim.defer_fn(function() ... end, 150)
```

---

### Problem: CWD not changing

**Diagnose:**
```lua
-- Check position
print("Position:", state.window.position)

-- Check if command succeeded
vim.cmd("pwd")
```

**Solution:**
- Verify permission to access parent directory
- Check if parent exists (`vim.fn.isdirectory(parent)`)
- Try global `cd` instead of `lcd` for testing

---

### Problem: Conflicts with cwd_sync

**Diagnose:**
```lua
-- Check if pause is working
local cwd_sync = require("config.neotree.cwd_sync")
print("Paused until:", cwd_sync.S.pause_until)
print("Current time:", vim.loop.now())
```

**Solution:**
- Increase pause duration (`pause_sync(5000)`)
- Check if cwd_sync is respecting pause (see cwd_sync.lua `sync_now`)

---

## Best Practices

### ✅ DO

```lua
-- Use - mapping for updir (intuitive)
["-"] = { updir.up_one_level, desc = "Up one level" }

-- Combine with + for down (set root to node)
["+"] = { set_root_to_node, desc = "Set root to node" }

-- Keep pause duration reasonable (2-5 seconds)
cwd_sync.pause_sync(3000)
```

---

### ❌ DON'T

```lua
-- NICHT: Zu kurze Pause
cwd_sync.pause_sync(500)  -- ❌ cwd_sync überschreibt sofort

-- NICHT: In tight loop aufrufen
for i = 1, 10 do
  updir.up_one_level(state)  -- ❌ Chaos
end

-- NICHT: Ohne State aufrufen
updir.up_one_level()  -- ❌ Fehler: state required
```

---

## Advanced Usage

### Custom Selection Logic

```lua
-- Select specific node type after updir
vim.defer_fn(function()
  for _, child in ipairs(parent_node.children) do
    if child.type == "directory" and child.path == old_path then
      tree:set_selection(child:get_id())
      tree:expand(child)  -- Also expand it
      break
    end
  end
end, 100)
```

---

### Multiple Levels Up

```lua
-- Navigate up N levels
local function up_n_levels(state, n)
  for i = 1, n do
    updir.up_one_level(state)
    vim.wait(100)  -- Wait for each level to complete
  end
end
```

---

## Testing

```lua
describe("updir", function()
  local updir = require("config.neotree.updir")

  it("navigates up one level", function()
    local state = create_test_state("/project/src")
    updir.up_one_level(state)

    -- After navigation
    assert.equals("/project", state.path)
  end)

  it("selects old directory", function()
    local state = create_test_state("/project/src")
    updir.up_one_level(state)

    vim.wait(150)  -- Wait for selection

    local selected = state.tree:get_node()
    assert.equals("/project/src", selected.path)
  end)

  it("pauses cwd_sync", function()
    local cwd_sync = require("config.neotree.cwd_sync")
    local before = cwd_sync.S.pause_until

    updir.up_one_level(state)

    local after = cwd_sync.S.pause_until
    assert.is_true(after > before)
  end)
end)
```

---

## See Also

- [Neo-tree Navigation](https://github.com/nvim-neo-tree/neo-tree.nvim/blob/main/doc/neo-tree.txt#L1234)

---
