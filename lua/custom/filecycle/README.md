# filecycle – Dateien im aktuellen Verzeichnis vor/zurück laden

## Table of content

- [Kurzbeschreibung](#kurzbeschreibung)
- [Hauptmerkmale](#hauptmerkmale)
- [Installation (Lazy.nvim, lokales Modul)](#installation-lazynvim-lokales-modul)
- [Schnellstart](#schnellstart)
  - [Keymaps](#keymaps)
  - [User-Commands](#user-commands)
- [Konfiguration](#konfiguration)
- [Funktionsweise](#funktionsweise)
- [Edge-Cases](#edge-cases)
- [Beispiele](#beispiele)
- [API](#api)
- [Troubleshooting](#troubleshooting)
- [Kompatibilität](#kompatibilitt)
- [Minimalbeispiel (ohne Lazy)](#minimalbeispiel-ohne-lazy)

---

## Kurzbeschreibung

Kleines, zustandsloses Modul, das zwischen Dateien im Verzeichnis des aktuellen Buffers vor- bzw. zurückspringt. Es öffnet die nächste/vorherige Datei alphabetisch sortiert (optional case-insensitive), berücksichtigt versteckte Dateien, Symbol-Links und kann wahlweise:

- **Buffer-Inhalt ersetzen** (Standard) → `<leader>nf` / `<leader>pf`
- **Neuer Buffer, alter bleibt** (stay mode) → `<leader>nfn` / `<leader>pfn`
- **im Hintergrund** (neuer Buffer ohne Wechsel) → `<leader>nF` / `<leader>pF`
- **in Vsplit** → `<leader>NF` / `<leader>PF`
- **via User-Command** mit Argument → `:NextFile %/stay/new/bg/split/vsplit/tab`

Bei ungespeicherten Änderungen im aktuellen Buffer (nur bei "replace"-Modus) erscheint ein **hover_select-Popup** mit 3 Optionen:
1. **Save and open** – speichert und öffnet
2. **Discard changes and open** – verwirft Änderungen
3. **Cancel** – bricht ab

---

## Hauptmerkmale

• **Kontext**: Verzeichnis des aktuellen Buffers oder globales `:cwd`
• **Reihenfolge**: alphabetisch, optional case-insensitive
• **Grenzen**: optionales Wrap am Anfang/Ende
• **Versteckte Dateien**: optional inkludieren
• **Symlinks**: echte Pfade via `fs_realpath` (konfigurierbar)
• **Sicherheit**: `hover_select`-Dialog bei modifizierten Buffern (nur replace-Modus)
• **Modi**:
  - **replace** (Standard): Buffer-Inhalt direkt ersetzen
  - **stay**: Neuer Buffer, alter bleibt in Buffer-Liste
  - **background**: Buffer laden ohne Fokus
  - **split/vsplit/tab**: Splits und Tabs
• **API**: User-Commands, Keymaps und programmatischer Aufruf

---

## Installation (Lazy.nvim, lokales Modul)

```lua
{
  dir = vim.fn.stdpath("config") .. "/nvim/custom/filecycle",
  name = "filecycle",
  lazy = true,
  config = function()
    require("custom.filecycle").setup({
      open_target = "replace",     -- "replace"|"current"|"split"|"vsplit"|"tab"|"background"
      include_hidden = false,
      wrap = true,
      follow_symlinks = true,
      root = "buffer_dir",
      confirm_on_modified = true,  -- hover_select bei Änderungen (nur replace)
      case_insensitive = true,
    })
  end,
  keys = {
    -- Buffer-Inhalt ersetzen (Standard)
    { "<leader>nf", desc = "[filecycle] Next file (replace buffer)" },
    { "<leader>pf", desc = "[filecycle] Previous file (replace buffer)" },
    -- Stay mode: neuer Buffer, alter bleibt
    { "<leader>nfn", desc = "[filecycle] Next file (stay mode)" },
    { "<leader>pfn", desc = "[filecycle] Previous file (stay mode)" },
    -- Hintergrund-Buffer
    { "<leader>nF", desc = "[filecycle] Next file (background)" },
    { "<leader>pF", desc = "[filecycle] Previous file (background)" },
    -- Vsplit
    { "<leader>NF", desc = "[filecycle] Next file (vsplit)" },
    { "<leader>PF", desc = "[filecycle] Previous file (vsplit)" },
  },
  cmd = { "NextFile", "PreviousFile" },
}
```

---

## Schnellstart

### Keymaps

| Keymap         | Aktion                                     |
| -------------- | ------------------------------------------ |
| `<leader>nf`   | Nächste Datei **Buffer-Inhalt ersetzen** (Standard) |
| `<leader>pf`   | Vorherige Datei **Buffer-Inhalt ersetzen** |
| `<leader>nfn`  | Nächste Datei **stay mode** (neuer Buffer, alter bleibt) |
| `<leader>pfn`  | Vorherige Datei **stay mode** |
| `<leader>nF`   | Nächste Datei **im Hintergrund** (buffer)  |
| `<leader>pF`   | Vorherige Datei **im Hintergrund**         |
| `<leader>NF`   | Nächste Datei **in Vsplit**                |
| `<leader>PF`   | Vorherige Datei **in Vsplit**              |

### User-Commands

```vim
:NextFile              " Buffer-Inhalt ersetzen (% = default)
:NextFile %            " explizit Buffer ersetzen
:NextFile stay         " neuer Buffer, alter bleibt (stay mode)
:NextFile new          " neuer Buffer im Hintergrund
:NextFile bg           " neuer Buffer im Hintergrund (alias)
:NextFile background   " neuer Buffer im Hintergrund (alias)
:NextFile split        " horizontaler Split
:NextFile vsplit       " vertikaler Split
:NextFile tab          " neuer Tab

:PreviousFile          " vorherige Datei (Buffer ersetzen)
:PreviousFile stay     " vorherige Datei (stay mode)
:PreviousFile split    " vorherige Datei in Split
```

 **Bang-Varianten** (`:NextFile!`, `:PreviousFile!`) erzwingen Wechsel **ohne** `hover_select`-Dialog

---

## Konfiguration

| Option              | Typ                   | Standard     | Beschreibung                                |
| ------------------- | --------------------- | ------------ | ------------------------------------------- |
| open_target         | `"replace"`\|`"current"`\|... | `"replace"` | Standard-Öffnungsmodus |
| include_hidden      | `boolean`             | `false`      | Dotfiles (`.`) einbeziehen                  |
| wrap                | `boolean`             | `true`       | Am Ende/Anfang umbrechen                    |
| follow_symlinks     | `boolean`             | `true`       | Pfade via `fs_realpath` kanonisieren        |
| root                | `"buffer_dir"` \| `"cwd"` | `buffer_dir` | Bezugsverzeichnis für die Dateiliste        |
| confirm_on_modified | `boolean`             | `true`       | `hover_select`-Dialog bei geänderten Buffern (nur replace-Modus) |
| case_insensitive    | `boolean`             | `true`       | Sortierung und Matching ohne Groß/Klein     |

**Modi-Beschreibung:**
- **replace** (Standard): Ersetzt Buffer-Inhalt direkt (wie `:edit`)
- **current** (stay mode): Neuer Buffer, alter bleibt in Buffer-Liste
- **background**: Buffer laden ohne Fokus
- **split/vsplit/tab**: Splits und Tabs

---

## Funktionsweise

1. **Ermittlung des Wurzelverzeichnisses**: abhängig von `root` entweder Buffer-Verzeichnis (`buffer_dir`) oder `:cwd`
2. **Auflistung**: nicht-rekursiv via `vim.fs.dir`; Fallback-Typbestimmung via `uv.fs_stat`
3. **Filter**: nur reguläre Dateien; Dotfiles optional; Symlinks je nach `follow_symlinks` kanonisiert
4. **Sortierung**: alphabetisch; optional case-insensitive
5. **Position**: aktueller Buffername wird kanonisiert und im sortierten Array gesucht
6. **Navigation**: `next`/`prev`; bei `wrap=false` Meldung "boundary reached"
7. **Öffnen**:
   - **`<leader>nf` / `<leader>pf`** → `open_target = "replace"` (Buffer-Inhalt ersetzen)
   - **`<leader>nfn` / `<leader>pfn`** → `open_target = "current"` (stay mode)
   - **`<leader>nF` / `<leader>pF`** → `open_target = "background"` (Hintergrund)
   - **`<leader>NF` / `<leader>PF`** → `open_target = "vsplit"`
   - **User-Commands** → Argument überschreibt (`%`, `stay`, `new`/`bg`/`background`, `split`, `vsplit`, `tab`)
8. **Sicherheit**: bei ungespeicherten Änderungen im aktuellen Buffer (nur bei `open_target = "replace"`):
   - **`hover_select`-Popup** mit 3 Optionen:
     1. **Save and open** – speichert und öffnet
     2. **Discard changes and open** – verwirft Änderungen
     3. **Cancel** – bricht ab
   - **Bang-Varianten** (`:NextFile!`) umgehen diesen Dialog

---

## Edge-Cases

- **Unbenannter Buffer**: Abbruch mit Hinweis
- **Leeres Verzeichnis**: Hinweis "no files in directory"
- **Aktuelle Datei nicht in Liste**: wird virtuell einsortiert für stabile Nachbarwahl
- **background-Modus**: lädt Buffer ohne Fensterwechsel
- **stay-Modus**: neuer Buffer, alter bleibt in Buffer-Liste
- **Split/Vsplit mit `keep_focus=true`**: Rücksprung via `vim.schedule`

---

## Beispiele

### Zum nächsten File springen (Buffer ersetzen)
```vim
:NextFile
" oder
<leader>nf
```

### Nächste Datei (stay mode - neuer Buffer, alter bleibt)
```vim
:NextFile stay
" oder
<leader>nfn
```

### Nächste Datei im Hintergrund laden
```vim
:NextFile new
" oder
<leader>nF
```

### Vorherige Datei in Vsplit öffnen
```vim
:PreviousFile vsplit
" oder
<leader>PF
```

### Wechsel erzwingen trotz Änderungen (kein hover_select)
```vim
:NextFile!
```

---

## API

```lua
-- Setup (einmalig)
require("custom.filecycle").setup({ wrap = true, case_insensitive = true })

-- Zur nächsten/vorherigen Datei springen (default: replace buffer)
require("custom.filecycle").open("next")
require("custom.filecycle").open("prev")

-- Mit Overrides (stay mode)
require("custom.filecycle").open("next", { open_target = "current" })

-- Mit anderen Overrides
require("custom.filecycle").open("next", { open_target = "background", include_hidden = true })
```

---

## Troubleshooting

| Problem                         | Ursache / Lösung                                                |
| ------------------------------- | --------------------------------------------------------------- |
| "no files in directory"         | Filter schließt alles aus oder Verzeichnis leer                 |
| "current buffer has no file name" | Unbenannter Buffer; Datei speichern oder `root="cwd"` nutzen  |
| "boundary reached (wrap disabled)" | `wrap=false` und Ende erreicht; `wrap=true` aktivieren       |
| Unerwartete Reihenfolge         | `case_insensitive` prüfen                                       |
| Symlink-Verhalten               | `follow_symlinks=false` kann Duplikate erzeugen                 |
| Buffer nicht ersetzt            | Prüfe `open_target="replace"` (Standard für `<leader>nf/pf`)  |

---

## Kompatibilität

- **Linux und macOS**
- **Neovim ≥ 0.9** (0.10+ empfohlen für `vim.fs`-APIs)

---

## Minimalbeispiel (ohne Lazy)

```lua
-- init.lua
require("custom.filecycle").setup()
vim.keymap.set("n", "<leader>nf", function()
  require("custom.filecycle").open("next")
end)
vim.keymap.set("n", "<leader>pf", function()
  require("custom.filecycle").open("prev")
end)
vim.keymap.set("n", "<leader>nfn", function()
  require("custom.filecycle").open("next", { open_target = "current" })
end)
vim.keymap.set("n", "<leader>pfn", function()
  require("custom.filecycle").open("prev", { open_target = "current" })
end)
```

---
