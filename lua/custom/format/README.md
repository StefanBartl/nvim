# custom.format

Unified formatting command interface for Neovim that consolidates various text formatting operations under a single `:Format` command with subcommands.

---

## Table of content

  - [Overview](#overview)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Command Syntax](#command-syntax)
    - [Available Subcommands](#available-subcommands)
  - [Subcommand Reference](#subcommand-reference)
    - [:Format column](#format-column)
    - [:Format table](#format-table)
    - [:Format textwidth](#format-textwidth)
    - [:Format filter](#format-filter)
    - [:Format clear](#format-clear)
  - [Configuration](#configuration)
  - [Legacy Commands](#legacy-commands)
  - [Examples](#examples)
  - [Architecture](#architecture)
  - [Troubleshooting](#troubleshooting)
  - [See Also](#see-also)

---

## Overview

This module provides a centralized interface for various formatting operations in Neovim:

* **Column Alignment**: Align characters to specific columns with fill characters
* **Table Formatting**: Format Markdown tables with configurable alignment
* **Text Width**: Reflow text to specified width
* **Line Filtering**: Keep or remove lines based on patterns
* **Buffer Clearing**: Quick buffer content clearing

All operations are accessible through the `:Format` command with intelligent completion.

---

## Installation

Add to your Neovim configuration:

```lua
require("custom.format").setup({
  enable_legacy_commands = true,  -- Keep old commands like :FormatTable
  default_subcommand = nil,       -- Optional default if no subcommand given
})
```

The setup automatically registers all subcommands and creates the `:Format` command.

---

## Usage

### Command Syntax

```vim
:Format <subcommand> [arguments...]
```

Tab completion is available for:
* Subcommand names
* Subcommand-specific arguments

### Available Subcommands

| Subcommand | Purpose | Arguments |
|------------|---------|-----------|
| `column` | Align character to column | `<col> [fill_char]` |
| `table` | Format Markdown table | `[header_align] [entry_align]` |
| `textwidth` | Reflow text to width | `<N\|max>` |
| `filter` | Filter lines by pattern | `[--remove] <pattern> ...` |
| `trim` | Remove trailing whitespace | none |
| `sort` | Sort lines | `[-r] [-i] [-n]` |
| `unique` | Remove duplicate lines | `[-i]` |
| `case` | Change case | `<upper\|lower\|title\|sentence>` |
| `indent` | Fix indentation | `[--spaces\|--tabs] [width]` |
| `clear` | Clear buffer content | none |

---

## Subcommand Reference

### :Format column

Aligns visually selected character(s) to a target column.

**Syntax:**
```vim
:Format column <target_col> [fill_char]
```

**Arguments:**
* `<target_col>`: Target column number (1-based)
* `[fill_char]`: Fill character (default: space)

**Modes:**
* Visual mode (`v`): Single line, single character
* Visual block mode (`<C-v>`): Multiple lines, same column

**Examples:**
```vim
" Interactive prompt
:Format column

" Align to column 40 with spaces
:Format column 40

" Align to column 60 with underscores
:Format column 60 _
```

**Features:**
* UTF-8 support for fill characters
* Repeat last alignment with `.` (dot command)
* Handles multi-byte characters correctly

**Limitations:**
* Target column must be greater than current position
* Fill character must have display width of 1

---

### :Format table

Formats Markdown tables with configurable alignment.

**Syntax:**
```vim
:Format table [header_align] [entry_align]
```

**Arguments:**
* `[header_align]`: Alignment for header row (`left`, `center`, `right`)
* `[entry_align]`: Alignment for data rows (`left`, `center`, `right`)
* Default: `center center`

**Examples:**
```vim
" Center both headers and entries
:Format table

" Center headers, left-align entries
:Format table center left

" Right-align everything
:Format table right right
```

**Features:**
* Automatic column width calculation
* UTF-8 character support via `vim.fn.strdisplaywidth`
* Preserves separator style (compact `|---|` or spaced `| --- |`)
* Cursor-position-based table detection

**Requirements:**
* Cursor must be inside table
* Table must have header + separator + at least one data row
* Separator must be on line 2

---

### :Format textwidth

Reflows text to specified width.

**Syntax:**
```vim
:Format textwidth <N|max>
```

**Arguments:**
* `<N>`: Target width in columns
* `max`: Use window width

**Examples:**
```vim
" Reflow to 80 columns
:Format textwidth 80

" Reflow to window width
:Format textwidth max
```

**Features:**
* Preserves paragraph structure
* Handles list indentation
* No hyphenation (words kept intact)
* Sets `textwidth` buffer-local option

**Notes:**
* Entire buffer is reflowed
* Blank lines preserved
* Simple bullet/number list detection

---

### :Format filter

Filters lines based on patterns.

**Syntax:**
```vim
:Format filter [--remove] <pattern> [<pattern>...]
```

**Arguments:**
* `[--remove]` or `[-r]`: Remove matching lines (default: keep)
* `<pattern>`: String to match (plain text, not regex)
* Multiple patterns: AND logic (all must match)
* Table patterns `{ "a", "b" }`: OR logic (any must match)

**Examples:**
```vim
" Keep lines containing 'foo'
:Format filter foo

" Remove lines containing 'TODO'
:Format filter --remove TODO

" Keep lines with 'foo' AND ('bar' OR 'baz')
:Format filter foo { "bar", "baz" }

" Remove lines with 'error' OR 'warning'
:Format filter -r { "error", "warning" }
```

**Features:**
* Plain text matching (not regex)
* Supports OR-groups via table syntax
* Safety: prevents removing all lines unintentionally

---

### :Format clear

Clears all buffer content.

**Syntax:**
```vim
:Format clear
```

**Notes:**
* No undo confirmation
* Use `u` to undo immediately after

---

### :Format trim

Removes trailing whitespace from all lines.

**Syntax:**
```vim
:Format trim
```

**Features:**
* Operates on entire buffer
* Reports number of lines modified
* Preserves empty lines

---

### :Format sort

Sorts buffer lines with optional flags.

**Syntax:**
```vim
:Format sort [-r] [-i] [-n]
```

**Flags:**
* `-r, --reverse`: Reverse sort order
* `-i, --ignore-case`: Case-insensitive sort
* `-n, --numeric`: Numeric sort (extracts leading numbers)

**Examples:**
```vim
" Alphabetical sort
:Format sort

" Reverse alphabetical
:Format sort -r

" Case-insensitive
:Format sort -i

" Numeric sort by leading numbers
:Format sort -n

" Reverse numeric
:Format sort -r -n
```

---

### :Format unique

Removes duplicate lines (keeps first occurrence).

**Syntax:**
```vim
:Format unique [-i]
```

**Flags:**
* `-i, --ignore-case`: Case-insensitive comparison

**Examples:**
```vim
" Remove exact duplicates
:Format unique

" Remove case-insensitive duplicates
:Format unique -i
```

---

### :Format case

Changes case of all buffer text.

**Syntax:**
```vim
:Format case <mode>
```

**Modes:**
* `upper`: UPPERCASE
* `lower`: lowercase
* `title`: Title Case (Each Word Capitalized)
* `sentence`: Sentence case. First letter after punctuation.

**Examples:**
```vim
" Convert to uppercase
:Format case upper

" Convert to title case
:Format case title
```

---

### :Format indent

Fixes indentation based on buffer settings or arguments.

**Syntax:**
```vim
:Format indent [--spaces|--tabs] [width]
```

**Arguments:**
* `--spaces`: Force spaces (overrides `expandtab`)
* `--tabs`: Force tabs
* `width`: Indentation width (overrides `shiftwidth`)

**Default Behavior:**
* Uses `expandtab` setting (spaces vs. tabs)
* Uses `shiftwidth` or `tabstop` for width

**Examples:**
```vim
" Fix with current settings
:Format indent

" Fix with spaces, width 4
:Format indent --spaces 4

" Fix with tabs
:Format indent --tabs
```

**Features:**
* Converts mixed indentation to consistent style
* Preserves indentation levels
* Empty lines stay empty

---

## Configuration

```lua
require("custom.format").setup({
  -- Keep legacy commands (:FormatTable, :FilterLines, etc.)
  enable_legacy_commands = true,

  -- Default subcommand when none specified
  -- nil = show usage message
  default_subcommand = nil,
})
```

---

## Legacy Commands

When `enable_legacy_commands = true`, the following commands remain available:

* `:ColumnAlignInteractive`
* `:ColumnAlignToColumn <col> [fill]`
* `:FormatTable [header] [entry]`
* `:SetTextWidth <N|max>`
* `:SetTextWidthRange <N|max>` (range command)
* `:FilterLines [--remove] <pattern> ...`
* `:BufferClear`
* `:CopyFilepathToClipboard`

These are deprecated in favor of `:Format` subcommands.

---

## Examples

### Column Alignment Workflow

```vim
" Select = character in visual mode
" Then:
:Format column 40 _

" Result: key_________=value
```

### Table Formatting Workflow

```markdown
Before:
| Name | Age | City |
|---|---|---|
| Alice | 30 | NYC |

" Place cursor in table, run:
:Format table center left

After:
|  Name  | Age  | City |
|--------|------|------|
| Alice  | 30   | NYC  |
```

### Text Reflow Workflow

```vim
" Long paragraph on one line
:Format textwidth 80

" Result: wrapped to 80 columns
```

### Line Filtering Workflow

```vim
" Remove all TODO comments
:Format filter --remove TODO

" Keep only lines with 'function' and ('public' or 'private')
:Format filter function { "public", "private" }
```

---

## Architecture

```
custom/format/
├── @types.lua              -- Central type definitions
├── init.lua                -- Main module + command registry
├── column_align/
│   ├── @types.lua
│   └── core.lua            -- Alignment logic
├── format_table/
│   ├── @types.lua
│   └── init.lua            -- Table formatting
├── format_text_width/
│   ├── @types.lua
│   └── init.lua            -- Text reflow
├── filter_lines/
│   ├── @types.lua
│   └── init.lua            -- Line filtering
└── misc/
    ├── @types.lua
    └── init.lua            -- Misc utilities
```

### Command Flow

```
:Format column 40 _
    ↓
parse_command_line()
    ↓
registry.subcommands["column"].handler({"40", "_"})
    ↓
column_align.align_to_column(40, "_")
```

### Completion Flow

```
:Format co<Tab>
    ↓
format_complete("co", ...)
    ↓
returns: ["column"]
```

---

## Troubleshooting

### "Unknown subcommand" error

**Problem:** `:Format xyz` fails

**Solution:** Check available subcommands with `:Format` (no arguments)

### Column alignment fails in visual mode

**Problem:** "Command must be executed from visual mode"

**Solution:** Enter visual mode (`v` or `<C-v>`) before running command

### Table not detected

**Problem:** "Not a valid table"

**Solution:** Ensure:
* Cursor is inside table
* Table has header + separator (`|---|`) + data row
* Separator is on line 2

### Completion not working

**Problem:** Tab completion shows nothing

**Solution:** Verify setup was called:
```lua
require("custom.format").setup()
```

---

## See Also

* `:h format.txt` - Full Vim help documentation
* `custom/format/column_align/README.md` - Column alignment details
* `custom/format/format_table/README.md` - Table formatting details
* Source: `lua/custom/format/`

---
