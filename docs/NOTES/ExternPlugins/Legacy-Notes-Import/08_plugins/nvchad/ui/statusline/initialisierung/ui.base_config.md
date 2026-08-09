# Statusline-Initialisierung in NVChad: Warum `ui.base_config` kein Theme setzen darf

## Table of content

  - [Überblick](#berblick)
  - [Ausgangssituation](#ausgangssituation)
  - [Symptom](#symptom)
  - [Technische Ursache](#technische-ursache)
    - [1. NVChad lädt `ui.base_config` extrem früh](#1-nvchad-ldt-uibase_config-extrem-frh)
    - [2. Setzen eines Statusline-Themes erzwingt sofortige Auswertung](#2-setzen-eines-statusline-themes-erzwingt-sofortige-auswertung)
    - [3. Zu diesem Zeitpunkt ist NVChad noch nicht initialisiert](#3-zu-diesem-zeitpunkt-ist-nvchad-noch-nicht-initialisiert)
  - [Wichtige (undokumentierte) Regel](#wichtige-undokumentierte-regel)
  - [Korrekte Architektur](#korrekte-architektur)
    - [Verantwortlichkeiten trennen](#verantwortlichkeiten-trennen)
  - [Korrekte Base-Konfiguration](#korrekte-base-konfiguration)
  - [Custom-Statusline in `chadrc.lua`](#custom-statusline-in-chadrclua)
  - [Warum der Fehler oft nur bei Session-Restore auftritt](#warum-der-fehler-oft-nur-bei-session-restore-auftritt)
  - [Fazit](#fazit)
  - [Literatur](#literatur)

---

## Überblick

Beim Modularisieren der Statusline in NVChad tritt ein subtiler, aber kritischer Fehler auf, sobald in `ui.base_config` aktive Statusline-Module **und gleichzeitig** ein Statusline-Theme gesetzt werden.
Dieser Artikel beschreibt die Ursache, die internen Abläufe in NVChad und die einzig stabile Architektur, um eigene Module (z. B. Cursor- oder Progress-Anzeigen) sauber einzubinden.

---

## Ausgangssituation

Man möchte:

* eigene Statusline-Module entwickeln
* diese modular kapseln (Renderer, Controller, Calculators)
* ein Fallback definieren, falls die Custom-Statusline nicht geladen werden kann
* dabei NVChad-konform bleiben

Typischer Ansatz:

* `ui.base_config` enthält eine minimale, aber funktionale Statusline
* `chadrc.lua` überschreibt diese bei Bedarf

Sobald jedoch in `ui.base_config` Folgendes vorkommt:

```lua
ui = {
  statusline = {
    theme = "vscode_colored",
    modules = {
      cursor = function()
        ...
      end,
    },
  },
}
```

kommt es reproduzierbar zu einem Crash.

---

## Symptom

Beim Start von Neovim, insbesondere beim Session-Restore (`:source last.vim`), erscheint:

```
attempt to call local 'module' (a nil value)
E15: Invalid expression: "v:lua.require('nvchad.stl.vscode_colored')()"
```

Der Fehler tritt **auch dann auf**, wenn:

* keine eigenen NVChad-Utils verwendet werden
* das Modul nur rohe Statusline-Strings zurückgibt
* alle `require`-Aufrufe per `pcall` abgesichert sind

---

## Technische Ursache

### 1. NVChad lädt `ui.base_config` extrem früh

* vor `chadrc.lua`
* vor vollständigem Plugin-Bootstrap
* teilweise noch während Session-Restore oder `BufReadPost`

### 2. Setzen eines Statusline-Themes erzwingt sofortige Auswertung

Sobald `ui.statusline.theme` gesetzt ist, erzeugt NVChad intern folgenden Ausdruck:

```
v:lua.require('nvchad.stl.<theme>')()
```

Dieser wird **bei jedem Redraw** ausgeführt.

### 3. Zu diesem Zeitpunkt ist NVChad noch nicht initialisiert

* `nvchad.stl.utils` ist noch nicht bereit
* interne `module()`-Resolver sind `nil`
* selbst das reine Laden des Themes schlägt fehl

Ergebnis: Hard-Crash, unabhängig vom eigenen Code.

---

## Wichtige (undokumentierte) Regel

`ui.base_config` darf **kein Statusline-Theme setzen**, sobald dort **irgendein** Modul definiert ist.

Das ist kein Bug im eigenen Code, sondern eine Folge der NVChad-Initialisierungsreihenfolge.

---

## Korrekte Architektur

### Verantwortlichkeiten trennen

| Ebene              | Aufgabe                        |
| ------------------ | ------------------------------ |
| `ui.base_config`   | früh, minimal, inert           |
| `chadrc.lua`       | spät, vollständig, theme-aware |
| Renderer           | reine Strings                  |
| Controller / Logic | Zustand, Modus, Berechnung     |

---

## Korrekte Base-Konfiguration

```lua
---@module 'ui.base_config'
--- Minimal, early-safe UI configuration.

---@return table
return {
  ui = {
    statusline = {
      -- WICHTIG: kein theme im Base-Layer
      order = {},
      modules = {
        --- Minimaler Cursor, keine NVChad-Abhängigkeiten.
        --- @return string
        cursor = function()
          local ok_r, renderer = pcall(require, "ui.CursorCtl.renderer")
          local ok_p, pct = pcall(require, "ui.CursorCtl.progress_calculators")

          if not ok_r then
            return " Ln %l, Col %v "
          end

          local parts = { renderer.cursor_classic() }

          if ok_p then
            parts[#parts + 1] = renderer.pct_token(pct.compute_row_pct(), "R")
          end

          return table.concat(parts, "")
        end,
      },
    },
  },
}
```

Eigenschaften:

* kein `theme`
* keine `%=`-Layout-Elemente
* keine `nvchad.stl.*` Utilities
* absolut stabil beim Bootstrap und Session-Restore

---

## Custom-Statusline in `chadrc.lua`

```lua
M.ui = {
  statusline = {
    theme = "vscode_colored",

    order = {
      "mode",
      "git",
      "%=",
      "diagnostics",
      "cursor",
      "cwd",
    },

    modules = {
      -- volle NVChad-Integration
    },
  },
}
```

Hier ist es **sicher**, da:

* NVChad vollständig initialisiert ist
* `nvchad.stl.utils` existiert
* Theme-Module korrekt geladen werden können

---

## Warum der Fehler oft nur bei Session-Restore auftritt

Session-Restore triggert:

```
BufReadPost
→ redrawstatus
→ Statusline-Auswertung
```

Wenn das Theme zu diesem Zeitpunkt bereits gesetzt ist, aber NVChad noch bootstrapped:

→ sofortiger Crash.

---

## Fazit

* `ui.base_config` ist kein Ort für aktive Statusline-Themes
* selbst minimale Module + Theme reichen für einen Crash
* die einzig stabile Lösung ist eine **inert gehaltene Base-Config**
* vollständige Statusline-Logik gehört ausschließlich in `chadrc.lua`

Diese Trennung ist essenziell für robuste, modulare NVChad-Konfigurationen.

---

## Literatur

* NVChad Source: `lua/nvchad/stl/*`
* NVChad Bootstrap-Reihenfolge (implizit durch Lazy.nvim)
* Eigene Tests mit Session-Restore und frühem Redraw

---
