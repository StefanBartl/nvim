# filecycle – Dateien im aktuellen Verzeichnis vor/zurück laden

## Kurzbeschreibung

Kleines, zustandsloses Modul, das zwischen Dateien im Verzeichnis des aktuellen Buffers vor- bzw. zurückspringt. Es öffnet die nächste/vorherige Datei alphabetisch sortiert (optional case-insensitive), berücksichtigt versteckte Dateien, Symbol-Links und kann wahlweise im aktuellen Fenster, Split, Vert-Split, Tab oder im Hintergrund öffnen.

---

## Hauptmerkmale

• Kontext: Verzeichnis des aktuellen Buffers oder globales :cwd
• Reihenfolge: alphabetisch, optional case-insensitive
• Grenzen: optionales Wrap am Anfang/Ende
• Versteckte Dateien: optional inkludieren
• Symlinks: echte Pfade via fs_realpath (konfigurierbar)
• Sicherheit: confirm edit bei modifizierten Buffern
• API: User-Commands, Keymaps und programmatischer Aufruf

---

## Installation (Lazy.nvim, lokales Modul)

```lua
{
  -- Pfad anpassen: hier als lokales Modul im config-Repo
  dir = vim.fn.stdpath("config") .. "/nvim/usrcmds/filecycle",
  name = "filecycle",
  lazy = true,
  config = function()
    require("usrcmds.filecycle").setup({
      open_target = "current",     -- "current"|"split"|"vsplit"|"tab"|"background"
      keep_focus = true,           -- bei Split/Vsplit Fokus im Ursprungsfenster behalten
      include_hidden = false,      -- Dotfiles ignorieren
      wrap = true,                 -- am Ende/Anfang umbrechen
      follow_symlinks = true,      -- echte Pfade für Vergleich/Öffnen nutzen
      root = "buffer_dir",         -- "buffer_dir"|"cwd"
      confirm_on_modified = true,  -- :confirm edit bei geänderten Buffern
      case_insensitive = true,     -- alphabetische Sortierung/Matching ohne Groß/Kleinschreibung
    })
  end,
  keys = {
    { "<leader>nf", function() require("usrcmds.filecycle").open("next") end, desc = "[filecycle] Next file" },
    { "<leader>pf", function() require("usrcmds.filecycle").open("prev") end, desc = "[filecycle] Previous file" },
  },
  cmd = { "NextFile", "PreviousFile" },
}
```

---

## Schnellstart

• `:NextFile` springt zur nächsten Datei im Verzeichnis des aktuellen Buffers.
• `:PreviousFile` springt zur vorherigen Datei.
• `:NextFile!` bzw. `:PreviousFile!` erzwingt den Wechsel auch bei modifiziertem Buffer (ohne :confirm).

---

## Konfiguration

### Optionen und Standards

| Option              | Typ                                                             | Standard     | Beschreibung                                        |
| ------------------- | --------------------------------------------------------------- | ------------ | --------------------------------------------------- |
| open_target         | `"current"` | `"split"` | `"vsplit"` | `"tab"` | `"background"` | `current`    | Ziel für das Öffnen                                 |
| keep_focus          | `boolean`                                                       | `true`       | Bei Split/Vsplit Fokus im Ursprungsfenster behalten |
| include_hidden      | `boolean`                                                       | `false`      | Dotfiles (`.*`) einbeziehen                         |
| wrap                | `boolean`                                                       | `true`       | Am Ende/Anfang umbrechen                            |
| follow_symlinks     | `boolean`                                                       | `true`       | Pfade via `fs_realpath` kanonisieren                |
| root                | `"buffer_dir"` | `"cwd"`                                        | `buffer_dir` | Bezugsverzeichnis für die Dateiliste                |
| confirm_on_modified | `boolean`                                                       | `true`       | `:confirm edit` bei geänderten Buffern              |
| case_insensitive    | `boolean`                                                       | `true`       | Sortierung und Matching ohne Groß/Klein             |

--

### User-Commands

• :NextFile – öffnet die nächste Datei; mit ! wird confirm_on_modified temporär deaktiviert.
• :PreviousFile – öffnet die vorherige Datei; mit ! wird confirm_on_modified temporär deaktiviert.

---

### Empfohlene Keymaps

```lua
vim.keymap.set("n", "<leader>nf", function()
  require("usrcmds.filecycle").open("next")
end, { desc = "[filecycle] Next file in directory", silent = true })

vim.keymap.set("n", "<leader>pf", function()
  require("usrcmds.filecycle").open("prev")
end, { desc = "[filecycle] Previous file in directory", silent = true })
```

---

## API

