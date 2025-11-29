Ausführen von der Kommandozeile (im Parent-Ordner der lua_file_stats-Ordner):

lua lua_file_stats/cli.lua . --percent-only

lua lua_file_stats/cli.lua --file=lua/some/file.lua

cli.lua erweitert package.path dynamisch, sodass require("lua_file_stats.utils") funktioniert, wenn cli.lua im gleichen Verzeichnis wie den Modulen liegt.



| lua/mappings/buffer_jump.lua                                 | 74.4%   | 13.7%   | 95.3%   | 4.7%    | 68.5%   | 68.5%   | 31.5%   | 5.3%    |

bei diesr ausgabe ist die differenz zwischen 74,4 und 13,7 whitespace

```sh
- Standardausgabe:
`lua lua_file_stats.lua .`

-- Spaltenbreite anpassen:
`lua lua_file_stats.lua . --width 10`

-- Nur bestimmte Tabellen ausgeben:
`lua lua_file_stats.lua . --fields "total-files,total-folders"`
  - Mögliche Optionen: files, total-files, folders, total-folders, summary
  - Bei Angabe wird nur die ausgewählte(n) Tabellen ausgegeben.

`--percent-only` zeigt nur Prozente
`--numbers-only` nur Zahlen
 Standard = beide

-- Ausgabe umkehren:
`lua lua_file_stats.lua . --reverse`
```

# Lua File Stats

A Lua-based script for analyzing `.lua` files in a directory, generating line and word statistics, and printing results in ASCII tables with optional percentages and legends.

---

## Features

### 1. File Analysis

* Analyzes all `.lua` files in a given directory (recursively).
* Handles both inline (`--`) and block (`--[[ ... ]]`) comments.
* Detects annotations starting with `---@`.
* Counts lines and words for:

  * Total code
  * Code without comments
  * Comment lines
  * Code without annotations
  * Annotation lines
* Supports a per-file breakdown as well as aggregated folder and total statistics.

### 2. ASCII Tables

* Outputs tables for:

  * **Single File Stats** (if `--file` is specified)
  * **File Stats** (all files individually)
  * **Folder Summary** (aggregated by folder)
  * **Total Summary** (aggregated for all files)
* Columns for lines and words are shortened to:

  * Lines: `L1=Total, L2=NoComments, L3=Comments, L4=NoAnnotations, L5=Annotations`
  * Words: `W1=Total, W2=NoComments, W3=NoAnnotations, W4=Comments, W5=Annotations`
* Adjustable column width via `--colwidth=<number>` flag (default 7).
* Legends included for all tables.

### 3. Percent Display

* Supports three display modes via flags:

  * `--numbers-only` → only counts (no percentages)
  * `--percent-only` → only percentages
  * Default (`both`) → counts and percentages together

### 4. File Filtering

* Ignores specified directories by default: `.git`, `debuglog`, `docs`
* Supports specifying a single file with `--file=<path>`

### 5. Sorting and Display Order

* Default order: File stats → Folder summary → Total summary → Text summary
* Reverse order available via `--reverse` flag

### 6. Text Summary

* At the end, prints a compact textual summary:

  * Total analyzed files
  * Lines (total, without comments, comments, without annotations, annotations)
  * Words (total, without comments, comments, without annotations, annotations)

### 7. Command-line Usage

```bash
lua lua_file_stats.lua [root_dir] [--reverse] [--percent-only] [--numbers-only] [--fields=files,folders,summary] [--file=<file_path>] [--colwidth=<num>]
```

* `root_dir` → directory to scan (default is current directory)
* `--reverse` → print Total Summary first
* `--percent-only` → show only percentages
* `--numbers-only` → show only numbers
* `--fields` → comma-separated list of which tables to print (`files`, `folders`, `summary`)
* `--file` → analyze a single file
* `--colwidth` → set column width for table values

### 8. Relative Paths

* Outputs file paths relative to the current working directory for easier readability.

### 9. Customization

* Adjustable ignored directories (`IGNORE_DIRS` table)
* Flexible percent display and column widths
* Optional legends for clarity

---

## Examples

1. **Analyze all files in the current directory:**

```bash
lua lua_file_stats.lua
```

2. **Analyze a single file:**

```bash
lua lua_file_stats.lua --file=lua/config/init.lua
```

3. **Display percentages only:**

```bash
lua lua_file_stats.lua --percent-only
```

4. **Increase column width for better alignment:**

```bash
lua lua_file_stats.lua --colwidth=10
```

5. **Print only folder summary and total summary:**

```bash
lua lua_file_stats.lua --fields=folders,summary
```

---

## Legend (used in all ASCII tables)

```
Lines:
  L1 = Total
  L2 = NoComments
  L3 = Comments
  L4 = NoAnnotations
  L5 = Annotations

Words:
  W1 = Total
  W2 = NoComments
  W3 = NoAnnotations
  W4 = Comments
  W5 = Annotations
```

---

## Requirements

* Lua 5.1+ (tested on Lua 5.4)
* Windows or Linux/macOS (uses `dir` on Windows for file listing; may need adaptation for Unix with `ls`)

---

## Notes

* The script is modular; the table formatting strings and helper functions can be reused for other Lua file analysis tasks.
* Percent calculations handle division by zero gracefully.
* Designed for terminal output; supports adjustable column widths for readability.

