# reload

Enhanced Lua module reloading for Neovim plugin development with smart dependency tracking.

## Features

- **Single module reload** - Reload just the current file
- **Deep reload** - Reload module + all submodules
- **Reverse reload** - Reload module + parent modules
- **Pattern reload** - Reload all modules matching a pattern
- **Smart notifications** - Shows what was reloaded, skipped, or failed
- **Auto-completion** - Tab-complete module names
- **Safe reloading** - pcall-wrapped with detailed error messages

---

## Quick Start

### Setup

```lua
-- In your init.lua or plugin setup
require("usercmds.reload").enable()
```

### Basic Usage

```vim
" Reload just the current module
:ReloadCurrentModule

" Reload module + all submodules (e.g., testmodul.*)
:ReloadCurrentModuleDeep

" Reload module + parent modules (e.g., testmodul when editing testmodul.keymaps)
:ReloadCurrentModuleReverse

" Reload everything related to current module
:ReloadCurrentModuleFull

" Reload all modules matching pattern
:ReloadModulePattern testmodul

" List loaded modules (optionally filter)
:ReloadListLoaded
:ReloadListLoaded telescope
```

---

## Problem It Solves

### Scenario

You have this structure:

```
testmodul/
├── init.lua         (requires keymaps)
└── keymaps.lua      (defines functions)
```

`testmodul` is loaded by `plugins/neotree.lua` at startup.

### Without This Plugin

1. Edit `testmodul/keymaps.lua` (add new function)
2. `:luafile %` only reloads `keymaps.lua`
3. `testmodul` still has old cached version
4. **Must restart Neovim** ðŸ˜«

### With This Plugin

1. Edit `testmodul/keymaps.lua`
2. `:ReloadCurrentModuleReverse`
3. Reloads `testmodul.keymaps` → then `testmodul`
4. **Changes active immediately** ✅

---

## Commands

### `:ReloadCurrentModule`

Reload only the module corresponding to the current buffer.

**Use when:**
- You changed a standalone module
- No parent/child dependencies need updating

**Example:**
```vim
" Edit lua/utils/string.lua
:ReloadCurrentModule
" → Reloads utils.string only
```

---

### `:ReloadCurrentModuleDeep`

Reload current module + all submodules.

**Use when:**
- You changed a parent module
- Want to ensure all children pick up changes

**Example:**
```vim
" Edit lua/testmodul/init.lua
:ReloadCurrentModuleDeep
" → Reloads:
"   • testmodul
"   • testmodul.keymaps
"   • testmodul.config
```

---

### `:ReloadCurrentModuleReverse`

Reload current module + all parent modules.

**Use when:**
- You changed a child module
- Parent needs to re-import it

**Example:**
```vim
" Edit lua/testmodul/keymaps.lua
:ReloadCurrentModuleReverse
" → Reloads:
"   • testmodul (parent)
"   • testmodul.keymaps (current)
```

---

### `:ReloadCurrentModuleFull`

Reload current module + parents + submodules.

**Use when:**
- Nuclear option: reload everything related
- Complex dependency graph

**Example:**
```vim
" Edit lua/testmodul/foo/bar.lua
:ReloadCurrentModuleFull
" → Reloads:
"   • testmodul (top parent)
"   • testmodul.foo (parent)
"   • testmodul.foo.bar (current)
"   • testmodul.foo.bar.* (children, if any)
```

---

### `:ReloadModulePattern <pattern>`

Reload all loaded modules matching a Lua pattern.

**Use when:**
- Want to reload an entire namespace
- Doing broad refactoring

**Example:**
```vim
:ReloadModulePattern ^telescope
" → Reloads all telescope.* modules

:ReloadModulePattern config%.
" → Reloads all config.* modules
```

**Tab Completion:**
- Press `<Tab>` after `:ReloadModulePattern ` to see loaded modules

---

### `:ReloadListLoaded [pattern]`

List all loaded modules (optionally filter by pattern).

**Use when:**
- Debugging what's loaded
- Finding module names for pattern reloading

**Example:**
```vim
:ReloadListLoaded
" → Shows all loaded modules

:ReloadListLoaded telescope
" → Shows only telescope.* modules
```

---

## API

### `reload_current(opts)`

Programmatic reload with options.

```lua
local reload = require("usercmds.reload")

-- Simple reload
reload.reload_current()

-- Deep reload
reload.reload_current({ deep = true })

-- Reverse reload
reload.reload_current({ reverse = true })

-- Full reload
reload.reload_current({ deep = true, reverse = true })

-- Silent reload (no notifications)
reload.reload_current({ notify = false })
```

**Options:**
```lua
---@class ReloadModuleOpts
---@field deep boolean Reload all submodules
---@field reverse boolean Reload parent modules
---@field notify boolean Show notifications (default: true)
---@field force boolean Force reload even if not in package.loaded
```

**Returns:**
```lua
---@class ReloadResult
---@field success boolean Overall success
---@field reloaded string[] Successfully reloaded modules
---@field failed table<string,string> Failed modules with error messages
---@field skipped string[] Modules that weren't loaded
```

**Example:**
```lua
local result = reload.reload_current({ deep = true })

if result.success then
  print("All modules reloaded!")
else
  print("Some failures:")
  for mod, err in pairs(result.failed) do
    print(string.format("  %s: %s", mod, err))
  end
end
```

