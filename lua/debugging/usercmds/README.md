# debugging.usercmds

Inspection commands for buffers, tabs, and windows with comprehensive reporting.

## Table of content

  - [Features](#features)
  - [Quick Start](#quick-start)
  - [Commands](#commands)
    - [`:BufReport`](#bufreport)
    - [`:TabReport`](#tabreport)
    - [`:WinReport [winid]`](#winreport-winid)
  - [API](#api)
    - [`collect_win_report(winid)`](#collect_win_reportwinid)
  - [Dependencies](#dependencies)
    - [Required](#required)
    - [Optional](#optional)
  - [Integration](#integration)
    - [With views module](#with-views-module)
    - [Programmatic Access](#programmatic-access)
  - [Troubleshooting](#troubleshooting)
    - [BufReport / TabReport not available](#bufreport-tabreport-not-available)
    - [Invalid window ID](#invalid-window-id)
    - [Window variables empty](#window-variables-empty)
  - [See Also](#see-also)

---

## Features

- ✅ **Buffer inspection** - Lists all buffers with filetype, buftype, state
- ✅ **Tab inspection** - Shows tab structure with windows
- ✅ **Window inspection** - Detailed window configuration and options
- ✅ **Safe API calls** - All operations wrapped in pcall
- ✅ **Structured output** - Both textual and raw data formats

---

## Quick Start

```lua
require("debugging.usercmds").attach()
```

```vim
:BufReport          " List all buffers
:TabReport          " List all tabs
:WinReport          " Current window info
:WinReport 1000     " Window 1000 info
```

---

## Commands

### `:BufReport`

Prints comprehensive buffer report to `:messages`.

**Information Included:**
- Buffer ID
- Buffer name (file path)
- Filetype
- Buftype (normal, terminal, quickfix, etc.)
- Loaded status
- Modified status
- Listed status

**Example Output:**
```
=== Buffer Report ===
[1] init.lua
  Filetype: lua
  Buftype:
  Loaded: true
  Modified: false

[2] [No Name]
  Filetype:
  Buftype: nofile
  Loaded: true
  Modified: true
```

**Usage:**
```vim
:BufReport
```

---

### `:TabReport`

Prints tab report to `:messages`.

**Information Included:**
- Tab numbers
- Windows per tab
- Current tab indicator
- Window IDs per tab

**Example Output:**
```
=== Tab Report ===
Tab 1 (current)
  Windows: 1000, 1001, 1002

Tab 2
  Windows: 1003
```

**Usage:**
```vim
:TabReport
```

---

### `:WinReport [winid]`

Prints detailed window report to `:messages`.

**Information Included:**
- Window ID
- Buffer ID and name
- Cursor position
- Window options (number, wrap, cursorline, etc.)
- Window variables (custom tags, state)
- Window configuration (floating, size, z-index)

**Example Output:**
```
=== Window Report: 1000 ===
Valid: true
Buffer: 5
  Name: /path/to/file.lua
  Filetype: lua
  Buftype:
Cursor: [10, 5]
Window Options:
  number: true
  wrap: false
  cursorline: true
  winbar:
Window Variables:
  custom_tag: messages
Window Config:
  Relative: editor
  Width: full
  Height: full
  Focusable: true
```

**Usage:**
```vim
:WinReport          " Current window
:WinReport 1000     " Window ID 1000
```

---

## API

### `collect_win_report(winid)`

Collects comprehensive window information.

**Parameters:**
- `winid` (integer|nil): Window ID (default: current window)

**Returns:**
- `{ textual: string[], raw: table }`
  - `textual`: Array of formatted strings for display
  - `raw`: Structured data for programmatic access

**Example:**
```lua
local usercmds = require("debugging.usercmds")

-- This is an internal function, but can be used if needed
local report = usercmds.collect_win_report(1000)

-- Print report
for _, line in ipairs(report.textual) do
  print(line)
end

-- Access raw data
print("Window ID:", report.raw.winid)
print("Buffer ID:", report.raw.bufnr)
print("Filetype:", report.raw.filetype)
```

---

## Dependencies

### Required
None - module is self-contained.

### Optional
- `lib.buf_win_tab.windows_utils` - For enhanced BufReport
- `lib.buf_win_tab.tabs_utils` - For enhanced TabReport

If these libraries are not available, `:BufReport` and `:TabReport` will not be registered, but `:WinReport` will always work.

---

## Integration

### With views module

Window reports integrate seamlessly with debug views:

```lua
-- Get window tag
:WinReport
-- Output shows:
-- Window Variables:
--   custom_tag: messages
```

### Programmatic Access

```lua
-- Get all window IDs
local wins = vim.api.nvim_list_wins()

-- Report each window
for _, win in ipairs(wins) do
  vim.cmd("WinReport " .. win)
end
```

---

## Troubleshooting

### BufReport / TabReport not available

**Symptom:** Commands not found

**Cause:** Optional dependencies missing

**Solution:**
```bash
# Check if libraries are installed
:checkhealth debugging
```

If lib.buf_win_tab.* is missing, only `:WinReport` is available.

### Invalid window ID

**Symptom:** "Invalid window ID: X" error

**Cause:** Window no longer exists or wrong ID provided

**Solution:**
```vim
" List all valid windows
:lua print(vim.inspect(vim.api.nvim_list_wins()))

" Use valid window ID
:WinReport 1000
```

### Window variables empty

**Symptom:** "Window Variables:" section empty

**Cause:** Window has no custom variables set

**This is normal** - not all windows have custom variables. Debug views set `custom_tag`, but normal editor windows typically don't.

---

## See Also

- [Main README](../../docs/README.md)
- `:h debugging-usercmds`
- [views/README.md](../views/README.md) - For window tagging integration

---