```lua
-- Setup (einmalig, z. B. im Plugin-Loader)
require("usrcmds.filecycle").setup({ wrap = true, case_insensitive = true })

-- Zur nächsten/vorherigen Datei springen (unter Beibehaltung globaler Defaults)
require("usrcmds.filecycle").open("next")
require("usrcmds.filecycle").open("prev")

-- Optional: per-Call Overrides (werden auf M.opts gemerged)
require("usrcmds.filecycle").open("next", { include_hidden = true, wrap = false })
```

---

## Funktionsweise

• Ermittlung des Wurzelverzeichnisses: abhängig von root entweder Buffer-Verzeichnis (buffer_dir) oder :cwd.
• Auflistung: nicht-rekursiv via vim.fs.dir; Fallback-Typbestimmung via uv.fs_stat.
• Filter: nur reguläre Dateien; Dotfiles optional; symbolische Links je nach follow_symlinks kanonisiert.
• Sortierung: alphabetisch; optional case-insensitive.
• Position: aktueller Buffername wird kanonisiert und im sortierten Array gesucht (bei Nicht-Fund wird er einsortiert, um „nächste“ Nachbarn stabil zu bestimmen).
• Navigation: next/prev; bei wrap=false Meldung „boundary reached“.
• Öffnen: abhängig von open_target; Fehler werden via vim.notify gemeldet.
• Sicherheit: confirm_on_modified schützt vor versehentlichem Verwerfen; :NextFile! / :PreviousFile! heben dies temporär auf.

---

### Edge-Cases und Verhalten

• Unbenannter Buffer: es wird abgebrochen mit Hinweis, da kein Verzeichnis ableitbar ist.
• Leeres Verzeichnis nach Filterung: Hinweis „no files in directory“.
• Aktuelle Datei nicht in Liste (z. B. Dotfile bei include_hidden=false): sie wird virtuell einsortiert, um eine stabile Nachbarwahl zu ermöglichen.
• background-Modus: lädt die Zieldatei als Buffer (bufadd/bufload), ohne Fenster zu wechseln.
• Split/Vsplit mit keep_focus=true: Rücksprung in das Ursprungsfenster erfolgt zeitversetzt via vim.schedule.

---

## Beispiele

• Zum nächsten File springen, Dotfiles ignorieren, mit Wrap:
`:NextFile`

• Zum vorherigen File springen, Wechsel erzwingen trotz Änderungen:
`:PreviousFile!`

• Temporär in Tabs navigieren:
`require("usrcmds.filecycle").open("next", { open_target = "tab" })`

---

## LuaLS-Typen (Referenz)

```lua
---@alias FilePath string

---@class FileCycle.Config
---@field open_target        "current"|"split"|"vsplit"|"tab"|"background"
---@field keep_focus         boolean
---@field include_hidden     boolean
---@field wrap               boolean
---@field follow_symlinks    boolean
---@field root               "buffer_dir"|"cwd"
---@field confirm_on_modified boolean
---@field case_insensitive   boolean

---@class FileCycle.State
---@field opts FileCycle.Config
```

---

## Troubleshooting

• Befehl macht „nichts“: sicherstellen, dass der aktuelle Buffer einen Dateinamen besitzt (:echo expand('%:p')).
• Immer „boundary reached“: wrap=false konfiguriert oder das Verzeichnis enthält nur die aktuelle Datei.
• Datei wird „übersprungen“: include_hidden=false und die Nachbarn sind Dotfiles; entweder include_hidden=true setzen oder Dateien umbenennen.
• Unerwartete Reihenfolge: case_insensitive prüfen; bei true werden Pfade in Kleinbuchstaben verglichen.
• Symlink-Verhalten: follow_symlinks=false kann dazu führen, dass die „gleiche“ Datei aus unterschiedlichen Linkpfaden als verschieden betrachtet wird.

---

## Leistungs- und Implementationshinweise

• Die Auflistung ist nicht-rekursiv und nutzt vim.fs.dir; für sehr große Verzeichnisse ist die Sortierung der dominante Schritt.
• canon() nutzt uv.fs_realpath, wenn erlaubt, um Deduplikation und Vergleich robuster zu machen.
• Es werden keine globalen Zustände geschrieben; das Modul arbeitet über M.opts und Funktionsaufrufe.

---

## Kompatibilität

• Linux und macOS; Pfadfunktionen basieren auf LibUV und Vim-APIs.
• Neovim ≥ 0.9 empfohlen; mit 0.10 stehen vim.fs-APIs stabiler zur Verfügung.

---

## Minimalbeispiel (ohne Lazy)

```lua
-- init.lua oder ein beliebiges geladenes Modul
require("usrcmds.filecycle").setup()
vim.keymap.set("n", "<leader>nf", function() require("usrcmds.filecycle").open("next") end)
vim.keymap.set("n", "<leader>pf", function() require("usrcmds.filecycle").open("prev") end)
```

---
