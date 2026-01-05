# Lua Project File Statistics

Comprehensive project analysis tool for Lua codebases and documentation files. Provides code quality metrics, documentation ratios, and project insights. Works both as a CLI tool and Neovim plugin with async support.

## Features

- 📊 **Lua Code Analysis**: Lines, words, comments, annotations with detailed ratios
- 📄 **Documentation Analysis**: Markdown, TXT, JSON files with line/word counts
- 📈 **Ratio Analysis**: Comment/code ratios with deviation tracking
- 🎯 **Top-N Lists**: Identify largest files and folders
- ⚙️ **Flexible Configuration**: Easy-to-modify defaults at top of init.lua
- ⚡ **Async Execution**: Non-blocking analysis in Neovim
- 🔧 **CLI Compatible**: Works standalone or in Neovim
- 🎨 **Multiple Display Modes**: Numbers, percentages, or both
- 💾 **File Output**: Save reports for CI/CD integration

## Installation

### Neovim Plugin

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  dir = "path/to/custom/lua_project_file_stats",
  config = function()
    require("custom.lua_project_file_stats").setup()
  end,
  cmd = {
    "LuaFileStats",
    "LuaFileStatsQuick",
    "LuaFileStatsRatios",
    "LuaFileStatsCurrentFile",
    "LuaFileStatsMisc",
  },
}
```

### CLI Tool

```bash
lua /path/to/lua_project_file_stats/init.lua [options]
```

## Configuration

### Default Behavior

Edit the `DEFAULT_CONFIG` table at the top of `init.lua` to control what gets analyzed and displayed:

```lua
local DEFAULT_CONFIG = {
  -- Analysis scope
  lua_files = true,           -- Analyze Lua source files
  misc_files = true,          -- Analyze Markdown, TXT, JSON files

  -- Output sections (Lua files)
  show_file_tables = true,    -- Detailed file-level statistics
  show_folder_tables = true,  -- Folder-level aggregates
  show_total_summary = true,  -- Total summary table

  -- Advanced analysis
  show_ratios = false,        -- Ratio analysis
  show_deviations = false,    -- Deviations from global averages
  show_top_lists = true,      -- Top-N lists

  -- Non-Lua files
  show_misc_detailed = false, -- Detailed list of misc files

  -- Display settings
  percent_mode = "both",      -- "both" | "percent" | "numbers"
  reverse_order = false,      -- Show summary first
  top_n = 25,                 -- Number of items in top-N lists
}
```

This allows you to customize default behavior without modifying core logic.

## Usage

### Neovim Commands

#### `:LuaFileStats [options] [path]`

Main command with full configurability:

```vim
" Analyze current directory (uses DEFAULT_CONFIG)
:LuaFileStats

" Analyze with ratios and deviations
:LuaFileStats --ratios --deviations ~/projects/myapp

" Only Lua files, no documentation
:LuaFileStats --no-misc

" Only documentation files with details
:LuaFileStats --misc-only --misc-detailed

" Export to file
:LuaFileStats --output=/tmp/stats.txt
```

#### `:LuaFileStatsQuick [path]`

Quick summary (numbers only):

```vim
:LuaFileStatsQuick
:LuaFileStatsQuick ~/projects/myapp
```

#### `:LuaFileStatsRatios [path]`

Detailed ratio analysis:

```vim
:LuaFileStatsRatios
```

#### `:LuaFileStatsCurrentFile`

Analyze current buffer:

```vim
:LuaFileStatsCurrentFile
```

#### `:LuaFileStatsMisc [path]`

Analyze only documentation files:

```vim
:LuaFileStatsMisc
```

### CLI Usage

```bash
# Full analysis (Lua + documentation)
lua init.lua

# Specific directory
lua init.lua /path/to/project

# Only Lua files
lua init.lua --lua-only

# Only documentation files with details
lua init.lua --misc-only --misc-detailed

# Lua files without documentation
lua init.lua --no-misc

# With ratios and deviations
lua init.lua --ratios --deviations

