# usrcmds.gather

Tree-sitter-based symbol gathering for Neovim buffers and projects.

## Table of content

  - [Features](#features)
  - [Modes](#modes)
    - [Buffer Mode (default)](#buffer-mode-default)
    - [CWD Mode](#cwd-mode)
  - [Function Detection](#function-detection)
  - [Table Detection](#table-detection)
  - [Implementation Notes](#implementation-notes)
    - [Tree-sitter Queries](#tree-sitter-queries)
    - [API Usage](#api-usage)
    - [Performance](#performance)
  - [Safety](#safety)
  - [Usage in Setup](#usage-in-setup)
  - [Dependencies](#dependencies)
  - [See Also](#see-also)

---

## Features

- **Functions**: Detect all function definitions (top-level, local, module methods, lambda assignments)
- **Tables**: Recursively detect table assignments including nested tables like `state.win.new = {}`
- **Strings**: Collect all string literals

## Modes

### Buffer Mode (default)
Scans current buffer and displays results in a scratch buffer.

```vim
:GatherLua
:GatherLua %
:GatherLua buffer
```

### CWD Mode
Scans all Lua files in current working directory and shows results in Telescope picker.

```vim
:GatherLua cwd
```

The picker allows:
- Navigation through all found symbols across files
- Preview with context (±5 lines)
- Jump to definition with `<CR>`

## Function Detection

Detects all patterns:

```lua
-- Top-level declaration
function name() end

-- Local function
local function name() end

-- Module method
M.name = function() end
function M.name() end

-- Lambda assignment
local name = function() end

-- Table field
local t = {
  func = function() end
}
```

## Table Detection

Detects nested tables recursively:

```lua
-- Simple
local state = {}

-- Nested
state.win = {}
state.win.new = {}

-- All three are detected: state, state.win, state.win.new
```

## Implementation Notes

### Tree-sitter Queries

- **Functions**: Comprehensive query covering 5 patterns
- **Tables**: Path reconstruction via parent traversal
- **Strings**: Simple literal matching

### API Usage

- Uses `nvim_set_option_value` (not deprecated `nvim_buf_set_option`)
- Proper error handling with `pcall`
- Buffer validation before operations

### Performance

- Lazy loading: modules loaded on demand
- Efficient queries: single tree traversal per type
- File filtering: ignores `.git`, `node_modules`, etc.

## Safety

- Type guards before all API calls
- Graceful error handling
- Invalid buffer detection
- Filetype validation (Lua only)

## Usage in Setup

```lua
require("usrcmds.gather").setup({
  lua = true,
})
```

## Dependencies

- Neovim 0.9+ (Tree-sitter)
- Telescope (for cwd mode)
- lib.hover_select (for type selection)

## See Also

- Architecture: `Arch&Coding-Regeln.md`
- Checklist: `Checklist.md`
- Principles: `Zentrale-Prinzipien.md`
