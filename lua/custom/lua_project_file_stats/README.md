# Lua Project File Statistics

Comprehensive Lua file analysis tool for code quality metrics, documentation ratios, and project insights. Works both as a CLI tool and Neovim plugin with async support.

## Features

- 📊 **Detailed Statistics**: Lines, words, comments, annotations
- 📈 **Ratio Analysis**: Comment/code ratios with deviation tracking
- 🎯 **Top-N Lists**: Identify largest files and folders
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
  },
}
```

### CLI Tool

Simply add to your PATH or run directly:

```bash
lua /path/to/lua_project_file_stats/init.lua [options]
```

## Usage

### Neovim Commands

#### `:LuaFileStats [options] [path]`

Main command with full configurability:

```vim
" Analyze current directory with all options
:LuaFileStats

" Analyze specific directory with ratios
:LuaFileStats --ratios --deviations ~/projects/myapp

" Quick top-10 files by lines
:LuaFileStats --top-files-lines-only --topn=10

" Export to file
:LuaFileStats --output=/tmp/stats.txt

" Current file only
:LuaFileStats --file=%:p
```

#### `:LuaFileStatsQuick [path]`

Quick summary (numbers only, summary table):

```vim
:LuaFileStatsQuick
:LuaFileStatsQuick ~/projects/myapp
```

#### `:LuaFileStatsRatios [path]`

Detailed ratio analysis with deviations:

```vim
:LuaFileStatsRatios
```

#### `:LuaFileStatsCurrentFile`

Analyze current buffer:

```vim
:LuaFileStatsCurrentFile
```

### CLI Usage

```bash
# Basic analysis
lua init.lua

# Specific directory
lua init.lua /path/to/project

# With ratios and deviations
lua init.lua --ratios --deviations

# Export to file
lua init.lua --output=report.txt

# Top 10 files only
lua init.lua --top-files-lines-only --topn=10
```

## Options

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

### Table Columns

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

### Ratio Metrics

| Metric | Description | Typical Range |
|--------|-------------|---------------|
| **Comm%** | Comment ratio | 15-30% |
| **Anno%** | Annotation ratio | 5-12% |
| **Doc%** | Documentation ratio (comments + annotations) | 20-40% |
| **Code%** | Code ratio | 55-75% |
| **L/File** | Average lines per file | 80-200 |
| **A/C** | Annotation/Comment ratio | 0.20-0.50 |

### Deviation Display

When `--deviations` is enabled, delta (Δ) values show how each folder differs from the global average:

```
| Folder     | Comm% | Delta  | Anno% | Delta  |
| src/core   | 25.3  | +5.8%  | 8.1   | +2.3%  |
| src/ui     | 18.2  | -1.3%  | 4.5   | -1.3%  |
```

- `+X%`: Folder exceeds global average by X%
- `-X%`: Folder is below global average by X%

## Examples

### 1. Quick Project Overview

```vim
:LuaFileStatsQuick
```

Shows total summary with absolute numbers.

### 2. Find Documentation Gaps

```vim
:LuaFileStats --ratios --deviations --fields=folders,summary
```

Identifies folders with low documentation ratios.

### 3. Identify Refactoring Candidates

```vim
:LuaFileStats --top-files-lines-only --topn=20
```

Lists 20 largest files that may benefit from splitting.

### 4. CI/CD Integration

```bash
lua init.lua --numbers-only --fields=summary --output=ci_report.txt
```

Generates machine-readable report.

### 5. Code Review Preparation

```vim
:LuaFileStatsRatios ~/projects/myapp
```

Complete analysis with ratios and deviations for team discussion.

## Configuration Ignored Directories

By default, the following directories are ignored:
- `.git`
- `debuglog`
- `docs`
- `node_modules`
- `.cache`

Modify in `utils.lua`:

```lua
M.IGNORE_DIRS = { ".git", "debuglog", "docs", "node_modules" }
```

## Architecture

### Module Structure

```
lua_project_file_stats/
├── init.lua              -- Main entry point
├── @types.lua            -- Type definitions
├── utils.lua             -- Core utilities and file analysis
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
- **Compatibility**: Works in Neovim and CLI

## Troubleshooting

### Encoding Issues

If delta symbols display incorrectly, the output uses "Delta" text instead of Unicode symbols for maximum compatibility.

### No Files Found

Check:
1. Path is correct
2. Directory contains `.lua` files
3. Files are not in ignored directories

### Neovim: Command Not Found

Ensure `setup()` was called:

```lua
require("custom.lua_project_file_stats").setup()
```

### Async Issues

Disable async execution:

```vim
:LuaFileStats --sync
```

## Performance

- **Small projects** (<100 files): <1s
- **Medium projects** (100-500 files): 1-3s
- **Large projects** (>500 files): 3-10s

Async execution keeps Neovim responsive.

## Contributing

Guidelines:
1. Follow project coding standards (see `Arch&Coding-Regeln.md`)
2. Add type annotations for all functions
3. Use error handling (pcall) for I/O operations
4. Test both CLI and Neovim modes
5. Update documentation

## License

MIT License - see project root for details.

## See Also

- `:help lua_project_file_stats` - Vim help documentation
- Project coding standards in repository root