# Export to file
lua init.lua --output=report.txt
```

## Options

### Analysis Scope

| Flag | Description |
|------|-------------|
| `--lua-only` | Analyze only Lua files |
| `--misc-only` | Analyze only documentation files |
| `--no-misc` | Exclude documentation files |
| `--misc-detailed` | Show detailed list of documentation files |

### Display Modes

| Flag | Description |
|------|-------------|
| `--percent-only` | Show only percentages |
| `--numbers-only` | Show only absolute numbers |
| _(default)_ | Show both numbers and percentages |

### Content Options

| Flag | Description |
|------|-------------|
| `--fields=LIST` | Comma-separated: `files`, `folders`, `summary` |
| `--ratios` | Show ratio analysis |
| `--deviations` | Show deviations from global average |
| `--reverse` | Reverse output order (summary first) |

### Top-N Lists

| Flag | Description |
|------|-------------|
| `--topn=N` | Number of items in top lists (default: 25) |
| `--top-files-lines-only` | Show ONLY top files by lines |
| `--top-files-words-only` | Show ONLY top files by words |

### Single File

| Flag | Description |
|------|-------------|
| `--file=PATH` | Analyze single file |

### Output

| Flag | Description |
|------|-------------|
| `--output=FILE` | Save output to file |
| `--colwidth=N` | Table column width (default: 7) |

### Neovim-Specific

| Flag | Description |
|------|-------------|
| `--sync` | Disable async execution |

## Output Structure

### Lua Files

**Lines (L1-L5):**
- L1: Code without comments
- L2: Comment lines
- L3: Code without annotations
- L4: Annotation lines (@-tags)
- L5: Whitespace/blank lines

**Words (W1-W5):**
- W1: Words in code
- W2: Words in code without annotations
- W3: Words in comments
- W4: Words in annotations
- W5: Words in blank lines

### Documentation Files

**Summary Table:**
- File type (Markdown, TXT, JSON)
- File count
- Total lines
- Total words
- Average lines per file

**Detailed List** (with `--misc-detailed`):
- Individual file paths
- Lines per file
- Words per file

### Ratio Metrics

| Metric | Description | Typical Range |
|--------|-------------|---------------|
| **Comm%** | Comment ratio | 15-30% |
| **Anno%** | Annotation ratio | 5-12% |
| **Doc%** | Documentation ratio | 20-40% |
| **Code%** | Code ratio | 55-75% |
| **L/File** | Average lines per file | 80-200 |
| **A/C** | Annotation/Comment ratio | 0.20-0.50 |

## Examples

### 1. Full Project Analysis

```vim
:LuaFileStats
```

Analyzes both Lua and documentation files using defaults.

### 2. Find Documentation Gaps

```vim
:LuaFileStats --ratios --deviations
```

Identifies folders with low documentation ratios.

### 3. Documentation Overview

```vim
:LuaFileStatsMisc --misc-detailed
```

Lists all Markdown, TXT, and JSON files with statistics.

### 4. Code Review Preparation

```bash
lua init.lua --ratios --deviations --output=review.txt
```

Complete analysis for team discussion.

### 5. CI/CD Integration

```bash
lua init.lua --numbers-only --fields=summary --no-misc --output=ci.txt
```

Machine-readable Lua-only report.

## Architecture

### Module Structure

```
lua_project_file_stats/
├── init.lua              -- Main entry point with DEFAULT_CONFIG
├── @types.lua            -- Type definitions
├── utils.lua             -- Core utilities and file analysis
├── misc_files.lua        -- Documentation file analysis
├── prints.lua            -- Output formatting
├── usercommands.lua      -- Neovim commands
├── README.md             -- This file
└── doc/
    └── lua_project_file_stats.txt  -- Vim help
```

### Key Design Principles

- **Type Safety**: Full LuaLS annotations
- **Error Handling**: pcall wrapping for all I/O
- **Modularity**: Single Responsibility per module
- **Performance**: Async execution in Neovim
- **Configurability**: Easy-to-modify defaults
- **Compatibility**: Works in Neovim and CLI

## Ignored Directories

Default ignored directories:
- `.git`
- `debuglog`
- `docs`
- `node_modules`
- `.cache`

Modify in `utils.lua`:

```lua
M.IGNORE_DIRS = { ".git", "debuglog", "docs" }
```

## Performance

- **Small projects** (<100 files): <1s
- **Medium projects** (100-500 files): 1-3s
- **Large projects** (>500 files): 3-10s

Async execution keeps Neovim responsive.

## Troubleshooting

### No Files Found

Check:
1. Path is correct
2. Directory contains relevant files
3. Files are not in ignored directories

### Command Not Found (Neovim)

Ensure `setup()` was called:

```lua
require("custom.lua_project_file_stats").setup()
```

### Disable Async

```vim
:LuaFileStats --sync
```

## Contributing

Guidelines:
1. Follow project coding standards
2. Add type annotations for all functions
3. Use error handling (pcall) for I/O
4. Test both CLI and Neovim modes
5. Update documentation

## License

MIT License

## See Also

- `:help lua_project_file_stats` - Vim help documentation
