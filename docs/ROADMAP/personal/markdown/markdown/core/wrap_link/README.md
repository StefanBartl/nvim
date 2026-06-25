# custom.markdown.core.wrap_link

Intelligentes Markdown-Link-Wrapping für Neovim.

## Table of content

  - [Features](#features)
    - [Normal Mode (`<leader>[`)](#normal-mode-leader)
    - [Visual Mode (`<leader>[`)](#visual-mode-leader)
  - [Verwendung](#verwendung)
    - [Beispiele](#beispiele)
      - [Normal Mode](#normal-mode)
      - [Visual Mode](#visual-mode)
  - [Technische Details](#technische-details)
    - [Wort-Erkennung](#wort-erkennung)
    - [URL/Pfad-Erkennung](#urlpfad-erkennung)
    - [Index-Konvertierung](#index-konvertierung)
    - [Fehlerbehandlung](#fehlerbehandlung)
  - [Installation](#installation)
  - [Abhängigkeiten](#abhngigkeiten)
  - [Bekannte Einschränkungen](#bekannte-einschrnkungen)
  - [Verbesserungsvorschläge](#verbesserungsvorschlge)
    - [Features](#features-1)
    - [Performance](#performance)
    - [Sicherheit](#sicherheit)
    - [Robustheit](#robustheit)
    - [Usability](#usability)
    - [Code Quality](#code-quality)
    - [Erweiterbarkeit](#erweiterbarkeit)

---

## Features

### Normal Mode (`<leader>[`)

Wickelt das Wort unter dem Cursor in Markdown-Link-Syntax:

1. **Leere Position**: `[]()` einfügen, Cursor in `[]`
2. **URL/Pfad**: `[](https://example.com)` erstellen, Cursor in `[]` für Beschreibung
3. **Text**: `[Detaildokument]()` erstellen, Cursor in `()` für URL

### Visual Mode (`<leader>[`)

Wickelt die Auswahl basierend auf Inhalt:

1. **URL/Pfad**: `[](selected_url)` → Cursor in `[]` für Beschreibung
2. **Einzelwort**: `[Wort]()` → Cursor in `()` für URL
3. **Mehrere Wörter**: `[Lange Beschreibung]()` → Cursor in `()` für URL

## Verwendung

```lua
-- In Markdown-Buffer automatisch aktiviert via setup
require("custom.markdown.core.wrap_link").attach(bufnr)
```

### Beispiele

#### Normal Mode

```markdown
# Cursor auf "example"
example  →  <leader>[  →  [example]()
                              ↑ Cursor hier

# Cursor auf URL
https://test.com  →  <leader>[  →  [](https://test.com)
                                     ↑ Cursor hier
```

#### Visual Mode

```markdown
# "Detaildokument" markiert
Detaildokument  →  <leader>[  →  [Detaildokument]()
                                                 ↑ Cursor hier

# URL markiert
https://example.com  →  <leader>[  →  [](https://example.com)
                                        ↑ Cursor hier
```

## Technische Details

### Wort-Erkennung

```lua
-- Erkannte Zeichen für Wort-Grenzen:
[%w_./:\\-]  -- Alphanumerisch + _ . / : \ -
```

Ermöglicht korrekte Erkennung von:
- Dateinamen: `doc/file.md`
- URLs: `https://example.com`
- Pfade: `../relative/path`
- API-Namen: `vim.api.nvim_buf_get_lines`

### URL/Pfad-Erkennung

Heuristiken:
1. Protokoll: `https?://`, `file://`, `ftp://`
2. Pfad-Separator: `/` oder `\`
3. Dateiendung: `name.ext`

### Index-Konvertierung

**Kritisch für Korrektheit:**

```lua
-- Visual Mode Marks ('< und '>):
-- - Zeilen: 1-basiert (Vim-Style)
-- - Spalten: 1-basiert, INKLUSIVE (zeigt auf letztes Zeichen)

-- nvim_buf_set_text erwartet:
-- - Zeilen: 0-basiert
-- - Spalten: 0-basiert, EXKLUSIVE (eins nach letztem Zeichen)

-- Konvertierung:
start_row = mark_row - 1      -- 1-based → 0-based
start_col = mark_col - 1      -- 1-based → 0-based
end_col_exclusive = mark_end_col  -- Already points to last char, keep as-is then +1
```

### Fehlerbehandlung

1. **Bounds Checking**: Validierung aller Indizes vor API-Calls
2. **pcall Wrapping**: Alle Buffer-Operationen geschützt
3. **Graceful Degradation**: Bei Fehler Notification statt Crash

## Installation

Wird automatisch via `custom.markdown.setup.keymaps` geladen:

```lua
-- In keymaps.lua wird attach() aufgerufen:
local wrap_link = require("custom.markdown.core.wrap_link")
wrap_link.attach(bufnr)  -- Pro Markdown-Buffer
```

## Abhängigkeiten

- Neovim >= 0.9 (für `nvim_buf_set_text`)
- `vim.bo[bufnr].filetype == "markdown"`

## Bekannte Einschränkungen

1. **Single-Line Only**: Multi-line Wrapping erstellt `[text\nmore]()` statt separate Links
2. **Keine Escape-Sequenzen**: URLs mit `[]()` können Probleme verursachen
3. **ASCII-fokussiert**: Unicode-Zeichen in Wort-Grenzen nicht optimal

---

## Verbesserungsvorschläge

### Features

1. **Smart Duplicate Detection**
   ```lua
   -- Existierenden Link nicht doppelt wrappen:
   [already linked](url)  →  keine Änderung
   ```

2. **Title Extraction**
   ```lua
   -- Bei URLs automatisch Titel fetchen:
   https://example.com  →  [Example Domain](https://example.com)
   ```

3. **Reference-Style Links**
   ```lua
   -- Option für [text][ref] statt [text](url)
   ```

4. **Multi-Line Smart Split**
   ```lua
   -- Lange Selections in mehrere Links aufteilen
   ```

### Performance

1. **Lazy Loading**: Nur bei Bedarf laden via autocmd
2. **Debouncing**: Rate-Limiting bei schnellen Wiederholungen
3. **Buffer-Local Cache**: Wort-Grenzen cachen

### Sicherheit

1. **URL Validation**: Prüfen ob URL gültig
   ```lua
   local ok, parsed = pcall(vim.uri_parse, url)
   ```

2. **XSS Protection**: Gefährliche Zeichen escapen
   ```lua
   -- < > " ' in URLs encoden
   ```

3. **Path Traversal Check**: `../../../etc/passwd` verhindern
   ```lua
   local normalized = vim.fn.fnamemodify(path, ":p")
   if normalized:match("%.%.") then return false end
   ```

### Robustheit

1. **Undo-Point Management**
   ```lua
   vim.cmd("undojoin")  -- Einzelner Undo-Schritt
   ```

2. **Mark Preservation**: Marks vor Operation speichern
   ```lua
   local marks = vim.fn.getmarklist(bufnr)
   -- ... operation ...
   -- restore marks
   ```

3. **Multi-Cursor Support**: Mehrere Cursors gleichzeitig

### Usability

1. **Visual Feedback**: Zeige Preview vor Apply
2. **Configurable Keys**: User-definierbare Mappings
3. **Telescope Integration**: Link-Targets via Picker wählen
4. **History**: Zuletzt verwendete URLs für Quick-Access

### Code Quality

1. **Type Annotations**: Vollständige EmmyLua Docs
2. **Unit Tests**: Für alle Edge Cases
3. **Error Messages**: Detaillierte Fehlermeldungen mit Context
4. **Logging**: Optional verbose Mode für Debugging

### Erweiterbarkeit

1. **Plugin API**: Hooks für Custom Behavior
   ```lua
   wrap_link.on_before_wrap = function(text, is_url)
     -- Custom logic
     return modified_text
   end
   ```

2. **Custom Patterns**: User-definierte URL-Erkennung
   ```lua
   wrap_link.add_pattern("jira", "^PROJ%-%d+$", "https://jira.com/browse/")
   ```

3. **Language Server Integration**: LSP für Link-Validation

---
