# debugging

Comprehensive debugging utilities for Neovim with modular architecture.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Modules](#modules)
- [Configuration](#configuration)
- [Commands](#commands)
- [Keymaps](#keymaps)
- [Health Check](#health-check)
- [Contributing](#contributing)

---

## Overview

The `debugging` module provides a unified suite of tools for inspecting, logging, and debugging Neovim's internal state. All modules follow strict architectural guidelines with:

- ✅ Type-safe annotations
- ✅ Cross-platform compatibility
- ✅ Graceful degradation
- ✅ Modular design
- ✅ Comprehensive error handling

---

## Installation

### Using lazy.nvim

```lua
{
  dir = "path/to/your/lua/debugging",
  name = "debugging",
  config = function()
    require("debugging").setup({
      views = {},
      usercmds = true,
    })
  end,
}
```

### Manual

```lua
require("debugging").setup()
```

---

## Quick Start

```lua
-- Minimal setup
require("debugging").setup()

-- Show messages window
:DebugMessagesShow

-- Capture to file + clipboard
:DebugMessagesCapture

-- Window report
:WinReport

-- Buffer report
:BufReport

-- Tab report
:TabReport
```

---

## Modules

| Module | Purpose | Documentation |
|--------|---------|---------------|
| **views** | Unified debug views (`:messages`, Noice) | [views/README.md](views/README.md) |
| **usercmds** | Report commands (Buf/Tab/Win) | [usercmds/README.md](usercmds/README.md) |
| **vardump** | Variable inspection utility | [vardump/README.md](vardump/README.md) |
| **terminals** | Terminal debugging (keylogger) | [terminals/README.md](terminals/README.md) |
| **nvim_options** | Neovim option helpers | [nvim_options/README.md](nvim_options/README.md) |
| **markdown** | Markdown highlight debugging | [markdown/README.md](markdown/README.md) |
| **cursor** | Cursor state inspection | [cursor/README.md](cursor/README.md) |
| **autocmds** | Autocommand inspection | [autocmds/README.md](autocmds/README.md) |

---

## Configuration

### Full Example

```lua
require("debugging").setup({
  -- Unified debug views (messages, noice)
  views = {
    keymaps = {
      enable = true,
      prefix = "<leader>d",  -- <leader>dm, <leader>dn, etc.
    },
    autocmds = {
      enable = true,
      group_name = "DebugViewsAuto",
      auto_refresh = true,  -- Auto-refresh on window enter
    },
    timings = {
      delay_messages_ms = 30,
      delay_noice_ms = 50,
      retry_delay_ms = 60,
      attempts = 3,
    },
  },

  -- User commands (BufReport, TabReport, WinReport)
  usercmds = true,

  -- Legacy modules (optional)
  autocmds = {
    list_autocmds = false,
  },
  markdown = {
    inline_debug_fixed = false,
  },
  terminals = {
    keylogger = false,
  },
})
```

### Minimal Setup

```lua
require("debugging").setup()
```

---

## Commands

### Views Module

| Command | Description |
|---------|-------------|
| `:DebugMessagesShow` | Open messages window (deterministic) |
| `:DebugMessagesCapture` | Capture `:messages` to file + clipboard |
| `:DebugWindowsClear` | Close all debug windows |

### User Commands Module

| Command | Description | Example |
|---------|-------------|---------|
| `:BufReport` | Print buffer report | `:BufReport` |
| `:TabReport` | Print tab report | `:TabReport` |
| `:WinReport` | Print window report | `:WinReport` or `:WinReport 1000` |

### Legacy Commands

| Command | Description |
|---------|-------------|
| `:ListAutocmds <event> [pattern]` | List autocommands |
| `:MarkdownInlineDebugFixed` | Debug markdown highlighting |
| `:TerminalKeyLoggerStart` | Start terminal keylogging |
| `:TerminalKeyLoggerStop` | Stop terminal keylogging |

---

## Keymaps

Default prefix: `<leader>d`

| Key | Action |
|-----|--------|
| `<leader>dm` | Open messages view |
| `<leader>dn` | Open Noice all |
| `<leader>de` | Open Noice errors |
| `<leader>dc` | Capture messages to file+clipboard |
| `<leader>dx` | Clear all debug windows |

**Custom Prefix:**

```lua
require("debugging").setup({
  views = {
    keymaps = {
      prefix = "<leader>dbg",  -- Custom prefix
    },
  },
})
```

---

## Health Check

```vim
:checkhealth debugging
```

Checks:
- ✅ Clipboard providers (pbcopy, wl-copy, xclip, xsel, clip.exe)
- ✅ Library dependencies (lib.buf_win_tab.*)
- ✅ Write permissions (stdpath("state")/debug_views)

---

## Architecture

### Design Principles

1. **Modularity**: Each module is self-contained
2. **Type Safety**: Full LuaLS annotations
3. **Cross-Platform**: Works on macOS, Linux, WSL, Windows
4. **Graceful Degradation**: Missing dependencies don't break core functionality
5. **Performance**: Lazy loading, debouncing, minimal allocations

### Module Structure

```
module/
├── init.lua       # Public API
├── @types.lua     # Type definitions
├── README.md      # Documentation
└── doc/
    └── *.txt      # Vim help
```

---

## Migration Guide

### From `usrcmds.mymessages`

**Old:**
```lua
require("usrcmds.mymessages").enable_usercmds()
```

**New:**
```lua
require("debugging").setup({ views = {} })
```

### From `mappings.dbg_messages`

**Old:**
```lua
require("mappings.dbg_messages").setup({
  keymaps = { enable = true },
})
```

**New:**
```lua
require("debugging").setup({
  views = {
    keymaps = { enable = true, prefix = "<lt>" },
  },
})
```

---

## Contributing

### Adding a New Module

1. Create module directory: `lua/debugging/mymodule/`
2. Add required files:
   - `init.lua` (implementation)
   - `@types.lua` (type definitions)
   - `README.md` (documentation)
   - `doc/debugging-mymodule.txt` (vim help)
3. Register in `debugging/init.lua`
4. Add health check in `debugging/health.lua`
5. Update main README.md

### Code Guidelines

- Follow [Arch&Coding-Regeln.md](../../docs/Arch&Coding-Regeln.md)
- Use type annotations (`---@param`, `---@return`)
- Handle errors with `pcall`
- Test on multiple platforms
- Document all public APIs

---

## Troubleshooting

### Clipboard not working

**Solution:** Install a clipboard provider:
- macOS: `pbcopy` (built-in)
- Wayland: `wl-clipboard`
- X11: `xclip` or `xsel`
- WSL: `clip.exe` (built-in)

### Window not focusing

**Solution:** Check if window is marked focusable:
```lua
vim.w[win].custom_tag = "messages"
```

### Views not refreshing

**Solution:** Enable auto-refresh:
```lua
require("debugging").setup({
  views = {
    autocmds = { auto_refresh = true },
  },
})
```

---

## License

MIT

---

## See Also

- `:h debugging` - Main help file
- `:h debugging-views` - Views module
- `:h debugging-usercmds` - User commands
- [vardump/README.md](../vardump/docs/README.md) - Variable inspection

---
