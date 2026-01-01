# debugging.views

Unified debug views for `:messages` and Noice with window management, auto-refresh, and clipboard integration.

## Features

- ✅ **Deterministic window management** - Tags track windows across sessions
- ✅ **Auto-bottom cursor** - Always scrolls to latest message
- ✅ **Cross-platform clipboard** - Supports macOS, Linux, WSL, Windows
- ✅ **Auto-refresh** - Updates on window enter
- ✅ **File persistence** - Saves timestamped logs
- ✅ **Graceful degradation** - Works without optional dependencies

---

## Quick Start

```lua
require("debugging.views").setup()
```

```vim
:DebugMessagesShow       " Open messages window
:DebugMessagesCapture    " Save to file + clipboard
<leader>dm               " Open messages (keymap)
<leader>dc               " Capture (keymap)
```

---

## Architecture

### Modules

| File | Purpose |
|------|---------|
| `init.lua` | Main setup and coordination |
| `capture.lua` | Message capture with clipboard |
| `display.lua` | Window management and refresh |
| `utils.lua` | Focus, cursor, validation helpers |
| `keymaps.lua` | Keymap registration |
| `autocmds.lua` | Auto-refresh on events |
| `@types.lua` | Type definitions |

### State Management

```lua
-- Window registry (display.lua)
local WINDOWS = {
  messages = nil,      -- Window ID for :messages
  noice_all = nil,     -- Window ID for Noice all
  noice_errors = nil,  -- Window ID for Noice errors
}
```

Windows are tracked via `vim.w[win].custom_tag`:
- `"messages"` - `:messages` buffer
- `"noice_all"` - Noice all buffer
- `"noice_errors"` - Noice errors buffer

---

## Configuration

### Full Options

```lua
require("debugging.views").setup({
  keymaps = {
    enable = true,
    map = vim.keymap.set,
    prefix = "<leader>d",  -- Prefix for all keymaps
  },
  autocmds = {
    enable = true,
    group_name = "DebugViewsAuto",
    auto_refresh = true,   -- Refresh on WinEnter/BufWinEnter
  },
  timings = {
    delay_messages_ms = 30,   -- Initial delay
    delay_noice_ms = 50,
    retry_delay_ms = 60,      -- Retry delay for cursor-at-bottom
    attempts = 3,             -- Max retry attempts
  },
})
```

### Minimal

```lua
require("debugging.views").setup()
```

### Disable Keymaps

```lua
require("debugging.views").setup({
  keymaps = { enable = false },
})
```

### Custom Prefix

```lua
require("debugging.views").setup({
  keymaps = { prefix = "<leader>dbg" },
})
```

---

## Commands

### `:DebugMessagesShow`

Opens `:messages` in a dedicated window with:
- Deterministic focus
- Cursor at bottom line
- Auto-refresh on window enter
- Close with `q` or `<Esc>`

**Example:**
```vim
:DebugMessagesShow
```

### `:DebugMessagesCapture`

Captures `:messages` output and:
1. Saves to timestamped file
2. Copies to clipboard (cross-platform)
3. Notifies user of success/failure

**File Location:**
- `$REPOS_DIR/debug_views/messages-YYYYMMDD-HHMMSS.log`
- Or: `stdpath("state")/debug_views/messages-YYYYMMDD-HHMMSS.log`

**Example:**
```vim
:DebugMessagesCapture
```

### `:DebugWindowsClear`

Closes all debug windows (messages, noice_all, noice_errors).

**Example:**
```vim
:DebugWindowsClear
```

---

## Keymaps

Default prefix: `<leader>d`

| Key | Action | Command |
|-----|--------|---------|
| `<leader>dm` | Messages view | `:DebugMessagesShow` |
| `<leader>dn` | Noice all | `:Noice all` |
| `<leader>de` | Noice errors | `:Noice errors` |
| `<leader>dc` | Capture to file+clipboard | `:DebugMessagesCapture` |
| `<leader>dx` | Clear all windows | `:DebugWindowsClear` |

---

## API

### `capture.capture_messages(opts)`

Captures `:messages` with options.

**Parameters:**
```lua
opts = {
  debug = false,        -- Show debug notifications
  clipboard = true,     -- Copy to clipboard
  save_file = true,     -- Save to file
  output_dir = nil,     -- Custom output directory
}
```

**Returns:** `boolean success, string|nil content`

**Example:**
```lua
local capture = require("debugging.views.capture")
local ok, content = capture.capture_messages({ debug = true })
if ok then
  print("Captured " .. #content .. " bytes")
end
```

### `display.execute_and_refresh(tag, cmd, timings)`

Executes command and manages window state.

**Parameters:**
- `tag` (string): Window tag ("messages", "noice_all", "noice_errors")
- `cmd` (string): Command to execute (":messages", ":Noice all")
- `timings` (table): Timing configuration

**Example:**
```lua
local display = require("debugging.views.display")
display.execute_and_refresh("messages", "messages", {
  attempts = 3,
  retry_delay_ms = 60,
})
```

### `utils.focus_and_bottom(win, attempts, retry_delay)`

Focuses window and moves cursor to bottom.

**Parameters:**
- `win` (integer): Window ID
- `attempts` (integer): Max retry attempts
- `retry_delay` (integer): Delay between retries (ms)

**Example:**
```lua
local utils = require("debugging.views.utils")
utils.focus_and_bottom(1000, 3, 60)
```

---

## Platform Support

### Clipboard Providers

| Platform | Provider | Installed? |
|----------|----------|------------|
| macOS | `pbcopy` | Built-in |
| Wayland | `wl-copy` | Install: `wl-clipboard` |
| X11 | `xclip` / `xsel` | Install: `xclip` or `xsel` |
| WSL | `clip.exe` | Built-in |
| Windows | `clip.exe` | Built-in |

**Fallback Chain:**
1. `vim.fn.setreg("+")` (requires system clipboard provider)
2. Platform-specific command (pbcopy, wl-copy, etc.)
3. Warning notification if all fail

---

## Troubleshooting

### Clipboard not working

**Symptom:** "clipboard not available" warning

**Solution:**
```bash
# Wayland
sudo apt install wl-clipboard

# X11
sudo apt install xclip
# or
sudo apt install xsel
```

### Window not focusing

**Symptom:** Window opens but cursor not visible

**Solution:** Check if window is focusable:
```lua
local win = vim.api.nvim_get_current_win()
local config = vim.api.nvim_win_get_config(win)
print(config.focusable)  -- Should be true
```

### Auto-refresh not working

**Symptom:** Messages window shows stale content

**Solution:** Enable auto-refresh:
```lua
require("debugging.views").setup({
  autocmds = { auto_refresh = true },
})
```

---

## Performance

### Optimizations

- **Debouncing**: Refresh events debounced to avoid thrashing
- **Validation**: Early returns if windows/buffers invalid
- **Async**: Cursor-at-bottom retries use `vim.defer_fn`
- **Caching**: Window registry avoids repeated searches

### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| Open messages | ~30ms | Includes window creation |
| Capture to file | ~50ms | Depends on message count |
| Clipboard copy | ~10ms | Platform-dependent |
| Auto-refresh | ~60ms | With 3 retry attempts |

---

## See Also

- [Main README](../../docs/README.md)
- `:h debugging-views`
- [Architecture Guidelines](../../../docs/Arch&Coding-Regeln.md)

---
