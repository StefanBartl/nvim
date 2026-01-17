# usrcmds.gather

Tree-sitter-based symbol gathering for Neovim buffers and projects.

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

**Output format:**
```
Functions (12)
─────────────────
15:4: M.setup
23:2: run_gatherer
45:6: format_output
...
```

Each line shows: `line:col: symbol_name`

### CWD Mode
Scans all Lua files in current working directory and shows results in scratch buffer with file paths.

```vim
:GatherLua cwd
```

**Output format:**
```
Functions (CWD: 347 matches)
─────────────────────────────────────
lua/init.lua:42:5: M.setup
lua/gather/functions.lua:18:2: scan_buffer
lua/gather/tables.lua:23:6: build_table_path
core/utils.lua:15:0: normalize_path
...
```

Each line shows: `relative_path:line:col: symbol_name`

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

**Benefits:**
- **Fast navigation**: Use standard Vim navigation (j/k, /, n/N)
- **Copy-friendly**: Easy to yank paths for external use
- **Sortable**: Can sort with `:sort` command
- **Searchable**: Use `/pattern` to filter matches
- **Persistent**: Keep buffer open while working

## Architecture

```
lua/usrcmds/gather/
├── @types.lua           # Type definitions
├── init.lua             # Command registration
└── lua/
    ├── init.lua         # Entry point with mode selection
    ├── functions.lua    # Function gatherer
    ├── tables.lua       # Table gatherer (recursive)
    ├── strings.lua      # String gatherer
    ├── scanner.lua      # CWD file scanning
    ├── confirm.lua      # CWD confirmation with stats
    └── ui.lua           # Scratch buffer creation
```

**Note:** `picker.lua` (Telescope integration) is available but not used by default. All output goes to scratch buffers for better performance and simpler navigation.

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
- **Smart sampling**: Estimates total lines from first 50 files only
- **Time estimation**: ~100 files/second (empirical)
- **Auto-warnings**: Alerts for projects >500 files or >50,000 lines

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

## Navigation in Scratch Buffer

The scratch buffer is a regular Vim buffer with additional keybindings:

| Key | Action |
|-----|--------|
| `q` | Close buffer |
| `<Esc>` | Close buffer |
| `/` | Search pattern |
| `n/N` | Next/previous match |
| `j/k` | Navigate lines |
| `:sort` | Sort results alphabetically |
| `yy` | Yank line (path + symbol) |

**Tip:** Use Vim's quickfix/location list integration:
```vim
" Copy path:line:col format for use with :cfile or :lfile
:w /tmp/gather_results.txt
:cfile /tmp/gather_results.txt
```

## Dependencies

- Neovim 0.9+ (Tree-sitter)
- lib.ui.hover_select (for type selection)

**Optional:**
- Telescope (if you want to use the picker.lua alternative)

**No external tools required** - pure Neovim/Lua implementation!

## See Also

- Architecture: `Arch&Coding-Regeln.md`
- Checklist: `Checklist.md`
- Principles: `Zentrale-Prinzipien.md`
