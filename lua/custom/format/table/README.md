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
* **Table Formatting**: Format Markdown tables with per-role and per-column alignment control, across cursor / buffer / cwd / file scopes
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

| Subcommand  | Purpose                        | Arguments                                          |
|-------------|--------------------------------|----------------------------------------------------|
| `column`    | Align character to column      | `<col> [fill_char]`                                |
| `table`     | Format Markdown table(s)       | `[ALIGN] [header=ALIGN] [cell=ALIGN] [skip=COLS] [scope=SCOPE]` |
| `textwidth` | Reflow text to width           | `<N\|max>`                                         |
| `filter`    | Filter lines by pattern        | `[--remove] <pattern> ...`                         |
| `trim`      | Remove trailing whitespace     | none                                               |
| `sort`      | Sort lines                     | `[-r] [-i] [-n]`                                   |
| `unique`    | Remove duplicate lines         | `[-i]`                                             |
| `case`      | Change case                    | `<upper\|lower\|title\|sentence>`                  |
| `indent`    | Fix indentation                | `[--spaces\|--tabs] [width]`                       |
| `clear`     | Clear buffer content           | none                                               |

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

Formats one or more Markdown tables with configurable per-role and per-column alignment.

**Syntax:**
```vim
:Format table [ALIGN] [header=ALIGN] [cell=ALIGN] [skip=COLS] [scope=SCOPE]
```

**Arguments:**

| Argument | Description | Values | Default |
|---|---|---|---|
| `ALIGN` (positional) | Set alignment for **both** header and cells | `left` \| `center` \| `right` | — |
| `ALIGN ALIGN` (positional) | First = header, second = cells | `left` \| `center` \| `right` | — |
| `header=ALIGN` | Header row alignment (key-value, takes precedence) | `left` \| `center` \| `right` | `center` |
| `cell=ALIGN` | Data row alignment (key-value, takes precedence) | `left` \| `center` \| `right` | `center` |
| `skip=COLS` | Columns excluded from cell alignment, pinned to `left` | Comma-separated names or 1-based indices | — |
| `scope=SCOPE` | Where to apply formatting | `cursor` \| `buffer` \| `cwd` \| `<path>` | `cursor` |

**Scope values:**

| Value | Effect |
|---|---|
| `cursor` | Only the table the cursor is currently inside (default) |
| `buffer` | Every table in the current buffer |
| `cwd` | Every `*.md` file under `vim.fn.getcwd()` — writes to disk |
| `<path>` | A specific file path (absolute or relative to cwd) |

**Examples:**
```vim
" Center both headers and cells (default)
:Format table

" Left-align EVERYTHING — header AND cells (v2 fix: one arg = both roles)
:Format table left

" Center headers, left-align cells (two positional args)
:Format table center left

" Explicit key-value syntax — mix freely
:Format table header=center cell=left

" Center cells, but keep 'Beschreibung' column left-aligned
:Format table center skip=Beschreibung

" Center cells, skip columns 3 and 'Notes'
:Format table center skip=3,Notes

" Format all tables in the current buffer
:Format table center left scope=buffer

" Format all *.md files under the project root (writes to disk)
:Format table left scope=cwd

" Format a specific file
:Format table center scope=~/project/docs/api.md
```

**Features:**
* Automatic column width calculation
* UTF-8 character support via `vim.fn.strdisplaywidth`
* Preserves separator style (compact `|---|` or spaced `| --- |`)
* Per-column alignment exceptions via `skip=` or Lua API `col_overrides`
* Multi-file scope: batch-format an entire directory without opening buffers

**Bug fix (v2):**
Previously, `:Format table left` silently applied `left` only to the header while data rows stayed `center`. A single positional argument now correctly applies to **both** header and data rows.

**Requirements:**
* Cursor must be inside table (for `scope=cursor`)
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
:Format textwidth 80
:Format textwidth max
```

**Features:**
* Preserves paragraph structure
* Handles list indentation
* No hyphenation (words kept intact)
* Sets `textwidth` buffer-local option

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
:Format filter foo
:Format filter --remove TODO
:Format filter foo { "bar", "baz" }
:Format filter -r { "error", "warning" }
```

---

### :Format clear

Clears all buffer content.

```vim
:Format clear
```

Use `u` to undo immediately after.

---

## Configuration

```lua
require("custom.format").setup({
  enable_legacy_commands = true,
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
" Select = character in visual mode, then:
:Format column 40 _
" Result: key_________=value
```

### Table Formatting Workflow

```markdown
Before:
| Name | Age | Description |
|---|---|---|
| Alice | 30 | A long description |

" Cursor in table:
:Format table center skip=Description

After:
|  Name  | Age | Description        |
|--------|-----|--------------------|
| Alice  | 30  | A long description |
```

### Batch Table Formatting

```vim
" All tables in buffer
:Format table left scope=buffer

" All *.md files under cwd
:Format table center left scope=cwd
```

### Text Reflow Workflow

```vim
:Format textwidth 80
```

### Line Filtering Workflow

```vim
:Format filter --remove TODO
:Format filter function { "public", "private" }
```

---

## Architecture

```
custom/format/
├── @types.lua                  -- Central type definitions
├── init.lua                    -- Main module + command registry
├── column_align/
│   ├── @types.lua
│   └── core.lua                -- Alignment logic
├── table/
│   ├── @types.lua              -- ColOverride, Opts, Scope types
│   ├── init.lua                -- Table formatting + scope dispatch
│   └── _handler.lua            -- Argument parser + :Format registration
├── text_width/
│   ├── @types.lua
│   └── init.lua                -- Text reflow
├── filter_lines/
│   ├── @types.lua
│   └── init.lua                -- Line filtering
└── misc/
    ├── @types.lua
    └── init.lua                -- Misc utilities
```

### Command Flow

```
:Format table center skip=Description scope=buffer
    ↓
_handler.parse_args({"center", "skip=Description", "scope=buffer"})
    ↓
{ entry_align="center", col_overrides=[{col="Description",align="left"}], scope="buffer" }
    ↓
format_table.format_tables_in_scope(opts)
    ↓
format_tables_in_buffer(current_buf, opts)   -- for each table
    ↓
render_table(parsed, header_align, entry_align, override_map)
```

---

## Troubleshooting

### "Unknown subcommand" error

Check available subcommands with `:Format` (no arguments).

### Table not detected

Ensure:
* Cursor is inside table
* Table has header + separator (`|---|`) + data row
* Separator is on line 2

### `:Format table left` only aligned the header

This was a bug in v1 — update to v2. A single positional argument now applies to both header and data rows.

### `skip=` column not recognized

Column names are matched case-insensitively against the header row. Alternatively, use a 1-based index: `skip=3`.

### `scope=cwd` changed unexpected files

Run `:pwd` first. Use `scope=<path>` to target a specific file.

### Completion not working

Verify `setup()` was called:
```lua
require("custom.format").setup()
```

---

## See Also

* `:h format.txt` – Full Vim help documentation
* `custom/format/column_align/README.md` – Column alignment details
* `custom/format/table/README.md` – Table formatting details
* Source: `lua/custom/format/`