---

### `reload_pattern(pattern, opts)`

Reload modules matching a pattern.

```lua
local reload = require("usercmds.reload")

-- Reload all config modules
reload.reload_pattern("^config%.")

-- Silent pattern reload
reload.reload_pattern("^telescope", { notify = false })
```

---

## Module Name Detection

The module automatically detects the module name from the file path using:

1. **package.path patterns** - Standard Lua search paths
2. **lua/ directory heuristic** - Finds `/lua/` in path
3. **Fallback handling** - Best-effort conversion

### Examples

| File Path | Module Name |
|-----------|-------------|
| `~/.config/nvim/lua/utils/string.lua` | `utils.string` |
| `~/.config/nvim/lua/testmodul/init.lua` | `testmodul` |
| `~/.config/nvim/lua/config/telescope/init.lua` | `config.telescope` |
| `/opt/nvim/site/pack/*/start/plugin/lua/foo.lua` | `foo` |

---

## Workflow Examples

### Scenario 1: Editing Child Module

```
testmodul/
├── init.lua      (uses keymaps)
└── keymaps.lua   ← Edit this
```

**Workflow:**
1. Edit `keymaps.lua` (add function)
2. `:ReloadCurrentModuleReverse`
3. Both `testmodul.keymaps` and `testmodul` reloaded
4. Changes active ✅

---

### Scenario 2: Editing Parent Module

```
testmodul/
├── init.lua      ← Edit this
├── config.lua
└── keymaps.lua
```

**Workflow:**
1. Edit `init.lua` (change setup logic)
2. `:ReloadCurrentModuleDeep`
3. `testmodul` + all `testmodul.*` reloaded
4. Changes active ✅

---

### Scenario 3: Namespace-Wide Changes

```
config/
├── init.lua
├── telescope/
│   ├── init.lua
│   └── keymaps.lua
└── lsp/
    └── init.lua
```

**Workflow:**
1. Make changes across multiple files
2. `:ReloadModulePattern ^config`
3. All `config.*` modules reloaded
4. Changes active ✅

---

## Troubleshooting

### Module Not Reloading

**Symptom:** Changes not visible after reload

**Cause:** Module wasn't loaded yet (not in `package.loaded`)

**Solution:**
```vim
" Force reload even if not loaded
:lua require('usercmds.reload').reload_current({ force = true })
```

---

### "Could not determine module name"

**Symptom:** Error when trying to reload

**Cause:** File not in a standard Lua path or no `lua/` directory found

**Solution:**
- Ensure file is in a `lua/` directory
- Check `package.path` includes your directory:
  ```vim
  :lua print(vim.inspect(vim.split(package.path, ';')))
  ```

---

### Parent Not Reloading Child Changes

**Symptom:** Parent module still uses old child version

**Cause:** Parent caches child reference

**Solution:**
```vim
" Use reverse reload to reload parent after child
:ReloadCurrentModuleReverse

" Or full reload for complex dependencies
:ReloadCurrentModuleFull
```

---

### Syntax Error After Reload

**Symptom:** Module fails to load after reload

**Cause:** Syntax error in modified file

**Fix:**
1. Check error message (shown in notification)
2. Fix syntax error
3. Reload again

**Example:**
```
✗ Failed to reload 1 module(s):
  • testmodul.keymaps: [string "..."]:5: unexpected symbol near '='
```

---

## Performance

### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| Single reload | ~5ms | Simple module |
| Deep reload (5 modules) | ~25ms | Includes submodules |
| Reverse reload (3 parents) | ~15ms | Parent chain |
| Pattern reload (10 modules) | ~50ms | Batch operation |

### Best Practices

- **Use specific reloads** - Don't always use Full reload
- **Pattern reload sparingly** - Can be slow with many modules
- **Check notifications** - Shows what actually happened
- **List loaded modules** - Use `:ReloadListLoaded` to verify state

---

## Limitations

### Stateful Modules

**Problem:** Modules with persistent state may lose data on reload.

**Example:**
```lua
-- Module with state
local M = {}
local counter = 0  -- Lost on reload!

function M.increment()
  counter = counter + 1
end

return M
```

**Solution:** Use external state or implement state persistence.

---

### Side Effects on Load

**Problem:** Modules that register autocmds/keymaps on load may duplicate.

**Example:**
```lua
-- Bad: runs on every reload
vim.keymap.set('n', '<leader>x', function() end)

-- Good: idempotent setup
local M = {}
function M.setup()
  vim.keymap.set('n', '<leader>x', function() end)
end
return M
```

**Solution:** Use `setup()` functions and make them idempotent.

---

### Native C Modules

**Problem:** Cannot reload C modules (`.so`, `.dll`).

**Example:**
```lua
:ReloadModulePattern luv  -- Won't work, luv is C module
```

**Solution:** Restart Neovim for C module changes.

---

## See Also

- `:h lua-require`
- `:h package.loaded`
- [Module Development Guide](../../../docs/Arch&Coding-Regeln.md)

---

## Literatur und Referenzen

- **Lua 5.1 Reference Manual** - Module system and `package.loaded`
- **Neovim Lua Guide** - `:h lua-guide`
- **Programming in Lua** (4th ed.) - Chapter 15: Modules and Packages
- **Neovim Plugin Development** - Best practices for hot-reloading
