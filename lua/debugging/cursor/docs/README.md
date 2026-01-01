# debugging.cursor

Cursor state inspection utilities for debugging focus, position, and window state issues.

## Features

- ✅ **Comprehensive state** - Window, buffer, cursor, mode inspection
- ✅ **Safe API calls** - All operations wrapped in pcall
- ✅ **Window enumeration** - Lists all windows with tags
- ✅ **Formatted output** - Clear, readable diagnostics

---

## Quick Start

```lua
local cursor = require("debugging.cursor.state")

-- Debug current cursor state
cursor.debug_state()
```

**Output:**
```
=== Cursor Debug State ===
Current Win ID: 1000
Win Valid: true
Buffer ID: 5
Buf Valid: true
Buf Lines: 100
Cursor Pos: {10, 5}
Mode: n
Window Tag: none

=== All Windows ===
Win 1000: tag=none
Win 1001: tag=messages
Win 1002: tag=noice_all
```

---

## Use Cases

### 1. Debug Focus Issues

When windows don't receive focus as expected:

```lua
local cursor = require("debugging.cursor.state")
cursor.debug_state()

-- Check:
-- - Current Win ID matches expected?
-- - Window is valid?
-- - Buffer is valid?
-- - Cursor position makes sense?
```

### 2. Inspect Window Tags

Find which windows have custom tags:

```lua
cursor.debug_state()

-- Output shows:
-- Win 1000: tag=none
-- Win 1001: tag=messages  ← Tagged by views module
```

### 3. Debug Cursor Position

Verify cursor is at expected position:

```lua
cursor.debug_state()

-- Check "Cursor Pos" output:
-- Cursor Pos: {row, col}
```

### 4. Verify Mode

Confirm Neovim mode state:

```lua
cursor.debug_state()

-- Modes:
-- n  = Normal
-- i  = Insert
-- v  = Visual
-- V  = Visual Line
-- ^V = Visual Block
-- c  = Command-line
-- t  = Terminal
```

---

## API

### `debug_state()`

Prints comprehensive cursor and window state to `:messages`.

**Information Included:**
- Current window ID
- Window validity
- Buffer ID and validity
- Buffer line count
- Cursor position (row, col)
- Current mode
- Window tag (if set)
- List of all windows with tags

**Example:**
```lua
local cursor = require("debugging.cursor.state")
cursor.debug_state()
```

**Usage in Commands:**
```vim
:lua require("debugging.cursor.state").debug_state()
```

---

## Output Reference

### Window Information

```
Current Win ID: 1000
```
The numeric ID of the current window.

```
Win Valid: true
```
Whether `nvim_win_is_valid(win)` returns true.

### Buffer Information

```
Buffer ID: 5
```
The buffer displayed in current window.

```
Buf Valid: true
```
Whether `nvim_buf_is_valid(buf)` returns true.

```
Buf Lines: 100
```
Total line count in buffer.

### Cursor Position

```
Cursor Pos: {10, 5}
```
Cursor position as `{row, column}` (1-indexed).

### Mode

```
Mode: n
```
Current Neovim mode:
- `n` - Normal
- `i` - Insert
- `v` - Visual (character-wise)
- `V` - Visual Line
- `<C-v>` - Visual Block
- `c` - Command-line
- `t` - Terminal
- `R` - Replace
- `s`, `S` - Select modes

### Window Tag

```
Window Tag: messages
```
Custom tag set via `vim.w[win].custom_tag` (used by views module).

### All Windows

```
=== All Windows ===
Win 1000: tag=none
Win 1001: tag=messages
Win 1002: tag=noice_all
```
Lists all windows with their custom tags.

---

## Integration

### With views module

Cursor debugging integrates with views window tagging:

```lua
-- Open messages view
:DebugMessagesShow

-- Check cursor state
:lua require("debugging.cursor.state").debug_state()

-- Output shows:
-- Window Tag: messages
```

### In Autocommands

Debug cursor state on events:

```lua
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    require("debugging.cursor.state").debug_state()
  end,
})
```

### In Keymaps

Quick cursor inspection:

```lua
vim.keymap.set("n", "<leader>dc", function()
  require("debugging.cursor.state").debug_state()
end, { desc = "Debug cursor state" })
```

---

## Troubleshooting

### "ERROR" in output

**Symptom:**
```
Buffer ID: ERROR
```

**Cause:** `pcall` failed, likely because window is invalid

**Solution:** Check if window still exists:
```lua
local wins = vim.api.nvim_list_wins()
print(vim.inspect(wins))
```

### Cursor position unexpected

**Symptom:** Cursor shows {1, 0} but visually elsewhere

**Cause:** Multiple windows displaying same buffer

**Solution:** Use `:WinReport` to check all windows:
```vim
:WinReport
```

### Window tag always "none"

**Symptom:** All windows show `tag=none`

**Cause:** Tags are only set by specific modules (like views)

**This is normal** - regular editor windows don't have tags.

### Mode shows unexpected value

**Symptom:** Mode is "n" but in insert mode

**Cause:** State captured between mode transitions

**Solution:** Check again or use `vim.api.nvim_get_mode().blocking` for more details.

---

## Performance

### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| debug_state() | ~5ms | Depends on window count |
| Single window check | ~0.5ms | Per window |

### Optimization

For frequent checks, cache window list:

```lua
-- Cache windows
local wins = vim.api.nvim_list_wins()

-- Check specific window
for _, win in ipairs(wins) do
  if vim.api.nvim_win_is_valid(win) then
    local tag = vim.w[win].custom_tag or "none"
    print(win, tag)
  end
end
```

---

## Advanced Usage

### Filter Windows by Tag

```lua
local function find_tagged_windows(tag)
  local result = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local win_tag = vim.w[win] and vim.w[win].custom_tag
      if win_tag == tag then
        table.insert(result, win)
      end
    end
  end
  return result
end

-- Find all messages windows
local msg_wins = find_tagged_windows("messages")
print(vim.inspect(msg_wins))
```

### Monitor Cursor Movement

```lua
local last_pos = { 0, 0 }

vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    if cursor[1] ~= last_pos[1] or cursor[2] ~= last_pos[2] then
      print(string.format("Cursor moved: %d,%d -> %d,%d",
        last_pos[1], last_pos[2], cursor[1], cursor[2]))
      last_pos = cursor
    end
  end,
})
```

---

## See Also

- [Main README](../../docs/README.md)
- `:h debugging-cursor`
- [views/README.md](../../views/docs/README.md) - Window tagging system
- [usercmds/README.md](../../usercmds/docs/README.md) - :WinReport command

---
