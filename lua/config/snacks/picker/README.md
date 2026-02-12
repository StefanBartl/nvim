# Snacks Picker Configuration

Erweiterte Konfiguration für snacks.nvim Picker mit Custom Actions, Keymaps und Shared History mit Telescope.

## Table of content

- [Snacks Picker Configuration](#snacks-picker-configuration)
  - [📦 Features](#features)
  - [📁 Struktur](#struktur)
  - [🚀 Installation & Setup](#installation-setup)
    - [Einfache Integration](#einfache-integration)
    - [Lazy.nvim Full Example](#lazynvim-full-example)
    - [Manuelle Integration (mit eigenen Anpassungen)](#manuelle-integration-mit-eigenen-anpassungen)
    - [Nur bestimmte Teile nutzen](#nur-bestimmte-teile-nutzen)
  - [📝 Verwendung](#verwendung)
    - [Create File/Folder](#create-filefolder)
    - [Open in Background](#open-in-background)
    - [Preview Navigation](#preview-navigation)
    - [History Navigation](#history-navigation)
  - [🔧 Konfiguration](#konfiguration)
    - [History Backend](#history-backend)
    - [Custom Actions hinzufügen](#custom-actions-hinzufgen)
    - [Keymaps überschreiben](#keymaps-berschreiben)
    - [Actions deaktivieren](#actions-deaktivieren)
  - [🎯 Built-in Snacks Actions](#built-in-snacks-actions)
  - [🔍 Troubleshooting](#troubleshooting)
    - [Create File funktioniert nicht](#create-file-funktioniert-nicht)
    - [History wird nicht gespeichert](#history-wird-nicht-gespeichert)
    - [Keymaps funktionieren nicht](#keymaps-funktionieren-nicht)
    - [SQLite History funktioniert nicht](#sqlite-history-funktioniert-nicht)
- [Installiere Dependencies](#installiere-dependencies)
- [Oder via Mason](#oder-via-mason)
  - [🤝 Kompatibilität](#kompatibilitt)
  - [📚 Siehe auch](#siehe-auch)

---

## 📦 Features

✅ **Custom Actions**
- `<C-a>`: Create file/folder im current directory
- `<S-CR>`, `<C-o>`: Open file in background (ohne Picker zu schließen)

✅ **Enhanced Keymaps**
- `<PageUp>`, `<PageDown>`: Preview vertical scrollen
- `<C-Left>`, `<C-Right>`: Preview horizontal scrollen
- `<C-p>`, `<C-n>`: History navigation (wenn verfügbar)

✅ **Shared History**
- Nutzt die **gleiche Datenbank** wie Telescope
- SQLite-Backend (wenn verfügbar) oder File-based Fallback
- Unified Search History über beide Picker

## 📁 Struktur

```
config/snacks/picker/
├── init.lua                    # Main module & orchestrator
├── history.lua                 # History integration (shared with Telescope)
├── keymaps.lua                 # Keymap definitions
├── actions/
│   ├── init.lua               # Actions aggregator
│   ├── create_file.lua        # File/folder creation action
│   └── open_background.lua    # Background file open action
└── README.md                   # This file
```

## 🚀 Installation & Setup

### Einfache Integration

```lua
-- In deiner snacks.nvim config (z.B. plugins/snacks.lua)
local picker_config = require("config.snacks.picker")

return {
  "folke/snacks.nvim",
  opts = {
    picker = picker_config.get_config(),
    -- ... andere snacks opts
  },
}
```

### Lazy.nvim Full Example

```lua
{
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = function()
    local picker_config = require("config.snacks.picker")

    return {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      picker = picker_config.get_config(),
      -- ... mehr snacks modules
    }
  end,
}
```

### Manuelle Integration (mit eigenen Anpassungen)

```lua
local picker_config = require("config.snacks.picker")

return {
  "folke/snacks.nvim",
  opts = function()
    local config = picker_config.get_config()

    -- Eigene Anpassungen
    config.win.input.keys["<C-x>"] = "custom_action"
    config.actions.custom_action = function(picker, item)
      -- Your custom action
    end

    return {
      picker = config,
    }
  end,
}
```

### Nur bestimmte Teile nutzen

```lua
-- Nur Actions
local custom_actions = require("config.snacks.picker").get_actions()

-- Nur Keymaps
local custom_keymaps = require("config.snacks.picker").get_keymaps()

-- Nur History
local history_config = require("config.snacks.picker").get_history()

-- Selbst zusammenbauen
opts = {
  picker = {
    enabled = true,
    actions = custom_actions,
    win = {
      input = { keys = custom_keymaps.input },
      list = { keys = custom_keymaps.list },
    },
    history = history_config,
  },
}
```

## 📝 Verwendung

### Create File/Folder

1. Öffne einen Picker (z.B. `:SnacksFindFiles`)
2. Navigiere zu dem Ordner wo du erstellen möchtest
3. Drücke `<C-a>`
4. Gib den Namen ein:
   - `filename.txt` → Erstellt File
   - `foldername/` → Erstellt Folder (trailing slash!)
5. File wird erstellt und geöffnet

**Beispiele:**
```
new-component.lua        → File
components/              → Folder
utils/helper.ts          → File in neuem Ordner
```

### Open in Background

1. Öffne einen Picker
2. Navigiere zu einer Datei
3. Drücke `<S-CR>` oder `<C-o>`
4. Datei wird als Buffer geladen, **Picker bleibt offen**
5. Weiter browsen und mehr Files laden
6. Später zu den Buffern wechseln mit `:SnacksFindBuffers`

**Use Case:**
- Preload mehrere Files bevor du mit dem Editieren startest
- Code-Review: Open alle geänderten Files
- Multi-File Refactoring vorbereiten

### Preview Navigation

**Vertical Scroll:**
- `<PageDown>` → Scroll down im Preview
- `<PageUp>` → Scroll up im Preview

**Horizontal Scroll:**
- `<C-Right>` → Scroll right (lange Zeilen)
- `<C-Left>` → Scroll left

**Use Case:**
- Lange Dateien durchsehen
- Horizontales Scrollen bei langen Zeilen
- Code-Snippets im Preview erkunden

### History Navigation

Wenn SQLite oder File-based History verfügbar:

- `<C-p>` → Vorheriger Suchbegriff
- `<C-n>` → Nächster Suchbegriff

**Use Case:**
- Wiederhole häufige Suchen
- Navigate durch Search History
- **Shared mit Telescope!** → Gleiche History in beiden Pickern

## 🔧 Konfiguration

### History Backend

Die History nutzt automatisch:
1. **SQLite** (wenn `sqlite.lua` und `telescope-smart-history` installiert)
2. **File-based** (Fallback)

**Gleiche Datenbank wie Telescope:**
- SQLite: `~/.local/share/nvim/databases/telescope_history.sqlite3`
- File: `~/.local/share/nvim/picker-history/_global.txt`

### Custom Actions hinzufügen

```lua
local picker_config = require("config.snacks.picker")
local config = picker_config.get_config()

-- Neue Action definieren
config.actions.my_action = function(picker, item)
  print("Selected: " .. vim.inspect(item))
  -- Your logic here
end

-- Keymap hinzufügen
config.win.input.keys["<C-y>"] = { "my_action", mode = { "i", "n" } }

return {
  "folke/snacks.nvim",
  opts = {
    picker = config,
  },
}
```

### Keymaps überschreiben

```lua
local config = require("config.snacks.picker").get_config()

-- PageDown zu etwas anderem ändern
config.win.input.keys["<PageDown>"] = "preview_page_down"  -- Built-in alternative
config.win.input.keys["<C-d>"] = "preview_scroll_down"     -- Alternative binding

return {
  "folke/snacks.nvim",
  opts = { picker = config },
}
```

### Actions deaktivieren

```lua
local config = require("config.snacks.picker").get_config()

-- Create file deaktivieren
config.win.input.keys["<C-a>"] = nil
config.win.list.keys["<C-a>"] = nil
config.actions.create_file = nil

return {
  "folke/snacks.nvim",
  opts = { picker = config },
}
```

## 🎯 Built-in Snacks Actions

Zusätzlich zu unseren Custom Actions stehen alle Built-in Actions zur Verfügung:

**Preview Control:**
- `preview_scroll_down` / `preview_scroll_up`
- `preview_scroll_left` / `preview_scroll_right`
- `preview_page_down` / `preview_page_up`

**History:**
- `history_back` / `history_forward`
- `history_clear`

**Navigation:**
- `jump` → Jump to selection
- `split` → Open in split
- `vsplit` → Open in vertical split
- `tab` → Open in new tab

**Selection:**
- `select` / `select_all`
- `toggle` / `toggle_all`

**Misc:**
- `close` → Close picker
- `cancel` → Cancel without selection
- `toggle_hidden` → Toggle hidden files
- `toggle_ignored` → Toggle gitignored files

[Vollständige Liste in snacks.nvim docs](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md)

## 🔍 Troubleshooting

### Create File funktioniert nicht

```lua
-- Prüfe ob Action registriert ist
:lua print(vim.inspect(require("snacks").picker.config.actions.create_file))

-- Sollte eine Function sein
```

### History wird nicht gespeichert

```lua
-- Prüfe Backend
:lua print(require("config.snacks.picker.history").get_backend())

-- Sollte "sqlite" oder "file" sein, nicht "none"
```

### Keymaps funktionieren nicht

```lua
-- Prüfe Keymap registration
:lua print(vim.inspect(require("snacks").picker.config.win.input.keys))

-- <C-a>, <S-CR>, etc. sollten sichtbar sein
```

### SQLite History funktioniert nicht

```bash
# Installiere Dependencies
:Lazy install sqlite.lua
:Lazy install telescope-smart-history.nvim

# Oder via Mason
:Mason install sqlite
```

## 🤝 Kompatibilität

- ✅ **Neovim** >= 0.9.4
- ✅ **snacks.nvim** (latest)
- ✅ **Telescope** (optional, für shared history)
- ✅ **sqlite.lua** (optional, für SQLite backend)
- ✅ **telescope-smart-history** (optional, für SQLite backend)

## 📚 Siehe auch

- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [telescope-smart-history](https://github.com/nvim-telescope/telescope-smart-history.nvim)
- [sqlite.lua](https://github.com/kkharji/sqlite.lua)

---

**Version:** 1.0.0
**Erstellt:** 2025-02-11
