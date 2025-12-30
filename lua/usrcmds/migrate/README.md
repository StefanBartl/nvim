# usrcmds.migrate

Modulares Framework für Code-Migrationen in Neovim Lua-Projekten.

## Table of content

  - [Überblick](#berblick)
    - [Verfügbare Migrationen](#verfgbare-migrationen)
  - [Core Konzepte](#core-konzepte)
    - [1. Common Infrastructure](#1-common-infrastructure)
    - [2. Migration Module Structure](#2-migration-module-structure)
  - [Neues Migrations-Modul hinzufügen](#neues-migrations-modul-hinzufgen)
    - [Schritt 1: Verzeichnis-Struktur](#schritt-1-verzeichnis-struktur)
    - [Schritt 2: Types definieren (@types.lua)](#schritt-2-types-definieren-typeslua)
    - [Schritt 3: Core Logic (init.lua)](#schritt-3-core-logic-initlua)
    - [Schritt 4: Aktivierung](#schritt-4-aktivierung)
    - [Schritt 5: Dokumentation (doc/mymodule.txt)](#schritt-5-dokumentation-docmymoduletxt)
  - [Best Practices](#best-practices)
    - [Pattern Detection](#pattern-detection)
    - [Line Replacement](#line-replacement)
    - [Index-Konvertierung](#index-konvertierung)
    - [Self-Migration Prevention](#self-migration-prevention)
    - [Import Injection](#import-injection)
  - [Debugging](#debugging)
    - [Enable Debug Output](#enable-debug-output)
    - [Test Pattern Matching](#test-pattern-matching)
    - [Common Issues](#common-issues)
  - [Testing](#testing)
  - [Weitere Resourcen](#weitere-resourcen)

---

## Überblick

Das `usrcmds.migrate` Modul bietet eine wiederverwendbare Infrastruktur für automatisierte Code-Refactorings. Es ermöglicht einheitliche Migration-Tools mit konsistenter UX über verschiedene Migrations-Typen hinweg.

### Verfügbare Migrationen

- **`notify`**: Migriert `vim.notify(msg, vim.log.levels.LEVEL)` → `notify.level(msg)`
- **`opt`**: Migriert deprecated `nvim_buf/win_get/set_option` → `nvim_get/set_option_value`

## Core Konzepte

### 1. Common Infrastructure

Alle Migration-Module nutzen gemeinsame Komponenten:

**Command Handler** (`common/command.lua`):
- Einheitliche Command-Syntax über alle Migrationen
- Unterstützt: line, range, buffer (%), cwd modes
- Auto-completion für Argumente

**Picker UI** (`common/picker.lua`):
- Telescope-basierte Auswahl-UI
- Multi-select Support (`<Tab>`)
- Preview mit Syntax-Highlighting
- Batch-Apply (`<S-A>`)

**Buffer Operations** (`common/buffer.lua`):
- Sichere Line-Replacements
- File I/O Helpers
- Undo-Point Management
- Recursive File Discovery

### 2. Migration Module Structure

Jedes Migration-Modul folgt diesem Pattern:

```lua
lua/usrcmds/migrate/<name>/
├── @types.lua      # Module-specific types
├── init.lua        # Main entry point
├── parser.lua      # Pattern detection (optional)
├── refactor.lua    # Apply logic (optional)
└── doc/
    └── <name>.txt  # Help documentation
```

**Erforderliche Funktionen** in `init.lua`:

```lua
local M = {}

-- Scan-Funktionen
local function scan_range(bufnr, line1, line2)
  -- Returns: MigrateCommon.Match[]
end

local function scan_buffer(bufnr)
  -- Returns: MigrateCommon.Match[]
end

local function scan_cwd()
  -- Returns: MigrateCommon.Match[]
end

-- Apply-Funktion
local function apply_matches(matches)
  -- Applies migrations to buffers
end

-- Picker-Funktion
local function show_picker_impl(matches)
  -- Shows Telescope picker
end

-- Registration
function M.enable()
  command.register({
    name = "Migrate<Name>",
    scan_range = scan_range,
    scan_buffer = scan_buffer,
    scan_cwd = scan_cwd,
    apply_matches = apply_matches,
    show_picker = show_picker_impl,
  })
end

return M
```

## Neues Migrations-Modul hinzufügen

### Schritt 1: Verzeichnis-Struktur

```bash
mkdir -p lua/usrcmds/migrate/mymodule/doc
touch lua/usrcmds/migrate/mymodule/@types.lua
touch lua/usrcmds/migrate/mymodule/init.lua
touch lua/usrcmds/migrate/mymodule/doc/mymodule.txt
```

### Schritt 2: Types definieren (@types.lua)

```lua
---@meta
---@module 'usrcmds.migrate.mymodule.@types'

---@class MigrateMyModule.Match
---@field line integer           # 1-based line number
---@field end_line integer       # 1-based end line
---@field original string        # Original text
---@field replacement string     # Migrated text
---@field extra table|nil        # Module-specific data

return {}
```

### Schritt 3: Core Logic (init.lua)

```lua
---@module 'usrcmds.migrate.mymodule'

local command = require("usrcmds.migrate.common.command")
local picker = require("usrcmds.migrate.common.picker")
local buffer_ops = require("usrcmds.migrate.common.buffer")

local M = {}

local api = vim.api

-- Conversion helper
local function to_common_matches(bufnr, module_matches)
  local matches = {}
  for _, m in ipairs(module_matches) do
    table.insert(matches, {
      bufnr = bufnr,
      fname = api.nvim_buf_get_name(bufnr),
      lnum = m.line,
      text = m.original,
      migrated = m.replacement,
      source = "buf",
      extra = m.extra,
    })
  end
  return matches
end

-- Scan functions
local function scan_range(bufnr, line1, line2)
  -- Your detection logic here
  local matches = {}
  -- ... populate matches
  return to_common_matches(bufnr, matches)
end

local function scan_buffer(bufnr)
  -- Scan entire buffer
  return scan_range(bufnr, 1, api.nvim_buf_line_count(bufnr))
end

local function scan_cwd()
  local files = buffer_ops.find_lua_files(vim.fn.getcwd())
  local all_matches = {}

  for _, filepath in ipairs(files) do
    local bufnr = buffer_ops.ensure_buffer(filepath)
    if bufnr then
      local matches = scan_buffer(bufnr)
      vim.list_extend(all_matches, matches)
    end
  end

  return all_matches
end

-- Apply migrations
local function apply_matches(matches)
  for _, match in ipairs(matches) do
    buffer_ops.replace_line(match.bufnr, match.lnum, match.migrated)
  end
end

-- Picker
local function show_picker_impl(matches)
  picker.show(matches, {
    title = "Migrate MyModule",
    single_apply = false,

    format_entry = function(match)
      return string.format("%s:%d  %s",
        vim.fn.fnamemodify(match.fname, ":t"),
        match.lnum,
        match.text:sub(1, 60))
    end,

    format_preview = function(match)
      return {
        "-- Before:",
        match.text,
        "",
        "-- After:",
        match.migrated,
      }
    end,

    on_apply = function(selections)
      apply_matches(selections)
    end,
  })
end

-- Enable command
function M.enable()
  command.register({
    name = "MigrateMyModule",
    scan_range = scan_range,
    scan_buffer = scan_buffer,
    scan_cwd = scan_cwd,
    apply_matches = apply_matches,
    show_picker = show_picker_impl,
  })
end

return M
```

### Schritt 4: Aktivierung

In deiner `init.lua` oder einem Setup-Modul:

```lua
require("usrcmds.migrate.mymodule").enable()
```

### Schritt 5: Dokumentation (doc/mymodule.txt)

Siehe Beispiele in `notify.txt` und `opt.txt`.

## Best Practices

### Pattern Detection

**Option 1: Regex (empfohlen für einfache Patterns)**
```lua
local function detect_pattern(line)
  local match = line:match("old_pattern%((.-)%)")
  if match then
    return "new_pattern(" .. match .. ")"
  end
end
```

**Option 2: Treesitter (für komplexe AST-Operationen)**
```lua
local ts = vim.treesitter
local function detect_with_ts(bufnr)
  local parser = ts.get_parser(bufnr, "lua")
  local tree = parser:parse()[1]
  -- ... traverse tree
end
```

**Empfehlung**: Beginne mit Regex. Treesitter nur wenn unbedingt nötig (siehe `notify` Modul für Lessons Learned).

### Line Replacement

**WICHTIG**: Immer in **descending order** arbeiten!

```lua
-- Sort DESCENDING by end_line
table.sort(matches, function(a, b)
  return a.extra.end_line > b.extra.end_line
end)

-- Then apply
for _, match in ipairs(matches) do
  apply_match(match)
end
```

**Warum**: Von oben nach unten würden sich Zeilen-Nummern verschieben.

### Index-Konvertierung

```lua
-- Parser: 1-based line numbers (wie Vim)
local line = 5        -- Zeile 5
local end_line = 7    -- bis Zeile 7 (inclusive)

-- nvim_buf_set_lines: 0-based, exclusive end
local start_idx = line - 1       -- 4
local end_idx = end_line         -- 7 (!)
-- Ersetzt indices [4,5,6] = Zeilen [5,6,7]
```

### Self-Migration Prevention

```lua
local function should_exclude(filepath)
  return filepath:match("/usrcmds/migrate/") ~= nil
end

-- In scan_cwd:
for _, file in ipairs(files) do
  if not should_exclude(file) then
    -- scan file
  end
end
```

### Import Injection

Wenn du Imports hinzufügst:

```lua
local function inject_import(bufnr)
  api.nvim_buf_set_lines(bufnr, 0, 0, false, {
    'local mylib = require("mylib")',
    ""
  })
  return true  -- Returns whether import was added
end

-- Adjust line numbers after import!
if import_added then
  for _, match in ipairs(matches) do
    match.lnum = match.lnum + 2
    match.extra.end_line = match.extra.end_line + 2
  end
end
```

## Debugging

### Enable Debug Output

```lua
-- In your migration module
local notify = require("lib.notify").create("[migrate.mymodule]")

notify.debug("Processing match at line " .. match.line)
notify.warn("Failed to parse: " .. line)
```

### Test Pattern Matching

```lua
-- Create test file
local test_content = [[
  old_pattern("test")
  another_old_pattern(123)
]]

-- Write to buffer and test
local bufnr = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(test_content, "\n"))

local matches = scan_buffer(bufnr)
print(vim.inspect(matches))
```

### Common Issues

**Problem**: Zeilen werden doppelt eingefügt
**Lösung**: Check Index-Konvertierung (1-based vs 0-based)

**Problem**: Spätere Matches werden nicht gefunden
**Lösung**: Sort descending, nicht ascending

**Problem**: Module migriert sich selbst
**Lösung**: Implement `should_exclude()`

**Problem**: Import verschiebt Zeilen-Nummern
**Lösung**: Adjust nach Import-Injection

## Testing

Teste jede Migration mit:

1. **Single line**: `:MigrateMyModule` auf Zeile mit Pattern
2. **Range**: Visual select + `:MigrateMyModule`
3. **Buffer**: `:MigrateMyModule %`
4. **CWD**: `:MigrateMyModule cwd`
5. **Multiline**: Pattern über mehrere Zeilen
6. **Edge cases**: Empty lines, comments, nested patterns

## Weitere Resourcen

- `docs/technical.md` - Technische Details zur Implementation
- `docs/patterns.md` - Pattern-Matching Beispiele
- `notify/doc/notify.txt` - Beispiel für komplexe Migration
- `opt/doc/opt.txt` - Beispiel für einfache Migration

-
