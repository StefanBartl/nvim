# LSP UserCommands - Refactored

## Table of content

  - [Usage](#usage)
    - [LspStartHere](#lspstarthere)
    - [LspStopHere](#lspstophere)
    - [LspRestartHere](#lsprestarthere)
    - [LspInfo](#lspinfo)
  - [Module Responsibilities](#module-responsibilities)
    - [`init.lua`](#initlua)
    - [`completion.lua`](#completionlua)
    - [`start.lua`](#startlua)
    - [`stop.lua`](#stoplua)
    - [`restart.lua`](#restartlua)
    - [`info.lua`](#infolua)
  - [Filetype-to-Server Mapping](#filetype-to-server-mapping)
  - [Troubleshooting](#troubleshooting)
    - [Server won't start](#server-wont-start)
    - [Completion doesn't show expected servers](#completion-doesnt-show-expected-servers)
    - [Server stops but won't restart](#server-stops-but-wont-restart)
  - [Technical Details](#technical-details)
    - [Why `{name}` instead of `name`?](#why-name-instead-of-name)
    - [Why delayed restart?](#why-delayed-restart)
    - [Why lazy-loading?](#why-lazy-loading)
  - [References](#references)

---

##  Usage

### LspStartHere
Start LSP servers for current buffer.

```vim
:LspStartHere          " Auto-detect servers for filetype
:LspStartHere lua_ls   " Start specific server
```

**Completion shows**:
1. Servers for current filetype (priority)
2. Configured servers (registry)
3. Installed Mason servers (fallback)
4. **Excludes**: Already running servers

**Example**:
- In `.lua` file: Shows `lua_ls` first
- In `.ts` file: Shows `ts_ls`, `eslint` first
- In `.md` file: Shows `marksman` first

### LspStopHere
Stop LSP servers.

```vim
:LspStopHere          " Stop all servers
:LspStopHere lua_ls   " Stop specific server
```

**Completion shows**: Only running servers

### LspRestartHere
Restart LSP servers.

```vim
:LspRestartHere          " Restart all servers
:LspRestartHere lua_ls   " Restart specific server
```

**Completion shows**: Only running servers

### LspInfo
Show detailed LSP information for current buffer.

```vim
:LspInfo
```

Displays:
- Buffer info
- Expected servers for filetype
- Running status (✓/✗)
- Attached clients + root directories

---

## Module Responsibilities

### `init.lua`
- Register all usercommands
- Delegate execution to submodules
- Lazy-load modules on demand

### `completion.lua`
- Filetype-to-server mapping
- Intelligent filtering based on:
  - Current filetype
  - Running state
  - Configured/installed servers

### `start.lua`
- Start single or multiple servers
- Auto-detect servers for filetype
- Fallback to lspconfig if needed
- **Critical fix**: Uses `{name}` array

### `stop.lua`
- Stop single or all servers
- Safe client ID handling

### `restart.lua`
- Stop + delayed start sequence
- Preserves server names
- **Critical fix**: Uses `{name}` array
- 100ms delay for cleanup

### `info.lua`
- Collect buffer/client info
- Show in floating window
- Visual status indicators

---

## Filetype-to-Server Mapping

Located in `completion.lua` and `start.lua`:

```lua
{
  lua = { "lua_ls" },
  javascript = { "ts_ls", "eslint" },
  typescript = { "ts_ls", "eslint" },
  go = { "gopls" },
  markdown = { "marksman" },
  html = { "html", "emmet_ls" },
  css = { "cssls" },
  sh = { "bashls" },
  c = { "clangd" },
  cpp = { "clangd" },
  cs = { "omnisharp" },
  zig = { "zls" },
}
```

**To add new mappings**: Edit both files and add your filetype.

---

## Troubleshooting

### Server won't start
1. Check if server is installed:
   ```vim
   :Mason
   ```

2. Check if server is configured:
   ```lua
   -- In lua/lsp/core/registry.lua
   local ACTIVE = {
     "lua_ls",
     "ts_ls",
     -- ...
   }
   ```

3. Check logs:
   ```vim
   :LspLog
   ```

### Completion doesn't show expected servers
1. Check filetype:
   ```vim
   :set filetype?
   ```

2. Update mapping in:
   - `lua/lsp/usercmds/completion.lua`
   - `lua/lsp/usercmds/start.lua`

### Server stops but won't restart
- Increase delay in `restart.lua`:
  ```lua
  vim.defer_fn(function()
    -- ...
  end, 200)  -- Increase from 100ms to 200ms
  ```

---

## Technical Details

### Why `{name}` instead of `name`?

From Neovim docs:
```lua
vim.lsp.enable({client_names})
  -- client_names: string[]
```

The API expects an **array of strings**, not a single string.

### Why delayed restart?

LSP cleanup is asynchronous. Without delay:
```
[ERROR] Client already active
```

With 100ms delay:
```
[INFO] Restarted LSP: lua_ls
```

### Why lazy-loading?

Commands are rarely used → no need to load all modules at startup.

```lua
-- Only loaded when command is executed
local commands = {
  start = function() return require("lsp.usercmds.start") end,
}
```

---

## References

- `lua/lsp/core/registry.lua` - ACTIVE servers list
- `lua/lsp/servers/` - Server configurations
- `Checklist.md` - Coding guidelines
- `:h vim.lsp.enable()` - Neovim LSP docs

---
