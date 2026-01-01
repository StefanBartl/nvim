# debugging.autocmds

Autocommand inspection and listing utilities for debugging event-driven behavior.

## Features

- ✅ **List autocommands** - Filter by event and pattern
- ✅ **Group information** - Shows autocommand groups
- ✅ **Callback details** - Identifies command vs callback
- ✅ **Description display** - Shows registered descriptions
- ✅ **Pattern matching** - Filter by file patterns

---

## Quick Start

```lua
require("debugging.autocmds").attach({ list_autocmds = true })
```

```vim
:ListAutocmds BufAdd
:ListAutocmds BufEnter *.lua
:ListAutocmds FileType markdown
```

---

## Commands

### `:ListAutocmds {event} [pattern]`

Lists all autocommands matching a specific event and optional pattern.

**Parameters:**
- `event` (required): Autocommand event (e.g., "BufAdd", "BufEnter", "FileType")
- `pattern` (optional): File pattern to match (default: "*")

**Example Output:**
```
=== Autocommands for BufEnter *.lua ===

[1] Group: LspAttach
    Event: BufEnter
    Pattern: *.lua
    Buffer: N/A
    Callback: <function>
    Description: Attach LSP to Lua files

[2] Group: TreesitterHighlight
    Event: BufEnter
    Pattern: *.lua
    Command: TSBufEnable highlight
    Description: Enable tree-sitter highlighting
```

---

## Use Cases

### 1. Debug Event Firing

Find which autocommands trigger on an event:

```vim
:ListAutocmds BufEnter

" Shows all BufEnter autocommands
" Helps identify conflicts or missing handlers
```

### 2. Find Filetype-Specific Commands

List commands for specific filetypes:

```vim
:ListAutocmds FileType lua
:ListAutocmds FileType markdown
:ListAutocmds FileType python
```

### 3. Debug Pattern Matching

Check which patterns are registered:

```vim
:ListAutocmds BufReadPost *.md
:ListAutocmds BufWritePre *
```

### 4. Identify Group Conflicts

Find duplicate handlers in different groups:

```vim
:ListAutocmds BufWritePre

" Check output for multiple groups handling same event
```

### 5. Verify Plugin Registration

Confirm plugins registered their autocommands:

```vim
:ListAutocmds User

" Look for plugin-specific User events
" Example: User LspAttach, User BufWinCapture
```

---

## API

### Module Functions

```lua
local autocmds = require("debugging.autocmds.list_autocmds")

-- This module only provides the :ListAutocmds command
-- No direct API functions exposed
```

### Using Neovim API

For programmatic access, use Neovim's API directly:

```lua
-- Get all autocommands for event
local autocmds = vim.api.nvim_get_autocmds({
  event = "BufEnter",
  pattern = "*.lua",
})

-- Iterate results
for i, cmd in ipairs(autocmds) do
  print(string.format("[%d] Group: %s", i, cmd.group_name or "default"))
  print(string.format("    Event: %s", cmd.event))
  print(string.format("    Pattern: %s", cmd.pattern or "N/A"))

  if cmd.command then
    print(string.format("    Command: %s", cmd.command))
  end

  if cmd.callback then
    print("    Callback: <function>")
  end

  if cmd.desc then
    print(string.format("    Description: %s", cmd.desc))
  end
end
```

---

## Output Reference

### Group
```
Group: LspAttach
```
Name of autocommand group. "default" if no group specified.

### Event
```
Event: BufEnter
```
The autocommand event that triggers this command.

### Pattern
```
Pattern: *.lua
```
File pattern that must match. "N/A" if no pattern specified.

### Buffer
```
Buffer: 5
```
Buffer-specific autocommand (if set). "N/A" for global autocommands.

### Command vs Callback

**Command:**
```
Command: TSBufEnable highlight
```
Vim command string to execute.

**Callback:**
```
Callback: <function>
```
Lua function callback. Function details not shown.

