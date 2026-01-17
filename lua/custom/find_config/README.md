# custom.find_config

Cross-platform Dateifinder und Live-Grep für das Neovim-Konfigurationsverzeichnis.

---

## Table of content

- [custom.find_config](#customfind_config)
  - [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [Überblick](#berblick)
  - [Features](#features)
  - [Installation](#installation)
  - [Konfiguration](#konfiguration)
    - [Basis-Setup](#basis-setup)
    - [Engine-Auswahl](#engine-auswahl)
    - [Keymaps anpassen](#keymaps-anpassen)
    - [User Commands anpassen](#user-commands-anpassen)
    - [Komplett-Beispiel](#komplett-beispiel)
  - [Verwendung](#verwendung)
    - [Keymaps](#keymaps)
    - [User Commands](#user-commands)
    - [Programmatisch](#programmatisch)
  - [Engines](#engines)
    - [fzf-lua](#fzf-lua)
    - [Telescope](#telescope)
  - [Architektur](#architektur)
  - [Abhängigkeiten](#abhngigkeiten)

---

## Inhaltsverzeichnis

- [Überblick](#überblick)
- [Features](#features)
- [Installation](#installation)
- [Konfiguration](#konfiguration)
  - [Basis-Setup](#basis-setup)
  - [Engine-Auswahl](#engine-auswahl)
  - [Keymaps anpassen](#keymaps-anpassen)
  - [User Commands anpassen](#user-commands-anpassen)
  - [Komplett-Beispiel](#komplett-beispiel)
- [Verwendung](#verwendung)
  - [Keymaps](#keymaps)
  - [User Commands](#user-commands)
  - [Programmatisch](#programmatisch)
- [Engines](#engines)
  - [fzf-lua](#fzf-lua)
  - [Telescope](#telescope)
- [Architektur](#architektur)
- [Abhängigkeiten](#abhängigkeiten)

---

## Überblick

`custom.find_config` ermöglicht die schnelle Suche in der Neovim-Konfiguration mit austauschbaren Such-Engines. Das Modul nutzt `vim.fn.stdpath("config")` für plattformübergreifende Kompatibilität (Linux, macOS, Windows).

---

## Features

* **Pluggable Engines**: Unterstützt fzf-lua und Telescope
* **Cross-Platform**: Funktioniert auf Linux, macOS, Windows und WSL
* **Konfigurierbare Keymaps**: Anpassbare Leader-Keys und Suffixes
* **Konfigurierbare Commands**: Eigene Command-Namen möglich
* **Engine-spezifische Optionen**: Direkter Zugriff auf Engine-APIs
* **Fuzzy Matching**: Case-insensitive Suche standardmäßig aktiviert
* **Live Grep**: Interaktive Echtzeit-Suche in Config-Dateien

---

## Installation

Das Modul ist Teil der Custom-Plugin-Sammlung und benötigt keine separate Installation.

**Abhängigkeiten:**
- `lib.notify` (für Fehlermeldungen)
- `lib.cross` oder `vim.fn.stdpath` (für Config-Verzeichnis-Auflösung)
- Eine der Such-Engines:
  - [fzf-lua](https://github.com/ibhagwan/fzf-lua) (empfohlen)
  - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

---

## Konfiguration

### Basis-Setup

Minimale Konfiguration mit Standardwerten:

```lua
require("custom.find_config").setup()
```

**Standard-Engine**: `fzf-lua`
**Standard-Keymaps**:
* `<leader>fc` → Find files in config
* `<leader>gc` → Grep in config

**Standard-Commands**:
- `:FindConfig [query]`
- `:GrepConfig [query]`

---

### Engine-Auswahl

Man kann die Such-Engine beim Setup auswählen:

```lua
-- fzf-lua (Standard)
require("custom.find_config").setup({
  engine = "fzf",
})

-- Telescope
require("custom.find_config").setup({
  engine = "telescope",
})
```

---

### Keymaps anpassen

Vollständige Kontrolle über Keymap-Konfiguration:

```lua
require("custom.find_config").setup({
  keymaps = {
    enable = true,           -- Keymaps aktivieren
    prefix = "<leader>",     -- Leader-Prefix
    find = "cf",             -- <leader>cf für Find
    grep = "cg",             -- <leader>cg für Grep
  },
})
```

**Keymaps deaktivieren**:

```lua
require("custom.find_config").setup({
  keymaps = { enable = false },
})
```

---

### User Commands anpassen

Eigene Command-Namen definieren:

```lua
require("custom.find_config").setup({
  usercmds = {
    enable = true,
    find = "ConfigFind",     -- :ConfigFind
    grep = "ConfigGrep",     -- :ConfigGrep
  },
})
```

**Commands deaktivieren**:

```lua
require("custom.find_config").setup({
  usercmds = { enable = false },
})
```

---

### Komplett-Beispiel

```lua
require("custom.find_config").setup({
  engine = "telescope",
  keymaps = {
    enable = true,
    prefix = "<leader>",
    find = "nf",  -- <leader>nf
    grep = "ng",  -- <leader>ng
  },
  usercmds = {
    enable = true,
    find = "NvimFind",
    grep = "NvimGrep",
  },
})
```

---

## Verwendung

### Keymaps

Nach dem Setup sind folgende Keymaps verfügbar (Standard-Konfiguration):

| Keymap       | Aktion                                    |
| ------------ | ----------------------------------------- |
| `<leader>fc` | Dateisuche in Neovim-Config               |
| `<leader>gc` | Live-Grep in Neovim-Config                |

**Verhalten**:
- **Find**: Öffnet fuzzy file picker im Config-Verzeichnis
- **Grep**: Öffnet interaktive Live-Grep-Suche

---

### User Commands

| Command              | Aktion                                      |
| -------------------- | ------------------------------------------- |
| `:FindConfig [query]` | Dateisuche mit optionaler initialer Query   |
| `:GrepConfig [query]` | Live-Grep mit optionaler initialer Query    |

**Beispiele**:

```vim
:FindConfig init
:GrepConfig keymap
```

---

### Programmatisch

Direkte API-Nutzung in eigenem Code:

```lua
local find_config = require("custom.find_config")

-- Dateisuche
find_config.find_in_config()

-- Live-Grep
find_config.grep_in_config()

-- Mit Engine-spezifischen Optionen
find_config.find_in_config({
  prompt_title = "Custom Title",  -- Telescope
})

find_config.grep_in_config({
  fzf_opts = { ["--exact"] = "" },  -- fzf-lua
})
```

---

## Engines

### fzf-lua

**Vorteile**:
- Extrem schnell
- Geringer Memory-Footprint
- Native Lua-Implementierung
- Flexibles fzf-Syntax

**Engine-spezifische Optionen**:

```lua
find_config.find_in_config({
  prompt = "Custom Prompt❯ ",
  fzf_opts = {
    ["-i"] = "",           -- case-insensitive (Standard)
    ["--exact"] = "",      -- exact match
    ["--no-sort"] = "",    -- keine Sortierung
  },
})
```

**Dokumentation**: `:help fzf-lua`

---

### Telescope

**Vorteile**:
- Rich UI mit Preview
- Umfangreiches Extension-Ökosystem
- Native Integration mit vielen Plugins
- Konfigurierbare Layouts

**Engine-spezifische Optionen**:

```lua
find_config.find_in_config({
  prompt_title = "Config Files",
  layout_strategy = "vertical",
  layout_config = {
    width = 0.9,
    height = 0.9,
  },
})

find_config.grep_in_config({
  additional_args = function()
    return { "--case-sensitive" }
  end,
})
```

**Dokumentation**: `:help telescope.builtin`

---

## Architektur

```
custom.find_config/
├── init.lua              -- Setup & Engine-Dispatcher
├── core.lua              -- Gemeinsame Logik
├── engines/
│   ├── fzf.lua          -- fzf-lua Integration
│   └── telescope.lua    -- Telescope Integration
└── config/
    └── defaults.lua     -- Default-Werte
```

**Design-Prinzipien**:
1. **Engine-Agnostik**: Kernlogik unabhängig von Such-Engine
2. **Lazy Loading**: Engines werden nur bei Bedarf geladen
3. **Defensive Programmierung**: Alle Engine-Calls mit pcall geschützt
4. **Erweiterbar**: Neue Engines durch einfaches Hinzufügen von `engines/*.lua`

---

## Abhängigkeiten

**Erforderlich**:
- Neovim ≥ 0.9.0
- `lib.notify` (Custom-Lib)
- `custom.find_config.core` (Modul-intern)

**Optional (mindestens eine)**:
- `fzf-lua` ≥ 0.0.1
- `telescope.nvim` ≥ 0.1.0

**Engine wird automatisch geprüft beim Setup-Call**. Bei fehlender Engine erscheint eine Fehlermeldung mit Installationshinweis.

---
