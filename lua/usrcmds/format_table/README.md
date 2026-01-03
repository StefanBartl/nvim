# Markdown Table Formatter

A Neovim plugin module that formats Markdown tables with configurable alignment for headers and entries.

## Table of content

  - [Features](#features)
  - [Installation](#installation)
    - [Using lazy.nvim](#using-lazynvim)
    - [Manual Setup](#manual-setup)
  - [Usage](#usage)
    - [Basic Command](#basic-command)
    - [With Alignment Arguments](#with-alignment-arguments)
    - [Example Transformation](#example-transformation)
  - [Command Arguments](#command-arguments)
  - [Configuration](#configuration)
    - [Default Setup](#default-setup)
    - [Available Options](#available-options)
  - [Alignment Behavior](#alignment-behavior)
    - [Left Alignment](#left-alignment)
    - [Center Alignment](#center-alignment)
    - [Right Alignment](#right-alignment)
  - [Separator Style Detection](#separator-style-detection)
    - [Compact Style](#compact-style)
    - [Spaced Style](#spaced-style)
  - [Error Handling](#error-handling)
  - [Technical Details](#technical-details)
    - [Architecture](#architecture)
    - [Key Functions](#key-functions)
      - [`parse_table_at_cursor(bufnr, cursor_line)`](#parse_table_at_cursorbufnr-cursor_line)
      - [`calculate_column_widths(rows, col_count)`](#calculate_column_widthsrows-col_count)
      - [`format_row(cells, widths, align)`](#format_rowcells-widths-align)
      - [`pad_cell(str, width, align)`](#pad_cellstr-width-align)
    - [Performance Considerations](#performance-considerations)
    - [Memory Profile](#memory-profile)
  - [Limitations](#limitations)
  - [Troubleshooting](#troubleshooting)
    - [Table not detected](#table-not-detected)
    - [Incorrect alignment](#incorrect-alignment)
    - [Command not found](#command-not-found)
  - [Changelog](#changelog)
    - [v1.0.0 (Initial Release)](#v100-initial-release)

---

## Features

- **Automatic Column Width Calculation**: Adjusts column widths based on content
- **UTF-8 Support**: Correctly handles multi-byte characters using `vim.fn.strdisplaywidth`
- **Flexible Alignment**: Configure alignment per header/entry or per command invocation
- **Separator Style Preservation**: Maintains compact (`|-----|`) or spaced (`| ----- |`) separator styles
- **Type-Safe**: Full type annotations for LSP support
- **Error Handling**: Comprehensive validation and user feedback

## Installation

### Using lazy.nvim

```lua
{
  "your-plugin",
  config = function()
    require("usrcmds.format_table").setup({
      header_align = "center",  -- "left" | "center" | "right"
      entry_align = "center",   -- "left" | "center" | "right"
    })
  end,
}
```

### Manual Setup

```lua
-- In your init.lua or after/plugin/format_table.lua
require("usrcmds.format_table").setup({
  header_align = "center",
  entry_align = "center",
})
```

## Usage

### Basic Command

Place your cursor anywhere within a Markdown table and run:

```vim
:FormatTable
```

This formats the table using default alignments (both centered).

### With Alignment Arguments

```vim
:FormatTable center left   " Center headers, left-align entries
:FormatTable left center   " Left headers, center entries
:FormatTable right right   " Right-align both headers and entries
```

### Example Transformation

**Before:**

```markdown
| Mapping-Typ      | init.lua (global) | filesystem | buffers | git_status | document_symbols | tests |
|------------------|-------------------|------------|---------|------------|------------------|-------|
| Window control   |         ✅        |      -     |    -    |     -      |         -        |   -   |
| Source switch    |         ✅        |      -     |    -    |     -      |         -        |   -   |
| File operations  |         ❌        |     ✅ | noop | noop | noop | noop |
```

**After** (`:FormatTable center center`):

```markdown
|   Mapping-Typ    | init.lua (global) | filesystem | buffers | git_status | document_symbols | tests |
|------------------|-------------------|------------|---------|------------|------------------|-------|
| Window control   |        ✅         |     -      |    -    |     -      |        -         |   -   |
| Source switch    |        ✅         |     -      |    -    |     -      |        -         |   -   |
| File operations  |        ❌         |     ✅     |  noop   |   noop    |       noop       | noop  |
```

## Command Arguments

| Argument Position | Description              | Values                    | Default  |
|-------------------|--------------------------|---------------------------|----------|
| 1                 | Header row alignment     | `left`, `center`, `right` | `center` |
| 2                 | Data rows alignment      | `left`, `center`, `right` | `center` |

## Configuration

### Default Setup

```lua
require("usrcmds.format_table").setup({
  header_align = "center",
  entry_align = "center",
})
```

### Available Options

| Option         | Type       | Default  | Description                     |
|----------------|------------|----------|---------------------------------|
| `header_align` | `string`   | `center` | Default alignment for headers   |
| `entry_align`  | `string`   | `center` | Default alignment for data rows |

Valid alignment values: `"left"`, `"center"`, `"right"`

## Alignment Behavior

### Left Alignment

```markdown
| Header       |
|--------------|
| Content      |
```

### Center Alignment

```markdown
|   Header     |
|--------------|
|   Content    |
```

### Right Alignment

```markdown
|       Header |
|--------------|
|      Content |
```

## Separator Style Detection

The formatter automatically detects and preserves your separator style:

### Compact Style

```markdown
|-----|-----|
```

### Spaced Style

```markdown
| ----- | ----- |
```

The original style is maintained in the formatted output.

## Error Handling

The module provides clear error messages for common issues:

- **Invalid alignment**: `"Invalid alignment: xyz (use left, center, or right)"`
- **Not a table**: `"Not a valid table (need at least header + separator + 1 row)"`
- **Buffer issues**: `"Invalid buffer"` or `"Failed to read buffer lines"`

## Technical Details

### Architecture

```
┌─────────────────────┐
│  User Command       │
│  :FormatTable       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Argument Parser    │
│  Validate alignment │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Table Parser       │
│  • Find boundaries  │
│  • Extract cells    │
│  • Detect style     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Formatter          │
│  • Calc widths      │
│  • Apply alignment  │
│  • Generate output  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Buffer Update      │
│  Replace lines      │
└─────────────────────┘
```

### Key Functions

#### `parse_table_at_cursor(bufnr, cursor_line)`

Scans up and down from cursor to find table boundaries, validates structure, and extracts cells.

**Returns**: `UsrCmds.FmtTbl.ParsedTable` object with:
- `start_line`: First line of table (1-indexed)
- `end_line`: Last line of table
- `rows`: Array of cell arrays
- `separator_style`: `"compact"` or `"spaced"`
- `col_count`: Number of columns

#### `calculate_column_widths(rows, col_count)`

Iterates all cells to determine maximum display width per column using `vim.fn.strdisplaywidth()`.

#### `format_row(cells, widths, align)`

Pads each cell to target width with specified alignment using `pad_cell()`.

#### `pad_cell(str, width, align)`

Core padding logic:
- **Left**: Content + spaces
- **Right**: Spaces + content
- **Center**: Floor(padding/2) + content + remaining padding

### Performance Considerations

- **Single-pass width calculation**: O(rows × cols)
- **No redundant allocations**: Reuses string buffers via `table.concat`
- **Safe API calls**: All Neovim API calls wrapped in `pcall`
- **UTF-8 aware**: Uses `vim.fn.strdisplaywidth` for accurate width calculation

### Memory Profile

- Temporary table allocations: O(rows × cols)
- No persistent state between invocations
- Immediate garbage collection of parsed data

## Limitations

1. **Cursor must be within table**: The command uses cursor position to detect table boundaries
2. **Minimum structure required**: At least header + separator + one data row
3. **No column-specific alignment**: Alignment is global per row type (header vs. entries)
4. **Single table per invocation**: Does not format multiple tables simultaneously

## Troubleshooting

### Table not detected

**Problem**: "Not a valid table" error

**Solution**: Ensure table has:
- Opening and closing `|` on each line
- A separator row with dashes (e.g., `|-----|`)
- At least one data row after separator

### Incorrect alignment

**Problem**: Columns appear misaligned after formatting

**Solution**: Check for:
- Hidden characters (tabs, non-breaking spaces)
- Inconsistent column counts across rows
- UTF-8 characters (should work, but verify with `:set list`)

### Command not found

**Problem**: `:FormatTable` not recognized

**Solution**: Ensure `setup()` was called:

```lua
require("usrcmds.format_table").setup()
```

## Changelog

### v1.0.0 (Initial Release)

- Core table formatting functionality
- Configurable header/entry alignment
- Separator style detection and preservation
- UTF-8 support
- Comprehensive error handling

---

**Maintained by**: [Your Name]
**Issues**: [Link to issue tracker]
**Documentation**: [Link to extended docs]

---