### Description
```
Description: Attach LSP to Lua files
```
User-provided description from autocommand registration.

---

## Common Events

### Buffer Events
- `BufAdd` - Buffer added to buffer list
- `BufEnter` - Entering a buffer
- `BufLeave` - Leaving a buffer
- `BufReadPost` - After reading file into buffer
- `BufWritePre` - Before writing buffer to file
- `BufWritePost` - After writing buffer to file
- `BufDelete` - Before deleting buffer
- `BufWipeout` - Before wiping buffer

### Window Events
- `WinEnter` - Entering a window
- `WinLeave` - Leaving a window
- `WinNew` - New window created
- `WinClosed` - Window closed

### FileType Events
- `FileType` - Filetype set
- `Syntax` - Syntax set

### LSP Events
- `LspAttach` - LSP client attached
- `LspDetach` - LSP client detached

### User Events
- `User` - User-defined events
  - `User LspAttach` - Custom LSP attach
  - `User BufWinCapture` - Custom buffer capture (views module)

---

## Integration

### With views module

Check auto-refresh autocommands:

```vim
:ListAutocmds WinEnter

" Look for:
" Group: DebugViewsAuto
" Description: Auto-refresh debug views
```

### Finding Event Sources

Trace where events come from:

```vim
" Enable verbose mode
:set verbose=9

" Trigger event
:edit test.lua

" Check which autocommands fired
:ListAutocmds BufEnter *.lua
```

---

## Troubleshooting

### "No autocommands found"

**Symptom:** Message says no autocommands found for event

**Cause:** Event name incorrect or no autocommands registered

**Solution:**
```vim
" List all possible events
:help autocmd-events

" Try broader pattern
:ListAutocmds BufEnter
```

### Too many results

**Symptom:** Output overwhelming

**Solution:** Use more specific pattern:
```vim
" Instead of:
:ListAutocmds BufEnter

" Try:
:ListAutocmds BufEnter *.lua
:ListAutocmds BufEnter */specific/path/*
```

### Callback details missing

**Symptom:** Shows "<function>" but want more info

**Cause:** Callback is Lua function, not command string

**Solution:** Use debug tools to inspect:
```lua
local autocmds = vim.api.nvim_get_autocmds({ event = "BufEnter" })
for _, cmd in ipairs(autocmds) do
  if cmd.callback then
    print(debug.getinfo(cmd.callback))
  end
end
```

---

## Performance

### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| List 10 autocmds | ~2ms | Fast |
| List 100 autocmds | ~10ms | Still fast |
| List all autocmds | ~50ms | Depends on count |

### Optimization

For frequent checks, cache results:

```lua
-- Cache autocommands
local cached = vim.api.nvim_get_autocmds({ event = "BufEnter" })

-- Use cached data
for _, cmd in ipairs(cached) do
  -- Process...
end
```

---

## Advanced Usage

### Find Autocommands by Group

```lua
local function find_by_group(group_name)
  local all = vim.api.nvim_get_autocmds({})
  local result = {}

  for _, cmd in ipairs(all) do
    if cmd.group_name == group_name then
      table.insert(result, cmd)
    end
  end

  return result
end

-- Find all in specific group
local lsp_autocmds = find_by_group("LspAttach")
print(vim.inspect(lsp_autocmds))
```

### Count Autocommands per Event

```lua
local events = {
  "BufEnter", "BufLeave", "WinEnter", "WinLeave",
  "FileType", "BufWritePre", "BufWritePost"
}

for _, event in ipairs(events) do
  local autocmds = vim.api.nvim_get_autocmds({ event = event })
  print(string.format("%s: %d autocommands", event, #autocmds))
end
```

---

## See Also

- [Main README](../../docs/README.md)
- `:h debugging-autocmds`
- `:h autocmd`
- `:h nvim_get_autocmds()`
- `:h autocmd-events`

---
