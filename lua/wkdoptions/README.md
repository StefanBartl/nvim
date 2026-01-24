# wkdoptions

**Modulares, hochperformantes Neovim-Konfigurationssystem für visuelle Verbesserungen und Editor-Optionen.**

---

## Inhaltsverzeichnis

* [Überblick](#überblick)
* [Funktionen](#funktionen)
* [Installation](#installation)
* [Schnellstart](#schnellstart)
* [Architektur](#architektur)
* [Module](#module)

  * [hl_config](#hl_config)
  * [options_config](#options_config)
  * [config](#config)
  * [commands](#commands)
* [Konfiguration](#konfiguration)
* [Befehle](#befehle)
* [Performance](#performance)
* [Best Practices](#best-practices)
* [Fehlerbehebung](#fehlerbehebung)
* [Entwicklung](#entwicklung)

---

## Überblick

wkdoptions ist ein umfassendes Konfigurationssystem für Neovim und bietet:

* **Visuelle Erweiterungen**: CursorLine, modusabhängige Einfärbung, Flash-Feedback, Breadcrumbs
* **Editor-Optionen**: Matchparen, Guicursor, globale Umschalter
* **Live-Konfiguration**: Laufzeitänderungen per Benutzerbefehl
* **Typsichere API**: Vollständige LuaLS-Typannotationen
* **Hohe Performance**: Lazy Loading, Memoisierung, optimiertes Rendering

---

## Funktionen

## Visuelle Funktionen (hl_config)

* **CursorLine/Column**: Adaptive Hervorhebung mit Schutz für große Dateien
* **Modus-Tinting**: CursorLine-Farben pro Modus (Normal/Insert/Visual/Replace)
* **Flash-Feedback**: Visuelles Feedback für Yank-/Paste-Operationen
* **SignColumn-Tinting**: Hintergrundfarben basierend auf Diagnoseschwere
* **Terminal-Palette**: Harmonisiertes Erscheinungsbild von Terminal-Buffern
* **Aktuelles Wort**: Unterstreichung des Wortes unter dem Cursor
* **Indent Scope**: Hervorhebung von Einrückungsblöcken im sichtbaren Bereich
* **Breadcrumbs**: Winbar mit Pfad und Kontext (LSP/Tree-sitter)
* **Diff Peek**: Integration zur Vorschau von Git-Hunks
* **Cword-Vorkommen**: Hervorhebung aller Vorkommen des aktuellen Wortes

## Editor-Optionen (options_config)

* **Matchparen**: Konfigurierbare Blinkdauer
* **Guicursor**: Cursorformen pro Modus mit eigenen Highlights
* **Diff-Profile**: Schnelles Umschalten von Diff-Modi (minimal/context/review/strict)

## Konfigurationssystem (config)

* **Modular**: Trennung von Daten, Kernlogik und Utilities
* **Lazy Loading**: Module werden bei Bedarf geladen
* **Typsicher**: Vollständige LuaLS-Annotationen
* **Live-Updates**: Laufzeitänderungen per Kommando
* **Observer-Pattern**: After-Set-Callbacks für reaktive Updates

---

## Installation

## Mit lazy.nvim

```lua
{
  dir = "/path/to/wkdoptions",
  name = "wkdoptions",
  config = function()
    require("wkdoptions").setup({
      highlights = true,
      options = true,
    })
  end,
}
```

## Mit packer.nvim

```lua
use {
  "/path/to/wkdoptions",
  config = function()
    require("wkdoptions").setup({
      highlights = true,
      options = true,
    })
  end,
}
```

---

## Schnellstart

## Basis-Setup

```lua
require("wkdoptions").setup({
  highlights = true,  -- Aktiviert visuelle Features
  options = true,     -- Aktiviert Editor-Optionen
})
```

## Laufzeit-Konfiguration

```vim
:WKDHighlightSet! enable_line
:WKDHighlightSet breadcrumbs_separator " › "
:WKDDiffProfile minimal
:WKDOptSet! enable_matchparen
```

---

## Architektur

```
wkdoptions/
├── init.lua
├── config/
│   ├── init.lua
│   ├── @types/
│   ├── data/
│   │   ├── highlight.lua
│   │   ├── options.lua
│   │   └── skip.lua
│   └── core/
│       ├── parser.lua
│       ├── setter.lua
│       ├── getter.lua
│       └── observer.lua
├── hl_config/
│   ├── init.lua
│   ├── @types/
│   ├── core/
│   ├── features/
│   ├── breadcrumbs/
│   ├── utils/
│   └── path_cache/
├── options_config/
│   └── init.lua
├── commands/
│   ├── init.lua
│   └── register/
└── set_diff_profile/
    ├── profiles.lua
    └── selector.lua
```

---

## Module

## hl_config

Subsystem für visuelle UX-Features mit modularer Architektur.

## Zentrale Komponenten

* **State-Management**

  * Zentrale Feature-Flags
  * Fensterlokaler Modus-Cache
  * Namespace- und Augroup-Registry

* **Highlight-Anwendung**

  * Sichere Anwendung von Highlight-Gruppen
  * Fehlerbehandlung mit Validierung
  * Fallback-Erzeugung von Highlights

Alle Features prüfen `State.is_enabled()` und lassen sich zur Laufzeit umschalten.

## Breadcrumbs-System

Winbar-Rendering mit Pfad und Kontext:

* Pfad- und Kontext-Komposition
* Skip-Regeln
* Mittige Ellipsisierung
* LSP-, Tree-sitter- und sprachspezifische Provider
* Konfigurierbare Provider-Reihenfolge

## Utilities

* **Winhighlight**: Sicheres Parsen, Memoisierung, Merge-/Remove-Operationen
* **Large File**: Größenprüfungen mit Memoisierung
* **Separator**: Nerd-Font-Fallback, Validierung, Cache
* **Skip**: UI-Buffer-Erkennung mit O(1)-Lookups

---

## options_config

Editor-Optionen und globale Umschalter:

* Matchparen an/aus mit Blinkdauer
* Guicursor-Zuordnung zu Highlight-Gruppen
* Cursorformen pro Modus
* CursorLine/Column-Defaults
* ColorScheme-Persistenz

---

## config

Modulares Konfigurationssystem mit Lazy Loading.

## API

```lua
local C = require("wkdoptions.config")

local cfg = C.get_cfg()
local value = C.parse("true")
local ok, err = C.set("highlight", "enable_line", true, false)
local val = C.get("highlight", "enable_line")
local keys = C.keys("highlight")

C.on_after_set("highlight", function(key)
  print("Changed:", key)
end)
```

---

## commands

Benutzerbefehle mit Autovervollständigung.

```vim
:WKDHighlightSet
:WKDHighlightSet!
:WKDHighlightShow
:WKDHighlightList
:WKDDiffProfile
```

---

## Konfiguration

## Highlight-Konfiguration

```lua
local C = require("wkdoptions.config")
local cfg = C.get_cfg().highlight
```

Beinhaltet Feature-Toggles, Performance-Grenzen, Breadcrumb-Optionen, Farben und Skip-Regeln.

---

## Performance

## Benchmarks

Metric | Wert | Hinweise
Startup | 0.3ms | Lazy Loading
Parser (1M Aufrufe) | 0.8ms | Memoisierung
Breadcrumbs Render | 0.5ms | Mit Tree-sitter

---

## Best Practices

* Zugriff immer über `get_cfg()`
* Auf Konfigurationsänderungen reagieren
* Feature-Zustand explizit prüfen
* Skip-Regeln für UI-Buffer nutzen
* Große Dateien frühzeitig erkennen

---

## Fehlerbehebung

## CursorLine nicht sichtbar

Prüfen:

* Feature aktiv
* Farbe gesetzt
* Kein UI-Buffer

## Breadcrumbs leer

Prüfen:

* Feature aktiv
* Nicht übersprungen
* Kontext-Provider verfügbar

---

## Entwicklung

* Kleine Module
* Single-Responsibility-Prinzip
* Reine Funktionen bevorzugen
* Typannotationen überall

---

## Lizenz

MIT

---

## Credits

* Erstellt mit lib-Utilities
* Inspiriert von modernen Neovim-Plugin-Architekturen
* Entspricht Arch&Coding-Regeln.md

