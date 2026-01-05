# debugging.views

Unified debug views for `:messages` and Noice with window management, auto-refresh, and clipboard integration.

## Features

* **Deterministic window management** – Tags track windows across sessions
* **Auto-bottom cursor** – Always scrolls to latest message
* **Cross-platform clipboard** – Supports macOS, Linux, WSL, Windows
* **Auto-refresh** – Updates on window enter
* **File persistence** – Saves timestamped logs
* **Graceful degradation** – Works without optional dependencies
* **Configurable output dir** – Set dir for capture message files

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

| File           | Purpose                                             |
| -------------- | --------------------------------------------------- |
| `init.lua`     | Main setup and coordination                         |
| `capture.lua`  | Message capture with clipboard and file persistence |
| `display.lua`  | Window management and refresh                       |
| `utils.lua`    | Focus, cursor, validation helpers                   |
| `keymaps.lua`  | Keymap registration                                 |
| `autocmds.lua` | Auto-refresh on events                              |
| `@types.lua`   | Type definitions                                    |

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

* `"messages"` – `:messages` buffer
* `"noice_all"` – Noice all buffer
* `"noice_errors"` – Noice errors buffer

---

## Configuration

### Full Options

```lua
require("debugging.views").setup({
  keymaps = {
    enable = true,
    map = vim.keymap.set,
    prefix = "<lt>",  -- Prefix for all keymaps
  },
  autocmds = {
    enable = true,
    group_name = "DebugViewsAuto",
    auto_refresh = true,   -- Refresh on WinEnter/BufWinEnter
  },
  timings = {
    delay_messages_ms = 30,
    delay_noice_ms = 50,
    retry_delay_ms = 60,
    attempts = 3,
  },
  capture = true,                      -- enable capture commands
  output_dir = vim.fn.stdpath("config").."/docs/debug_views", -- optional custom path
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

* Deterministic focus
* Cursor at bottom line
* Auto-refresh on window enter
* Close with `q` or `<Esc>`

```vim
:DebugMessagesShow
```

### `:DebugMessagesCapture`

Captures `:messages` output and:

1. Saves to timestamped file
2. Copies to clipboard (cross-platform)
3. Notifies user of success/failure

**File Location:**

* Default: `stdpath("config")/docs/debug_views/messages-YYYYMMDD-HHMMSS.log`
* Optional custom path via `output_dir` in setup

```vim
:DebugMessagesCapture
```

### `:DebugWindowsClear`

Closes all debug windows (messages, noice_all, noice_errors).

```vim
:DebugWindowsClear
```

---

## Keymaps

Default prefix: `<leader>d`

| Key     | Action                    | Command                 |
| ------- | ------------------------- | ----------------------- |
| `<lt>m` | Messages view             | `:DebugMessagesShow`    |
| `<lt>n` | Noice all                 | `:Noice all`            |
| `<lt>e` | Noice errors              | `:Noice errors`         |
| `<lt>c` | Capture to file+clipboard | `:DebugMessagesCapture` |
| `<lt>x` | Clear all windows         | `:DebugWindowsClear`    |

---

## API

### `capture.capture_messages(opts)`

Captures `:messages` with options.

```lua
opts = {
  debug = false,        -- Show debug notifications
  clipboard = true,     -- Copy to clipboard
  save_file = true,     -- Save to file
  output_dir = nil,     -- Optional directory for capture files
}
```

Returns: `boolean success, string|nil content`

Example:

```lua
local capture = require("debugging.views.capture")
local ok, content = capture.capture_messages({ debug = true, output_dir = vim.fn.stdpath("config").."/docs/debug_views_custom" })
if ok then
  print("Captured " .. #content .. " bytes")
end
```

---

### `display.execute_and_refresh(tag, cmd, timings)`

Executes command and manages window state.

* `tag` (string): Window tag ("messages", "noice_all", "noice_errors")
* `cmd` (string): Command to execute (":messages", ":Noice all")
* `timings` (table): Timing configuration

```lua
local display = require("debugging.views.display")
display.execute_and_refresh("messages", "messages", {
  attempts = 3,
  retry_delay_ms = 60,
})
```

---

### `utils.focus_and_bottom(win, attempts, retry_delay)`

Focuses window and moves cursor to bottom.

* `win` (integer): Window ID
* `attempts` (integer): Max retry attempts
* `retry_delay` (integer): Delay between retries (ms)

```lua
local utils = require("debugging.views.utils")
utils.focus_and_bottom(1000, 3, 60)
```

---

## Platform Support

### Clipboard Providers

| Platform | Provider         | Installed?                 |
| -------- | ---------------- | -------------------------- |
| macOS    | `pbcopy`         | Built-in                   |
| Wayland  | `wl-copy`        | Install: `wl-clipboard`    |
| X11      | `xclip` / `xsel` | Install: `xclip` or `xsel` |
| WSL      | `clip.exe`       | Built-in                   |
| Windows  | `clip.exe`       | Built-in                   |

**Fallback Chain:**

1. `vim.fn.setreg("+")`
2. Platform-specific command (pbcopy, wl-copy, xclip, xsel, clip.exe)
3. Warning notification if all fail

---

## Troubleshooting

### Clipboard not working

Install OS-specific clipboard provider:

```bash
# Wayland
sudo apt install wl-clipboard

# X11
sudo apt install xclip
# or
sudo apt install xsel
```

### Window not focusing

Check if window is focusable:

```lua
local win = vim.api.nvim_get_current_win()
local config = vim.api.nvim_win_get_config(win)
print(config.focusable)  -- Should be true
```

### Auto-refresh not working

Enable auto-refresh:

```lua
require("debugging.views").setup({
  autocmds = { auto_refresh = true },
})
```

---

## Performance

* **Debouncing**: Refresh events debounced to avoid thrashing
* **Validation**: Early returns if windows/buffers invalid
* **Async**: Cursor-at-bottom retries use `vim.defer_fn`
* **Caching**: Window registry avoids repeated searches

---

## See Also

* [Main README](../..README.md)
* `:h debugging-views`
* [Architecture Guidelines](../../../docs/Arch&Coding-Regeln.md)

---
