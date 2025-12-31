# hover-select

hover-select is a small, modular Neovim helper module for displaying and selecting items in a floating window relative to the cursor position. It is intentionally minimal and designed as a building block for custom plugins or internal tools.

---

## Table of content

  - [Motivation](#motivation)
  - [Features](#features)
  - [New in v2](#new-in-v2)
  - [Architecture](#architecture)
  - [Type Definitions](#type-definitions)
  - [Configuration](#configuration)
  - [Interaction](#interaction)
  - [Advanced Options](#advanced-options)
  - [Examples](#examples)
  - [Intended Use Cases](#intended-use-cases)

---

## Motivation

Many plugins require a simple, focused selection UI without pulling in large frameworks such as Telescope, fzf, or even `vim.ui.select`. hover-select provides a lightweight, fully controllable alternative for these cases.

---

## Features

* floating window relative to cursor, window, or editor
* simple string-based item list
* callback executed on item selection
* strictly vertical navigation, horizontal movement disabled
* automatic window size calculation with minimum and maximum limits
* automatic cleanup of buffers and windows via autocommands
* dedicated highlight group for the active cursor line

---

## New in v2

### Tab/Shift-Tab Navigation

Optional keyboard navigation with Tab and Shift-Tab:

```lua
hover_select.open({
  items = items,
  on_select = callback,
  use_tab_navigation = true,  -- Enable Tab/Shift-Tab
})
```

**Behavior:**
- `<Tab>` → Move to next item (wraps to first)
- `<Shift-Tab>` → Move to previous item (wraps to last)
- When `false` (default), Tab keys remain unmapped for future multi-select features

### Auto-Width Sizing

Three modes for window width:

**1. Fixed Width (default)**
```lua
hover_select.open({
  items = items,
  on_select = callback,
  width = 40,  -- Fixed width
})
```

**2. Auto-Width to Longest Line**
```lua
hover_select.open({
  items = items,
  on_select = callback,
  auto_width = true,  -- Size to longest line
})
```
Window width adjusts to fit the longest line (up to editor width - 4).

**3. Wrap Mode**
```lua
hover_select.open({
  items = items,
  on_select = callback,
  auto_width = "wrap",  -- Enable line wrapping
})
```
Lines wrap at window boundary, compact window size.

---

## Architecture

The module is split into small, well-defined components:

* **lib.hover_select.buffer**
  Responsible for buffer creation, content updates, and buffer-local options

* **lib.hover_select.window**
  Calculates window dimensions (including auto-width), creates the floating window, and manages lifecycle cleanup

* **lib.hover_select.navigation**
  Defines keymaps for navigation, selection, and closing the UI. Supports optional Tab navigation.

* **lib.hover_select.highlight**
  Manages highlight groups for the active cursor line

* **lib.hover_select.config**
  Central location for default buffer, window, and layout configuration

* **lib.hover_select.@types**
  EmmyLua type definitions for options and internal state

---

## Type Definitions

The module ships with EmmyLua annotations intended for LuaLS, including:

* **HoverSelectOptions**
  Configuration object for items, callbacks, buffer options, window options, layout, Tab navigation, and auto-width

* **HoverSelectState**
  Internal state holding buffer and window references as well as the active item list

These definitions significantly improve autocompletion and static analysis.

---

## Configuration

Reasonable defaults are provided for:

* buffer options (nofile buffer, wipe on close, no swapfile, custom filetype)
* window-local options (cursorline enabled, no line numbers, no wrapping)
* floating window layout (border, relative positioning, z-index)
* size constraints (minimum and maximum width and height)

All options can be overridden or extended by passing custom tables, which are merged using `vim.tbl_deep_extend`.

---

## Interaction

### Default Keybindings

* **Vertical navigation**: `j`/`k`, arrow keys (standard Vim)
* **Selection**: `<CR>` (Enter) or double mouse click
* **Close**: `<Esc>` or `q`
* **Horizontal movement**: Intentionally disabled

### With Tab Navigation Enabled

* **Next item**: `<Tab>` (wraps to first)
* **Previous item**: `<Shift-Tab>` (wraps to last)

---

## Advanced Options

### Complete Options Table

```lua
---@class HoverSelectOptions
{
  items = { "Option 1", "Option 2" },  -- Required
  on_select = function(item, idx) end, -- Required

  -- Window positioning
  relative = "cursor",  -- "cursor", "win", or "editor"
  title = "Select Option",

  -- Dimensions
  width = nil,   -- Auto-calculated if not specified
  height = nil,  -- Auto-calculated based on item count

  -- Auto-width modes
  auto_width = nil,     -- Default: fixed width
  auto_width = true,    -- Size to longest line
  auto_width = "wrap",  -- Enable line wrapping

  -- Navigation
  use_tab_navigation = false,  -- Enable Tab/Shift-Tab

  -- Advanced customization
  buf_options = {},  -- Override buffer options
  win_options = {},  -- Override window options
}
```

---

## Examples

### Basic Usage

```lua
local hover_select = require("lib.hover_select")

hover_select.open({
  items = { "Option A", "Option B", "Option C" },
  on_select = function(selected, index)
    print("Selected:", selected, "at index:", index)
  end,
})
```

### With Tab Navigation and Auto-Width

```lua
hover_select.open({
  title = "Choose Action",
  items = {
    "Create new file",
    "Open existing file",
    "Delete file",
  },
  auto_width = true,  -- Size to longest line
  use_tab_navigation = true,  -- Enable Tab/Shift-Tab
  on_select = function(selected)
    -- Handle selection
  end,
})
```

### Confirmation Dialog with Wrap

```lua
hover_select.open({
  title = "Confirm",
  items = {
    "✓ Yes, proceed with this potentially long operation",
    "✗ No, cancel",
  },
  auto_width = "wrap",  -- Wrap long lines
  use_tab_navigation = true,
  on_select = function(selected)
    if selected:match("^✓") then
      -- Confirmed
    else
      -- Cancelled
    end
  end,
})
```

---

## Intended Use Cases

hover-select is aimed at plugin authors and advanced Neovim users who:

* build custom UI components
* need precise control over buffers and floating windows
* prefer minimal dependencies and clear internal structure
* want configurable width handling for various content types
* need optional keyboard-only navigation

---

## Migration from v1

### Breaking Changes

None! All v1 code continues to work unchanged.

### New Optional Parameters

```lua
-- v1 (still works)
hover_select.open({
  items = items,
  on_select = callback,
})

-- v2 (with new features)
hover_select.open({
  items = items,
  on_select = callback,
  use_tab_navigation = true,  -- Optional
  auto_width = true,           -- Optional
})
```

---

## Performance Notes

- Auto-width calculation uses `vim.fn.strdisplaywidth()` for accurate multibyte character handling
- Window dimensions are calculated once at creation
- No performance impact when using default fixed-width mode
- Tab navigation uses simple cursor manipulation (no overhead)

---

## See Also

- Example configuration: `docs/EXAMPLE-CONFIGURATION.lua`
- Help documentation: `doc/hover_select.txt`
