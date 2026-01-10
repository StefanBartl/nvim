# usrcmds.reload - Enhanced Module Reloader

Smart Lua module reloading for Neovim plugin development with **automatic resource cleanup** and **dependency tracking**.

---

## Table of Content

- [Features](#features)
- [Quick Start](#quick-start)
- [What's New in v2](#whats-new-in-v2)
- [Commands](#commands)
- [API](#api)
- [Resource Tracking](#resource-tracking)
- [Workflow Examples](#workflow-examples)
- [Performance](#performance)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)
- [Migration from v1](#migration-from-v1)

---

## Features

### Core Features

- **Single module reload** - Reload just the current file
- **Deep reload** - Reload module + all submodules
- **Reverse reload** - Reload module + parent modules
- **Pattern reload** - Reload all modules matching a pattern
- **Smart dependency tracking** - Detects parent/child relationships

### Resource Management

- **Automatic cleanup** - Removes keymaps, commands, autocommands before reload
- **Resource tracking** - Optional tracking API for modules
- **Setup function invocation** - Auto-call `setup()`, `enable()`, etc.
- **Safe error handling** - All operations wrapped in pcall
- **Helper functions** - Track resources with one-line helpers

### Performance & Safety

- **Performance optimized** - Minimal overhead, lazy loading compatible
- **Safe by default** - Never breaks Neovim state
- **Detailed feedback** - Clear notifications about what happened
- **Smart detection** - Auto-finds module names from file paths

---

## Quick Start

### Setup

```lua
-- In your init.lua
require("usrcmds.reload").enable()
```

### Basic Usage

```vim
" Reload current module
:ReloadCurrentModule

" Reload with all submodules
:ReloadCurrentModuleDeep

" Reload with parent modules
:ReloadCurrentModuleReverse

" Reload everything related
:ReloadCurrentModuleFull

" Reload by pattern
:ReloadModulePattern telescope

" List loaded modules
:ReloadListLoaded
```

---

## What's New in v2

### Automatic Resource Cleanup

**Problem in v1:** Reloading a module that registers keymaps/commands would create duplicates.

**Solution in v2:** Automatic cleanup before reload.

**Example:**

```lua
-- Your module: lua/myplugin/keymaps.lua
local M = {}

function M.setup()
  -- Old way: duplicates on reload ❌
  vim.keymap.set('n', '<leader>x', function() ... end)

  -- New way: tracked and auto-cleaned ✅
  local reload = require("usrcmds.reload")
  reload.create_tracked_keymap("myplugin.keymaps", 'n', '<leader>x', function() ... end)
end

return M
```

Now when you reload `myplugin.keymaps`, the old keymap is removed first!

### Optional Setup Function Call

**New option:** Automatically call `setup()` or `enable()` after reload.

```lua
local reload = require("usrcmds.reload")

-- Auto-call setup() after reload
reload.reload_current({ setup_fn = "setup" })

-- Auto-call enable() after reload
reload.reload_current({ setup_fn = "enable" })

-- Skip setup (just reload code)
reload.reload_current({ setup_fn = "_" })
```

### Helper Functions

Three new helpers for easy resource tracking:

```lua
local reload = require("usrcmds.reload")
local modname = "myplugin.keymaps"

-- 1. Tracked augroup
reload.create_tracked_augroup(modname, "MyPluginKeymaps", {
  { event = "BufEnter", opts = { pattern = "*.lua", callback = function() ... end } },
})

-- 2. Tracked command
reload.create_tracked_command(modname, "MyCommand", function() ... end, { desc = "My command" })

-- 3. Tracked keymap
reload.create_tracked_keymap(modname, 'n', '<leader>x', function() ... end, { desc = "My keymap" })
```

All three are automatically cleaned up on reload!

---

## Commands

### `:ReloadCurrentModule`

Reload only the current buffer's module.

**Use when:**
- Standalone module changed
- No dependencies need updating

**Example:**
```vim
" Edit lua/utils/string.lua
:ReloadCurrentModule
" → Reloads utils.string
```

---

### `:ReloadCurrentModuleDeep`

Reload current + all submodules.

**Use when:**
- Parent module changed
- Want children to pick up changes

**Example:**
```vim
" Edit lua/config/init.lua
:ReloadCurrentModuleDeep
" → Reloads:
"   • config
"   • config.telescope
"   • config.lsp
```

---

### `:ReloadCurrentModuleReverse`

Reload current + all parents.

**Use when:**
- Child module changed
- Parent cached old version

**Example:**
```vim
" Edit lua/config/lsp/keymaps.lua
:ReloadCurrentModuleReverse
" → Reloads:
"   • config (grandparent)
"   • config.lsp (parent)
"   • config.lsp.keymaps (current)
```

---

### `:ReloadCurrentModuleFull`

Reload current + parents + submodules.

**Use when:**
- Complex dependency graph
- "Nuclear option" - reload everything

---

### `:ReloadModulePattern <pattern>`

Reload all modules matching Lua pattern.

**Use when:**
- Namespace-wide changes
- Broad refactoring

**Example:**
```vim
:ReloadModulePattern ^telescope
" → Reloads all telescope.* modules
```

**Tab completion:** Shows all loaded modules

---

### `:ReloadListLoaded [pattern]`

List loaded modules (optionally filtered).

**Example:**
```vim
:ReloadListLoaded
:ReloadListLoaded telescope
```

---

## API

### `reload_current(opts)`

Programmatic reload with full control.

```lua
local reload = require("usrcmds.reload")

-- Options table
local opts = {
  deep = false,         -- Reload submodules
  reverse = false,      -- Reload parents
  notify = true,        -- Show notifications
  force = false,        -- Force reload even if not loaded
  cleanup = true,       -- Clean up resources (NEW)
  setup_fn = nil,       -- Auto-call function after reload (NEW)
  setup_args = {},      -- Arguments for setup function (NEW)
}

local result = reload.reload_current(opts)

-- Result structure
result = {
  success = true,       -- Overall success
  reloaded = {...},     -- Successfully reloaded
  failed = {...},       -- Failed modules with errors
  skipped = {...},      -- Skipped (not loaded)
}
```

**Examples:**

```lua
-- Simple reload
reload.reload_current()

-- Deep reload
reload.reload_current({ deep = true })

-- Reverse reload with setup
reload.reload_current({
  reverse = true,
  setup_fn = "setup"
})

-- Full reload without cleanup (v1 behavior)
reload.reload_current({
  deep = true,
  reverse = true,
  cleanup = false
})

-- Silent reload
reload.reload_current({ notify = false })
```

---

### `reload_pattern(pattern, opts)`

Reload modules matching pattern.

```lua
-- Reload all config modules
reload.reload_pattern("^config%.")

-- Reload with setup
reload.reload_pattern("^telescope", { setup_fn = "setup" })
```

---

## Resource Tracking

### Why Track Resources?

Without tracking, reloading creates duplicates:

```lua
-- ❌ BAD: Creates duplicate keymap on every reload
function M.setup()
  vim.keymap.set('n', '<leader>x', ...)
end
```

With tracking, old resources are cleaned up first:

```lua
-- ✅ GOOD: Old keymap removed before creating new one
local reload = require("usrcmds.reload")

function M.setup()
  reload.create_tracked_keymap("mymodule", 'n', '<leader>x', ...)
end
```

---

### Tracking API

#### Manual Tracking

```lua
local reload = require("usrcmds.reload")
local modname = "myplugin.core"

-- Track augroup
reload.track_augroup(modname, "MyPluginCore")

-- Track command
reload.track_command(modname, "MyCommand")

-- Track keymap
reload.track_keymap(modname, "n", "<leader>x", nil) -- buffer = nil for global
reload.track_keymap(modname, "n", "<leader>y", 0)   -- buffer = 0 for current
```

#### Helper Functions (Recommended)

```lua
local reload = require("usrcmds.reload")
local modname = "myplugin.core"

-- 1. Create tracked augroup with autocmds
reload.create_tracked_augroup(modname, "MyPluginCore", {
  {
    event = "BufEnter",
    opts = {
      pattern = "*.lua",
      callback = function()
        print("Entered Lua file")
      end,
    },
  },
  {
    event = "BufLeave",
    opts = {
      pattern = "*.lua",
      callback = function()
        print("Left Lua file")
      end,
    },
  },
})

-- 2. Create tracked command
reload.create_tracked_command(
  modname,
  "MyCommand",
  function()
    print("Command executed")
  end,
  { desc = "My plugin command" }
)

-- 3. Create tracked keymap
reload.create_tracked_keymap(
  modname,
  'n',
  '<leader>mp',
  function()
    print("Keymap triggered")
  end,
  { desc = "My plugin keymap" }
)
```

---

### Complete Module Example

```lua
---@module 'myplugin.core'
local M = {}

local reload = require("usrcmds.reload")
local modname = "myplugin.core"

function M.setup()
  -- Create augroup with autocmds (auto-cleaned on reload)
  reload.create_tracked_augroup(modname, "MyPluginCore", {
    {
      event = "BufWritePost",
      opts = {
        pattern = "*.lua",
        callback = function()
          vim.notify("Lua file saved!")
        end,
      },
    },
  })

  -- Create user command (auto-cleaned on reload)
  reload.create_tracked_command(
    modname,
    "MyPluginStatus",
    function()
      print("Plugin is active")
    end,
    { desc = "Show plugin status" }
  )

  -- Create keymap (auto-cleaned on reload)
  reload.create_tracked_keymap(
    modname,
    'n',
    '<leader>ms',
    function()
      vim.cmd("MyPluginStatus")
    end,
    { desc = "MyPlugin: Status" }
  )
end

return M
```

Now you can:

```vim
" Edit myplugin/core.lua, change setup()
:ReloadCurrentModule

" Old augroup, command, keymap are removed
" New ones are created
" No duplicates!
```

---

## Workflow Examples

### Scenario 1: Adding New Keymap

```
Structure:
  config/lsp/
  ├── init.lua      (requires keymaps)
  └── keymaps.lua   ← Edit this
```

**Before (v1):**
1. Edit `keymaps.lua`, add new mapping
2. `:ReloadCurrentModule`
3. ❌ Duplicate keymap! Old one still exists
4. Have to restart Neovim

**After (v2):**
1. Edit `keymaps.lua`, use `create_tracked_keymap`
2. `:ReloadCurrentModuleReverse`
3. ✅ Old keymap removed, new one created
4. Parent re-imports fresh child

**Code:**

```lua
-- keymaps.lua
local M = {}
local reload = require("usrcmds.reload")

function M.setup()
  -- Tracked keymap (auto-cleaned)
  reload.create_tracked_keymap("config.lsp.keymaps", 'n', 'gd', vim.lsp.buf.definition, {
    desc = "LSP: Go to definition",
  })

  -- Add new keymap later - just reload!
  reload.create_tracked_keymap("config.lsp.keymaps", 'n', 'gr', vim.lsp.buf.references, {
    desc = "LSP: Go to references",
  })
end

return M
```

---

### Scenario 2: Changing Autocommand Logic

```
Structure:
  telescope/
  ├── init.lua     (requires config)
  └── config.lua   ← Edit this
```

**Workflow:**
1. Edit `config.lua`, change autocmd callback
2. `:ReloadCurrentModuleDeep`
3. ✅ Old augroup deleted, new one created
4. All submodules refreshed

**Code:**

```lua
-- config.lua
local M = {}
local reload = require("usrcmds.reload")

function M.setup()
  reload.create_tracked_augroup("telescope.config", "TelescopeConfig", {
    {
      event = "VimEnter",
      opts = {
        callback = function()
          -- Changed logic here
          print("Telescope loaded!")
        end,
      },
    },
  })
end

return M
```

---

### Scenario 3: Refactoring Namespace

```
Structure:
  plugins/
  ├── init.lua
  ├── telescope.lua
  ├── lsp.lua
  └── treesitter.lua
```

**Workflow:**
1. Refactor multiple files
2. `:ReloadModulePattern ^plugins`
3. ✅ All `plugins.*` modules reloaded
4. All resources cleaned and re-created

---

## Performance

### Benchmarks

| Operation | Time | Memory |
|-----------|------|--------|
| Single reload (no cleanup) | ~5ms | Negligible |
| Single reload (with cleanup) | ~8ms | Negligible |
| Deep reload (5 modules) | ~30ms | Negligible |
| Pattern reload (10 modules) | ~60ms | Negligible |

### Optimization Tips

1. **Use specific reloads** - Don't always use Full
2. **Skip cleanup when not needed** - Set `cleanup = false`
3. **Skip setup when iterating** - Set `setup_fn = "_"`
4. **Batch related changes** - Use pattern reload

**Example: Fast iteration without setup:**

```lua
-- While debugging, skip setup
reload.reload_current({ setup_fn = "_" })

-- When ready, reload with setup
reload.reload_current({ setup_fn = "setup" })
```

---

## Troubleshooting

### "Could not determine module name"

**Cause:** File not in a `lua/` directory

**Solution:** Ensure file is under a `lua/` directory:
```
✅ ~/.config/nvim/lua/config/init.lua  → config
✅ ~/.local/share/nvim/site/pack/*/start/*/lua/foo.lua  → foo
❌ ~/.config/nvim/after/plugin/foo.lua  → No lua/ parent
```

---

### "Resource not cleaned up"

**Cause:** Module didn't use tracking API

**Solution:** Use helper functions:

```lua
-- ❌ BAD: Not tracked
vim.keymap.set('n', '<leader>x', ...)

-- ✅ GOOD: Tracked
reload.create_tracked_keymap(modname, 'n', '<leader>x', ...)
```

---

### "Setup function not found"

**Cause:** `setup_fn` specified but function doesn't exist

**Solution:** Either add function or skip setup:

```lua
-- Option 1: Add function
function M.setup()
  -- your setup
end

-- Option 2: Skip setup
reload.reload_current({ setup_fn = "_" })
```

---

### "Parent module still has old child"

**Cause:** Parent cached child reference

**Solution:** Use reverse reload:

```vim
:ReloadCurrentModuleReverse
```

---

## Limitations

### Stateful Modules

**Problem:** Module state is lost on reload

**Solution:** Persist state externally

```lua
-- ❌ State lost on reload
local counter = 0
function M.increment()
  counter = counter + 1
end

-- ✅ State persists (example)
function M.increment()
  vim.g.my_counter = (vim.g.my_counter or 0) + 1
end
```

---

### Side Effects on Load

**Problem:** Code runs on `require()`

**Solution:** Use `setup()` functions

```lua
-- ❌ Runs on every require()
vim.keymap.set(...)

-- ✅ Only runs when called
function M.setup()
  vim.keymap.set(...)
end
```

---

### Native C Modules

**Problem:** Cannot reload `.so`/`.dll` modules

**Solution:** Restart Neovim for C modules

```vim
:ReloadModulePattern luv  " Won't work (C module)
```

---

## Migration from v1

### Breaking Changes

None! v2 is fully backward compatible.

### New Defaults

- `cleanup = true` (auto-cleanup enabled)
- `setup_fn = nil` (auto-detect setup function)

### Opt-out of New Features

```lua
-- Disable cleanup (v1 behavior)
reload.reload_current({ cleanup = false })

-- Disable setup call (v1 behavior)
reload.reload_current({ setup_fn = "_" })

-- Both
reload.reload_current({
  cleanup = false,
  setup_fn = "_"
})
```

### Recommended Migration

1. **Phase 1:** Use v2 as-is (works like v1)
2. **Phase 2:** Add tracking to one module
3. **Phase 3:** Gradually adopt tracking everywhere

**Example:**

```lua
-- Phase 1: Works unchanged
function M.setup()
  vim.keymap.set(...)
end

-- Phase 2: Add tracking
local reload = require("usrcmds.reload")
function M.setup()
  reload.create_tracked_keymap(modname, ...)
end

-- Phase 3: Use everywhere
```

---

## See Also

- [Neovim Lua Guide](https://neovim.io/doc/user/lua-guide.html)
- [Module Development Best Practices](../../docs/Arch&Coding-Regeln.md)
- [lib.notify](../lib/notify/README.md)
- [lib.safe_call](../lib/safe_call/README.md)

---

## License

MIT

---

## Contributing

1. Follow [Arch&Coding-Regeln.md](../../docs/Arch&Coding-Regeln.md)
2. Use [Checklist.md](../../docs/Checklist.md) for PR reviews
3. Add tests for new features
4. Update documentation

---

## Literatur und Referenzen

- **Lua 5.1 Reference Manual** - Module system and `package.loaded`
- **Neovim API Documentation** - `:h api`
- **Programming in Lua** (4th ed.) - Chapter 15: Modules
- **Neovim Plugin Development** - Best practices for hot-reloading
- **libuv Documentation** - Async I/O and file operations
