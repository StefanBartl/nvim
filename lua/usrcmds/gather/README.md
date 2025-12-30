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
    - [CWD Scan Performance Tips](#cwd-scan-performance-tips)
  - [Safety](#safety)
  - [Usage in Setup](#usage-in-setup)
  - [Dependencies](#dependencies)
  - [See Also](#see-also)

---

## Features

- **Functions**: Detect all function definitions (top-level, local, module methods, lambda assignments)
- **Tables**: Recursively detect table assignments including nested tables like `state.win.new = {}`
- **Strings**: Collect all string literals

---

## Modes

### Buffer Mode (default)
Scans current buffer and displays results in a scratch buffer.

```vim
:GatherLua
:GatherLua %
:GatherLua buffer
```

---

### CWD Mode
Scans all Lua files in current working directory and shows results in Telescope picker.

```vim
:GatherLua cwd
```

**New in v2: Smart Confirmation Dialog**

Before scanning, you'll see a detailed analysis:

```
CWD Scan Statistics
═══════════════════════════════
📁 Directories: 45
📄 Lua files:   523
📝 Lines (est): 87,432

⏱️  Estimated time: ~6 seconds

⚠️  WARNING: Large project detected!
This scan may take considerable time.
Consider using a more specific directory.

Proceed with scan?
✓ Yes, proceed with scan
✗ No, cancel operation
```

**Statistics calculated:**
- Total Lua files found
- Unique directories
- Estimated total lines (sampled from first 50 files)
- Time estimation (~100 files/second)
- Automatic warnings for large projects (>500 files or >50,000 lines)

The picker allows:
- Navigation through all found symbols across files
- Preview with context (±5 lines)
- Jump to definition with `<CR>`

---

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

---

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

---

## Implementation Notes

### Tree-sitter Queries

- **Functions**: Comprehensive query covering 5 patterns
- **Tables**: Path reconstruction via parent traversal
- **Strings**: Simple literal matching

---

### API Usage

- Uses `nvim_set_option_value` (not deprecated `nvim_buf_set_option`)
- Proper error handling with `pcall`
- Buffer validation before operations

---

### Performance

- Lazy loading: modules loaded on demand
- Efficient queries: single tree traversal per type
- File filtering: ignores `.git`, `node_modules`, etc.
- **Smart sampling**: Estimates total lines from first 50 files only
- **Time estimation**: ~100 files/second (empirical)
- **Auto-warnings**: Alerts for projects >500 files or >50,000 lines

---

### CWD Scan Performance Tips

For large projects (>1000 files):
- Use buffer mode (`:GatherLua`) for current file
- Navigate to specific subdirectory first
- Consider excluding vendor/generated code via `.gitignore`

Typical scan times:
- Small project (50 files, 5k lines): <1 second
- Medium project (200 files, 20k lines): ~2 seconds
- Large project (500 files, 50k lines): ~5 seconds
- Very large (1000+ files): 10+ seconds (not recommended)

---

## Safety

- Type guards before all API calls
- Graceful error handling
- Invalid buffer detection
- Filetype validation (Lua only)

---

## Usage in Setup

```lua
require("usrcmds.gather").setup({
  lua = true,
})
```

---

## Dependencies

- Neovim 0.9+ (Tree-sitter)
- Telescope (for cwd mode)
- lib.hover_select (for type selection)

---

## See Also

- Architecture: `Arch&Coding-Regeln.md`
- Checklist: `Checklist.md`
- Principles: `Zentrale-Prinzipien.md`

---
