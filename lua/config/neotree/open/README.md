# config.neotree.open

Unified opener module for Neo-tree with multiple sub-modules.

--

## Table of content

- [config.neotree.open](#configneotreeopen)
  - [Overview](#overview)
  - [Sub-Modules](#sub-modules)
    - [window.lua](#windowlua)
    - [system_app/](#system_app)
    - [filemanager/](#filemanager)
  - [Usage](#usage)
    - [Window Opener](#window-opener)
    - [System App](#system-app)
    - [File Manager](#file-manager)
  - [Integration](#integration)
  - [See Also](#see-also)
  - [5. Updated `doc/reload.txt`](#5-updated-docreloadtxt)
- [Module Reload List (config.neotree)](#module-reload-list-configneotree)
  - [Core Modules](#core-modules)
  - [Reload Command](#reload-command)
  - [Restart Neovim](#restart-neovim)
  - [Test Commands](#test-commands)

---

## Overview

Das `config.neotree.open`-Modul bündelt verschiedene Mechanismen zum Öffnen von Dateien und Verzeichnissen:

- **Window Opener**: Öffnet Neo-tree in verschiedenen Positionen (left/right/float/current)
- **System App Opener**: Öffnet Dateien mit der Standardanwendung des Systems
- **File Manager Opener**: Öffnet Dateien im Dateimanager (Explorer, Finder, Nautilus, etc.)

---

## Sub-Modules

### window.lua

Ehemals `init.lua`. Verwaltet Keymaps zum Öffnen von Neo-tree in verschiedenen Fensterpositionen.

**API:**
```lua
require("config.neotree.open.window").attach_opener_mappings(opts)
```

**Keymaps:**
- `<A-l>` → Open/Toggle Left
- `<A-r>` → Open/Toggle Right
- `<A-f>` → Open/Toggle Float
- `<A-c>` → Open/Toggle Current Window

**Details:** Siehe separates README in früheren Dokumenten.

---

### system_app/

Öffnet Dateien/Verzeichnisse mit der Standardanwendung des Betriebssystems.

**Modul:** `lua/config/neotree/open/system_app/init.lua`

**API:**
```lua
local system_app = require("config.neotree.open.system_app")
system_app.open_from_neotree(state)
```

**Plattform-Support:**
- **Windows**: PowerShell `Start-Process` für Dateien, `explorer.exe` für Verzeichnisse
- **macOS**: `open`
- **Linux**: `xdg-open`

**Keymaps:**
```lua
["sm"] = "Open with System Application"
```

**Fallback-Reihenfolge:**
1. `lazy.util.open` (LazyVim)
2. `vim.ui.open` (Neovim 0.10+)
3. Plattform-spezifischer Befehl

---

### filemanager/

Öffnet Dateien/Verzeichnisse im System-Dateimanager mit Fokus auf die Datei (Reveal/Select).

**Module:**
- `init.lua` - Dispatcher (wählt plattform-spezifisches Modul)
- `win.lua` - Windows Explorer
- `wsl.lua` - WSL → Windows Explorer
- `unix_ubuntu.lua` - Linux/macOS (DBus, Nautilus, Finder, etc.)

**API:**
```lua
local filemanager = require("config.neotree.open.filemanager")
filemanager.open_from_neotree(state)
```

**Keymaps:**
```lua
["L"] = "Open in system file manager"
```

**Plattform-Erkennung:**
- Windows → `win.lua`
- WSL → `wsl.lua`
- Linux/macOS → `unix_ubuntu.lua`

---

## Usage

### Window Opener
```lua
-- In plugins/neotree.lua config:
config = function(_, opts)
  require("config.neotree.open.window").attach_opener_mappings()
end
```

### System App
```lua
-- In keymaps/filesystem.lua:
["sm"] = {
  function(state)
    require("config.neotree.open.system_app").open_from_neotree(state)
  end,
  desc = "Open with System Application",
}
```

### File Manager
```lua
-- In keymaps/filesystem.lua:
["L"] = {
  function(state)
    require("config.neotree.open.filemanager").open_from_neotree(state)
  end,
  desc = "Open in system file manager",
}
```

---

## Integration

Alle Opener sind in `lua/config/neotree/keymaps/filesystem.lua` integriert:
```lua
["sm"] = "Open with System Application"  -- PDF, Images, etc.
["L"]  = "Open in File Manager"          -- Reveal in Explorer/Finder
["<A-l>"] = "Toggle Neo-tree (left)"     -- Window opener
```

---

## See Also

- [window.lua Documentation](./window.md) (früheres README)
- [filemanager/README.md](./filemanager/README.md)
- [system_app/README.md](./system_app/README.md)

---
```

---

## 5. Updated `doc/reload.txt`

**`doc/reload.txt`:**
```
# Module Reload List (config.neotree)

Nach Änderungen an folgenden Modulen sollte Neo-tree neu geladen werden:

## Core Modules
- lua/config/neotree/open/window.lua (ehemals open/init.lua)
- lua/config/neotree/open/system_app/init.lua
- lua/config/neotree/open/filemanager/init.lua
- lua/config/neotree/open/filemanager/win.lua
- lua/config/neotree/open/filemanager/wsl.lua
- lua/config/neotree/open/filemanager/unix_ubuntu.lua
- lua/config/neotree/keymaps/filesystem.lua
- lua/config/neotree/commands/mark/init.lua
- lua/config/neotree/utils/node.lua

## Reload Command
:Lazy reload neo-tree.nvim

## Restart Neovim
Falls Probleme auftreten, Neovim komplett neu starten.

## Test Commands
:lua require("config.neotree.open.window").attach_opener_mappings()
:lua require("config.neotree.open.system_app").open_from_neotree(require("neo-tree.sources.manager").get_state("filesystem"))
:lua require("config.neotree.open.filemanager").open_from_neotree(require("neo-tree.sources.manager").get_state("filesystem"))
