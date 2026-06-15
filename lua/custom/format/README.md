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
    - [:Format trim](#format-trim)
    - [:Format sort](#format-sort)
    - [:Format unique](#format-unique)
    - [:Format case](#format-case)
    - [:Format indent](#format-indent)
    - [:Format enum](#format-enum)
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
* **Enumeration**: Number whitespace-separated tokens in a visual selection
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

| Subcommand  | Purpose                             | Arguments                                              |
|-------------|-------------------------------------|--------------------------------------------------------|
| `column`    | Align character to column           | `<col> [fill_char]`                                    |
| `table`     | Format Markdown table               | `[header_align] [entry_align]`                         |
| `textwidth` | Reflow text to width                | `<N\|max>`                                             |
| `filter`    | Filter lines by pattern             | `[--remove] <pattern> ...`                             |
| `trim`      | Remove trailing whitespace          | none                                                   |
| `sort`      | Sort lines                          | `[-r] [-i] [-n]`                                       |
| `unique`    | Remove duplicate lines              | `[-i]`                                                 |
| `case`      | Change case                         | `<upper\|lower\|title\|sentence>`                      |
| `indent`    | Fix indentation                     | `[--spaces\|--tabs] [width]`                           |
| `enum`      | Enumerate tokens in selection       | `[STYLE] [sep=SEP] [start=N] [inline=true\|false]`    |
| `clear`     | Clear buffer content                | none                                                   |

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

### :Format trim

Removes trailing whitespace from all lines.

**Syntax:**
```vim
:Format trim
```

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

---

### :Format unique

Removes duplicate lines (keeps first occurrence).

**Syntax:**
```vim
:Format unique [-i]
```

---

### :Format case

Changes case of all buffer text.

**Syntax:**
```vim
:Format case <mode>
```

**Modes:** `upper` | `lower` | `title` | `sentence`

---

### :Format indent

Fixes indentation based on buffer settings or arguments.

**Syntax:**
```vim
:Format indent [--spaces|--tabs] [width]
```

---

### :Format enum

Numbers every whitespace-separated token in the current visual selection and
writes the result back to the buffer. Works in **any filetype**.

**Syntax:**
```vim
:Format enum [STYLE] [sep=SEP] [start=N] [inline=true|false]
```

**Arguments:**

| Argument         | Description                                                          | Default   |
|------------------|----------------------------------------------------------------------|-----------|
| `STYLE` (bare)   | Shorthand for `style=STYLE`                                          | `decimal` |
| `style=STYLE`    | Numbering style (see table below)                                    | `decimal` |
| `sep=SEP`        | String placed between the counter and the token (e.g. `sep=)`)      | `. `      |
| `start=N`        | Counter value for the first token (useful for continuing a list)     | `1`       |
| `inline=true`    | Force all tokens onto **one** output line                            | auto      |
| `inline=false`   | Force each token onto its **own** output line                        | auto      |

**Numbering styles (`STYLE`):**

| Style     | Output example           |
|-----------|--------------------------|
| `decimal` | `1. foo 2. bar 3. baz`   |
| `alpha`   | `a. foo b. bar c. baz`   |
| `ALPHA`   | `A. foo B. bar C. baz`   |
| `roman`   | `i. foo ii. bar iii. baz`|
| `ROMAN`   | `I. foo II. bar III. baz`|

**Inline vs. per-line output (automatic):**
* Single-line selection → tokens joined on **one** line (default)
* Multi-line selection  → each token on its **own** line (default)
* Use `inline=true` / `inline=false` to override.

**Examples:**
```vim
" Select 'Eins Zweite Drita' on one line, then:
:Format enum
" → 1. Eins 2. Zweite 3. Drita

" Alpha style
:Format enum alpha
" → a. Eins b. Zweite c. Drita

" Roman numerals with custom separator
:Format enum roman sep=)
" → i) Eins ii) Zweite iii) Drita

" Continue a list starting at 4
:Format enum start=4
" → 4. Eins 5. Zweite 6. Drita

" Force one token per output line
:Format enum inline=false
" → 1. Eins
"   2. Zweite
"   3. Drita
```

**Notes:**
* Empty lines inside a multi-line selection are ignored (they contribute no tokens).
* Leading indentation of the first selected line is preserved.
* The `sep` value is used verbatim – append a trailing space yourself if needed
  (e.g. `sep=") "` for `"1) foo"`).

---

### :Format clear

Clears all buffer content.

**Syntax:**
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

These are deprecated in favour of `:Format` subcommands.

---

## Examples

### Enum Workflow

```
Input line (visually selected):
  markdown Eins Zweite Drita

:Format enum
→ markdown 1. Eins 2. Zweite 3. Drita

:Format enum alpha sep=)
→ markdown a) Eins b) Zweite c) Drita

:Format enum roman inline=false
→ markdown
  i. Eins
  ii. Zweite
  iii. Drita
```

### Column Alignment Workflow

```vim
" Select = character in visual mode, then:
:Format column 40 _
" Result: key_________=value
```

### Table Formatting Workflow

```markdown
Before:
| Name | Age | City |
|---|---|---|
| Alice | 30 | NYC |

:Format table center left

After:
|  Name  | Age  | City |
|--------|------|------|
| Alice  | 30   | NYC  |
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
├── @types/
│   └── init.lua            -- Central type definitions
├── init.lua                -- Main module + command registry
├── column_align/
│   ├── @types.lua
│   └── core.lua
├── enum_lines/             -- NEW
│   ├── @types.lua          -- Type definitions
│   ├── core.lua            -- Pure enumeration logic + buffer API
│   └── init.lua            -- Public facade
├── table/
│   ├── @types.lua
│   ├── init.lua
│   └── _handler.lua
├── text_width/
│   └── init.lua
├── filter_lines/
│   └── init.lua
├── markdown/
│   └── ...
├── additional_features/
│   └── init.lua
└── doc/
    └── format.txt
```

---

## Troubleshooting

### "Unknown subcommand" error

Check available subcommands with `:Format` (no arguments).

### `:Format enum` – "No tokens found"

Ensure the visual selection contains at least one non-whitespace character.

### `:Format enum` outputs all on one line, but I want one per line

Add `inline=false`:
```vim
:Format enum inline=false
```

### Table not detected

Ensure cursor is inside the table, which has header + separator (`|---|`) + data row.

### Completion not working

Verify `setup()` was called:
```lua
require("custom.format").setup()
```

---

## See Also

* `:h format.txt` – Full Vim help documentation
* `custom/format/column_align/README.md` – Column alignment details
* `custom/format/enum_lines/` – Enumeration module source
* Source: `lua/custom/format/`
