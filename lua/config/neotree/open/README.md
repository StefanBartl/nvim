# open/init

Keymap-based Neo-tree opener with reveal support and position management.

## Table of content

  - [Features](#features)
  - [Quick Start](#quick-start)
  - [Configuration](#configuration)
    - [Custom Extra Aliases](#custom-extra-aliases)
  - [API](#api)
    - [`attach_opener_mappings(opts)`](#attach_opener_mappingsopts)
  - [Opener Behavior](#opener-behavior)
    - [1. Context Gathering](#1-context-gathering)
    - [2. Reveal Configuration](#2-reveal-configuration)
    - [3. Sync Pause](#3-sync-pause)
  - [Position Handling](#position-handling)
    - [Left (Default)](#left-default)
    - [Right](#right)
    - [Float](#float)
    - [Current](#current)
  - [Keymap Registration](#keymap-registration)
    - [Primary Keymaps](#primary-keymaps)
    - [Meta Aliases](#meta-aliases)
    - [Extra Aliases](#extra-aliases)
  - [Default Extra LHS](#default-extra-lhs)
  - [Integration](#integration)
    - [With reveal_manager](#with-reveal_manager)
    - [With cwd_sync](#with-cwd_sync)
    - [With updir](#with-updir)
  - [Error Handling](#error-handling)
    - [Command Not Available](#command-not-available)
    - [Invalid Buffer Context](#invalid-buffer-context)
  - [Performance](#performance)
  - [Troubleshooting](#troubleshooting)
    - [Problem: Keymaps not working](#problem-keymaps-not-working)
    - [Problem: Wrong position opening](#problem-wrong-position-opening)
    - [Problem: Reveal not working](#problem-reveal-not-working)
    - [Problem: cwd_sync overrides immediately](#problem-cwd_sync-overrides-immediately)
  - [Best Practices](#best-practices)
    - [✅ DO](#do)
    - [❌ DON'T](#dont)
  - [Advanced Usage](#advanced-usage)
    - [Custom Opener Function](#custom-opener-function)
    - [Conditional Opening](#conditional-opening)
    - [Position Rotation](#position-rotation)
  - [Testing](#testing)
  - [Changelog](#changelog)
    - [v2.0.0 (2024-01)](#v200-2024-01)
    - [v1.0.0 (2023-12)](#v100-2023-12)
  - [See Also](#see-also)

---

## Features

* **Multi-Position Support**: Open Neo-tree in left/right/float/current
* **Auto-Reveal**: Reveals current buffer when opening
* **Toggle Behavior**: Smart toggle (close if open, open if closed)
* **AltGr-Alias Support**: German keyboard layout support
* **Meta-Key Aliases**: Terminal compatibility (`<M-*>` aliases)
* **Sync Integration**: Pauses cwd_sync after manual open
* **Project-Root Aware**: Opens at project root when available

---

## Quick Start

```lua
-- In plugins/neotree.lua config:
require("config.neotree.open").attach_opener_mappings()
```

**Mappings:**
- `<A-l>` → Open/Toggle Left (default)
- `<A-r>` → Open/Toggle Right
- `<A-f>` → Open/Toggle Float
- `<A-c>` → Open/Toggle Current Window

---

## Configuration

### Custom Extra Aliases

```lua
require("config.neotree.open").attach_opener_mappings({
  extra_lhs = {
    ["<A-l>"] = { "ł", "<leader>nl" },  -- Add custom aliases
    ["<A-f>"] = { "đ", "<leader>nf" },
  }
})
```

**Use-Case:** Terminal emulators that don't support Alt properly.

---

## API

### `attach_opener_mappings(opts)`

Registers all Neo-tree opener keymaps.

**Parameter:**
```lua
---@param opts NeoTreeCfg|nil
---@field extra_lhs table<string, string[]>  -- Additional key aliases
```

**Example:**
```lua
local open = require("config.neotree.open")

open.attach_opener_mappings({
  extra_lhs = {
    ["<A-l>"] = { "¬" },  -- AltGr-L on some keyboards
  }
})
```

**Call once** in plugin config.

---

## Opener Behavior

### 1. Context Gathering

```lua
local ctx = utils.get_buffer_context()
-- Gathers:
-- - Current buffer number
-- - Current file path
-- - Parent directory
```

---

### 2. Reveal Configuration

```lua
local opts = {
  source = "filesystem",
  toggle = true,          -- Close if already open
  reveal = true,          -- Enable reveal
  reveal_file = ctx.file, -- ✅ Reveal current file
  reveal_force_cwd = false, -- Don't force CWD
  position = position,    -- "left"|"right"|"float"|"current"
  dir = ctx.dir,          -- ✅ Open at correct directory
}
```

**Key Points:**
- `reveal = true` enables file selection
- `reveal_file` points to current buffer
- `dir` ensures correct starting directory
- `toggle = true` provides smart open/close

---

### 3. Sync Pause

```lua
local cwd_sync = require("config.neotree.cwd_sync")
cwd_sync.pause_sync(2000)  -- Pause 2 seconds
```

**Rationale:**
- User just opened Neo-tree manually
- Give them 2s to navigate/browse
- Prevents cwd_sync from immediately overriding their view

---

## Position Handling

### Left (Default)

```lua
["<A-l>"] = "Toggle & Reveal (left)"
```

**Behavior:**
- Opens as sidebar on left
- Persists across buffer switches
- Global CWD changes affect it
- **Best for:** Primary file navigation

---

### Right

```lua
["<A-r>"] = "Toggle & Reveal (right)"
```

**Behavior:**
- Opens as sidebar on right
- Useful for dual-pane workflows
- Can coexist with left sidebar (Neo-tree limitation)
- **Best for:** Reference viewing

---

### Float

```lua
["<A-f>"] = "Toggle & Reveal (float)"
```

**Behavior:**
- Opens as centered floating window
- Temporary/modal feel
- Window-local CWD (`lcd`)
- **Best for:** Quick navigation without disrupting layout

---

### Current

```lua
["<A-c>"] = "Toggle & Reveal (current)"
```

**Behavior:**
- Opens in current window (replaces buffer)
- Window-local CWD (`lcd`)
- Most disruptive to layout
- **Best for:** Full-screen file browsing

---

## Keymap Registration

### Primary Keymaps

```lua
-- Example: <A-l>
map("n", "<A-l>", opener_callback, {
  desc = "[Neo-tree] Toggle & Reveal (left)",
  silent = true,
})
```

---

### Meta Aliases

```lua
-- Terminal compatibility: <A-l> → <M-l>
local m_lhs = lhs:gsub("^<A%-", "<M-")
if m_lhs ~= lhs then
  map("n", m_lhs, opener_callback, {
    desc = desc .. " (Meta alias)",
    silent = true,
  })
end
```

**Why?** Some terminal emulators send Meta (`M`) instead of Alt (`A`).

---

### Extra Aliases

```lua
-- User-defined via extra_lhs config
if M.cfg.extra_lhs and M.cfg.extra_lhs[lhs] then
  for _, alt in ipairs(M.cfg.extra_lhs[lhs]) do
    map("n", alt, opener_callback, {
      desc = desc .. " (alias)",
      silent = true,
    })
  end
end
```

**Example:** German keyboard AltGr combinations.

---

## Default Extra LHS

```lua
M.cfg = {
  extra_lhs = {
    ["<A-c>"] = { "¢" },  -- AltGr-C
    ["<A-f>"] = { "đ" },  -- AltGr-F
    ["<A-l>"] = { "ł" },  -- AltGr-L
    ["<A-r>"] = { "¶" },  -- AltGr-R (German layout)
  },
}
```

---

## Integration

### With reveal_manager

```lua
-- Opener uses similar logic to reveal_manager
-- But directly calls neo-tree.command (no circular dependency)

-- If you want explicit reveal_manager integration:
local reveal_mgr = require("config.neotree.reveal_manager")
reveal_mgr.reveal_buffer(nil, position)
```

**Note:** Current implementation doesn't use reveal_manager to avoid circular deps.

---

### With cwd_sync

```lua
-- After opening, pause sync
cwd_sync.pause_sync(2000)

-- This prevents:
-- 1. User opens with <A-f>
-- 2. cwd_sync immediately re-syncs to different dir
// 3. User is confused why their manual open was overridden
```

---

### With updir

```lua
-- updir pauses for 3s, opener for 2s
-- They don't conflict (updir's pause is longer)
```

---

## Error Handling

### Command Not Available

```lua
local ok_nt, NeoCmd = pcall(require, "neo-tree.command")
if not ok_nt then
  vim.notify("[neotree.open] neo-tree.command not available", vim.log.levels.WARN)
  return nil  -- Mapping does nothing
end
```

**Fallback:** Keymap becomes a no-op if Neo-tree not loaded.

---

### Invalid Buffer Context

```lua
local ctx = utils.get_buffer_context()
-- ctx may be nil if buffer is invalid

local reveal_file = nil
local dir = nil

if ctx then
  reveal_file = ctx.file  -- Only set if valid
  dir = ctx.dir
end
```

**Behavior:** Opens at CWD root if buffer invalid (e.g., terminal, help).

---

## Performance

| Operation | Complexity | Notes |
|-----------|-------------|-------|
| Context gathering | O(1) | Simple buffer queries |
| Keymap registration | O(1) per keymap | ~12 keymaps total |
| Opener callback | O(1) | Delegates to Neo-tree |

**Total:** Negligible impact on startup/runtime.

---

## Troubleshooting

### Problem: Keymaps not working

**Diagnose:**
```lua
-- Check if registered
vim.keymap.get("n", "<A-l>")

-- Check mapping
:nmap <A-l>
```

**Solution:**
- Verify `attach_opener_mappings()` was called
- Check for mapping conflicts
- Try Meta alias (`<M-l>`)
- Check terminal key codes (`:set <F37>^[<A-l>`)

---

### Problem: Wrong position opening

**Diagnose:**
```lua
-- Check which position is requested
print("Position:", position)

-- Check Neo-tree state
local pos = utils.get_current_position()
print("Current position:", pos)
```

**Solution:**
- Neo-tree may already be open in different position
- Close Neo-tree first, then open in desired position
- Check for position conflicts in config

---

### Problem: Reveal not working

**Diagnose:**
```lua
-- Check buffer context
local ctx = utils.get_buffer_context()
print(vim.inspect(ctx))

-- Check if reveal_file is set
print("Reveal file:", opts.reveal_file)
```

**Solution:**
- Ensure buffer is valid file (not terminal, help, etc.)
- Check file exists: `vim.fn.filereadable(path)`
- Verify Neo-tree's reveal config is enabled

---

### Problem: cwd_sync overrides immediately

**Diagnose:**
```lua
-- Check pause duration
local cwd_sync = require("config.neotree.cwd_sync")
print("Paused until:", cwd_sync.S.pause_until)
print("Current:", vim.loop.now())
```

**Solution:**
- Increase pause duration (e.g., 3000ms)
- Check if cwd_sync is respecting pause
- Verify pause_sync() is called after opener

---

## Best Practices

### ✅ DO

```lua
-- Use standard positions for consistency
<A-l> → left (primary)
<A-r> → right (secondary)
<A-f> → float (temporary)

-- Add project-specific aliases
extra_lhs = {
  ["<A-l>"] = { "<leader>e" },  -- Popular alternative
}

-- Call attach once in config
config = function(_, opts)
  require("config.neotree.open").attach_opener_mappings()
end
```

---

### ❌ DON'T

```lua
-- NICHT: Konflikt mit bestehenden Mappings
<A-l> → open Neo-tree
<A-l> → LSP references  -- ❌ Konflikt!

-- NICHT: Zu viele Aliases
extra_lhs = {
  ["<A-l>"] = { "<leader>e", "<C-e>", "<F3>", ... }  -- ❌ Übertrieben
}

-- NICHT: Mehrfach attach
attach_opener_mappings()
attach_opener_mappings()  -- ❌ Doppelte Mappings
```

---

## Advanced Usage

### Custom Opener Function

```lua
-- Create custom opener with different behavior
local function make_custom_opener(position)
  return function()
    -- Custom pre-logic
    vim.notify("Opening Neo-tree...", vim.log.levels.INFO)

    -- Use standard opener
    local opener = make_neotree_opener(position)
    opener()

    -- Custom post-logic
    vim.defer_fn(function()
      vim.notify("Neo-tree ready!", vim.log.levels.INFO)
    end, 100)
  end
end
```

---

### Conditional Opening

```lua
-- Only open if current file is in project
local function smart_open(position)
  local ctx = utils.get_buffer_context()
  if not ctx then return end

  local Root = require("utils.lv_project_root")
  local root = Root.get(ctx.buf)

  if root then
    -- In project: open with reveal
    local opener = make_neotree_opener(position)
    opener()
  else
    -- Outside project: just open at CWD
    vim.cmd("Neotree " .. position)
  end
end
```

---

### Position Rotation

```lua
-- Cycle through positions with single key
local positions = { "left", "float", "right" }
local current_idx = 1

vim.keymap.set("n", "<leader>nt", function()
  local pos = positions[current_idx]
  require("config.neotree.open").make_neotree_opener(pos)()

  current_idx = (current_idx % #positions) + 1
end, { desc = "Rotate Neo-tree position" })
```

---

## Testing

```lua
describe("open", function()
  local open = require("config.neotree.open")

  it("registers all mappings", function()
    open.attach_opener_mappings()

    assert.is_not_nil(vim.keymap.get("n", "<A-l>"))
    assert.is_not_nil(vim.keymap.get("n", "<A-r>"))
    assert.is_not_nil(vim.keymap.get("n", "<A-f>"))
    assert.is_not_nil(vim.keymap.get("n", "<A-c>"))
  end)

  it("creates Meta aliases", function()
    open.attach_opener_mappings()

    assert.is_not_nil(vim.keymap.get("n", "<M-l>"))
  end)

  it("creates extra aliases", function()
    open.attach_opener_mappings({
      extra_lhs = {
        ["<A-l>"] = { "<leader>test" }
      }
    })

    assert.is_not_nil(vim.keymap.get("n", "<leader>test"))
  end)

  it("pauses cwd_sync after open", function()
    local opener = make_neotree_opener("left")
    local before = cwd_sync.S.pause_until

    opener()

    local after = cwd_sync.S.pause_until
    assert.is_true(after > before)
  end)
end)
```

---

## Changelog

### v2.0.0 (2024-01)
- ✨ Added reveal_file support
- ✨ Added dir parameter for correct starting directory
- ✨ Added cwd_sync pause integration
- 🐛 Fixed: Opening at wrong directory
- 🐛 Fixed: No reveal when opening
- ⚡ Improved: Better buffer context handling

### v1.0.0 (2023-12)
- Initial release
- Multi-position support
- AltGr aliases
- Toggle behavior

---

## See Also

- [Neo-tree Commands](https://github.com/nvim-neo-tree/neo-tree.nvim/blob/main/doc/neo-tree.txt#L567)

---
