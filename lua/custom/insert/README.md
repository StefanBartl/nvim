# custom.insert

Unified insertion command interface for Neovim that provides quick access to various text insertion operations under a single `:Insert` command.

## Table of content

- [custom.insert](#custominsert)
  - [Quick Start](#quick-start)
  - [Features](#features)
  - [Available Subcommands](#available-subcommands)
  - [Subcommand Reference](#subcommand-reference)
    - [:Insert filepath](#insert-filepath)
    - [:Insert module](#insert-module)
    - [:Insert class](#insert-class)
    - [:Insert function](#insert-function)
    - [:Insert timestamp](#insert-timestamp)
    - [:Insert uuid](#insert-uuid)
    - [:Insert boilerplate](#insert-boilerplate)
  - [Configuration](#configuration)
  - [Legacy Commands](#legacy-commands)
  - [Keymaps](#keymaps)
  - [Architecture](#architecture)
  - [See Also](#see-also)
  - [License](#license)

---

## Quick Start

```lua
require("custom.insert").setup({
  enable_legacy_commands = true,
})
```

```vim
" Insert current file path as Lua module
:Insert filepath lua

" Insert @module annotation
:Insert module

" Insert ISO timestamp
:Insert timestamp iso

" Insert UUID
:Insert uuid

" Insert Lua module template
:Insert boilerplate lua-module
```

## Features

* **File Paths**: Insert buffer path in various formats (relative, absolute, Lua module)
* **Annotations**: Insert EmmyLua annotations (@module, @class, @param, @return)
* **Timestamps**: Insert dates and times in multiple formats
* **UUIDs**: Generate and insert UUIDs in different styles
* **Boilerplate**: Insert common code templates

## Available Subcommands

| Subcommand | Purpose | Example |
|------------|---------|---------|
| `filepath` | Insert file paths | `:Insert filepath cwd lua` |
| `module` | Insert @module annotation | `:Insert module` |
| `class` | Insert @class annotation | `:Insert class MyClass` |
| `function` | Insert function annotation | `:Insert function` |
| `timestamp` | Insert timestamps | `:Insert timestamp iso` |
| `uuid` | Insert UUIDs | `:Insert uuid compact` |
| `boilerplate` | Insert code templates | `:Insert boilerplate lua-class MyClass` |

## Subcommand Reference

### :Insert filepath

Insert current buffer's file path at cursor.

**Syntax:**
```vim
:Insert filepath [mode] [format] [depth]
```

**Modes:**
* `cwd` (default): Relative to current working directory
* `abs`, `absolute`: Absolute path

**Formats:**
* `lua` (default): Lua module path (dots, no extension)
* `system`: System-native separator
* `win`, `windows`: Windows backslash
* `unix`, `linux`: Unix forward slash

**Depth:**
* Number: Folder depth (0 = filename only)
* Omit: Full path

**Examples:**
```vim
:Insert filepath              " lua/custom/insert/init.lua -> custom.insert
:Insert filepath abs unix     " /home/user/nvim/lua/custom/insert/init.lua
:Insert filepath cwd system 1 " insert\init.lua (Windows)
```

### :Insert module

Insert `@module` annotation for current Lua file.

**Requirements:**
* File must be `.lua`
* File must be in `lua/` directory

**Example:**
```lua
-- Before cursor:

-- After :Insert module:
---@module 'custom.insert.filepath.core'
```

### :Insert class

Insert `@class` annotation.

**Syntax:**
```vim
:Insert class [name]
```

Prompts for name if not provided.

**Example:**
```lua
---@class MyClass
```

### :Insert function

Insert complete function annotation block (interactive).

**Prompts:**
1. Function description
2. Parameters (name, type, description) - repeat until empty
3. Return type and description

**Example:**
```lua
---Calculate sum of two numbers
---@param a number First number
---@param b number Second number
---@return number result Sum of a and b
```

### :Insert timestamp

Insert timestamp at cursor.

**Syntax:**
```vim
:Insert timestamp [format] [--utc]
```

**Formats:**
* `iso` (default): 2025-01-07T14:30:45Z
* `iso-date`: 2025-01-07
* `iso-time`: 14:30:45
* `unix`: 1704636645
* `human`: January 07, 2025
* `short`: 2025-01-07 14:30
* `log`: [2025-01-07 14:30:45]
* `filename`: 20250107_143045

**Flags:**
* `--utc`, `-u`: Use UTC instead of local time

**Examples:**
```vim
:Insert timestamp             " 2025-01-07T14:30:45
:Insert timestamp human       " January 07, 2025
:Insert timestamp iso --utc   " 2025-01-07T14:30:45Z
:Insert timestamp filename    " 20250107_143045
```

### :Insert uuid

Insert randomly generated UUID.

**Syntax:**
```vim
:Insert uuid [format]
```

**Formats:**
* `standard` (default): 550e8400-e29b-41d4-a716-446655440000
* `compact`: 550e8400e29b41d4a716446655440000
* `upper`: 550E8400-E29B-41D4-A716-446655440000
* `braced`: {550e8400-e29b-41d4-a716-446655440000}

**Examples:**
```vim
:Insert uuid              " 550e8400-e29b-41d4-a716-446655440000
:Insert uuid compact      " 550e8400e29b41d4a716446655440000
:Insert uuid upper        " 550E8400-E29B-41D4-A716-446655440000
```

### :Insert boilerplate

Insert code templates.

**Syntax:**
```vim
:Insert boilerplate <template> [name]
```

**Templates:**
* `lua-module`: Complete Lua module skeleton
* `lua-class`: Lua class with constructor
* `lua-function`: Annotated function template
* `nvim-autocmd`: Neovim autocommand group
* `nvim-keymap`: Neovim keymap with description
* `guard-clause`: Early return guard pattern

**Examples:**
```vim
:Insert boilerplate lua-module
:Insert boilerplate lua-class MyClass
:Insert boilerplate nvim-autocmd MyGroup
```

## Configuration

```lua
require("custom.insert").setup({
  -- Keep legacy commands (:InsertFilePath, :LuaModuleAnnotations)
  enable_legacy_commands = true,

  -- Default subcommand when :Insert is called without arguments
  -- nil = show usage message
  default_subcommand = nil,
})
```

## Legacy Commands

When `enable_legacy_commands = true`:

* `:InsertFilePath [args...]` → `:Insert filepath [args...]`
* `:LuaModuleAnnotations` → `:Insert module`

## Keymaps

Suggested mappings:

```lua
-- Insert filepath as Lua module
vim.keymap.set("n", "<leader>ip", "<Cmd>Insert filepath lua<CR>", {
  desc = "Insert filepath (Lua module)"
})

-- Insert @module annotation
vim.keymap.set("n", "<leader>im", "<Cmd>Insert module<CR>", {
  desc = "Insert @module annotation"
})

-- Insert ISO timestamp
vim.keymap.set("n", "<leader>it", "<Cmd>Insert timestamp iso<CR>", {
  desc = "Insert ISO timestamp"
})

-- Insert UUID
vim.keymap.set("n", "<leader>iu", "<Cmd>Insert uuid<CR>", {
  desc = "Insert UUID"
})
```

---

## See Also

* `:h insert.txt` - Full documentation
* `custom/insert/filepath/README.md`
* `custom/insert/annotation/README.md`
* `custom/insert/timestamp/README.md`
* `custom/insert/uuid/README.md`
* `custom/insert/boilerplate/README.md`

---
