# Neovim Recommender Plugin

Ein Neovim-Plugin, das wiederholte Lua-Chains analysiert und lokale Alias-Vorschläge macht.

## Features

- 🔍 Findet wiederholte Chains wie `vim.api`, `table.insert`, etc.
- 📊 Zwei Analyse-Modi: Regex und Treesitter
- 🎯 Interaktives Float-Window mit Navigation
- 💾 Persistente Ignore-Liste pro Buffer
- ⚙️ Anpassbare Custom-Aliases
- 🎨 Cursorline-Highlighting

## Installation

```lua
    require("custom.recommender").setup({
      analyzer = "regex",  -- oder "treesitter"
      threshold = 3,       -- Minimale Anzahl Vorkommen
      custom_aliases = {
        ["table.insert"] = "tbl_insert",
        ["table.concat"] = "tbl_concat",
        ["string.format"] = "fmt",
        ["vim.api"] = "api",
        ["vim.fn"] = "fn",
      },
    })
```

## Verwendung

### Command

```vim
" Standard (verwendet konfigurierte Einstellungen)
:Recommender

" Mit spezifischem Analyzer
:Recommender treesitter

" Mit spezifischem Threshold
:Recommender regex 5

" Beides kombiniert
:Recommender treesitter 4

" Mit Replace-Mode (-r): Nach Einfügen automatisch ersetzen
:Recommender -r
:Recommender -r regex 3
:Recommender --replace treesitter 5
```

### Replace-Mode Feature

Mit dem `-r` oder `--replace` Flag wird nach dem Einfügen eines Alias automatisch der `:Replace` Command ausgeführt:

**Beispiel-Workflow:**
1. Buffer enthält mehrfach `vim.api.nvim_create_buffer(...)`
2. `:Recommender -r` ausführen
3. `local api = vim.api` mit Enter einfügen
4. **Automatisch wird ausgeführt:** `:Replace vim.api api %`
5. Alle Vorkommen von `vim.api` werden durch `api` ersetzt

**Voraussetzung:** Das `:Replace` Command muss verfügbar sein.

### Keybindings im Float-Window

| Key | Aktion |
|-----|--------|
| `j` / `↓` | Nächster Eintrag |
| `k` / `↑` | Vorheriger Eintrag |
| `Enter` | Vorschlag einfügen |
| `Backspace` | Eintrag ignorieren |
| `U` | Alle ignorierten zurücksetzen |
| `q` / `Esc` | Schließen |
| `?` | Hilfe anzeigen |

## Beispiel

Angenommen, dein Buffer enthält:

```lua
vim.api.nvim_create_user_command(...)
vim.api.nvim_buf_set_lines(...)
vim.api.nvim_win_set_cursor(...)
table.insert(tbl, value)
table.insert(tbl, another)
table.insert(tbl, third)
```

Das Plugin schlägt vor:

```
→ vim.api (3 hits)
  local api = vim.api

→ table.insert (3 hits)
  local tbl_insert = table.insert
```

Nach dem Einfügen des ersten Vorschlags kannst du schreiben:

```lua
local api = vim.api

api.nvim_create_user_command(...)
api.nvim_buf_set_lines(...)
api.nvim_win_set_cursor(...)
```

## Konfiguration

### Analyzer

**Regex** (Standard):
- Schneller
- Funktioniert immer
- Weniger präzise

**Treesitter**:
- Präziser
- Erfordert Treesitter-Parser für Lua
- Etwas langsamer

### Custom Aliases

Du kannst spezifische Alias-Namen für bestimmte Chains definieren:

```lua
require("custom.recommender").setup({
  custom_aliases = {
    -- Chain = bevorzugter Alias-Name
    ["vim.api"] = "api",
    ["vim.fn"] = "fn",
    ["vim.keymap"] = "keymap",
    ["table.insert"] = "tbl_insert",
    ["table.concat"] = "tbl_concat",
    ["string.format"] = "fmt",
    ["string.match"] = "match",
    ["math.floor"] = "floor",
  },
})
```

### Threshold

Der Threshold bestimmt, wie oft eine Chain mindestens vorkommen muss:

```lua
require("custom.recommender").setup({
  threshold = 3,  -- Minimum 3x
})
```

## Workflow-Beispiel

1. Öffne eine Lua-Datei mit vielen wiederholten Chains
2. Führe `:Recommender` aus
3. Navigiere mit `j`/`k` durch die Vorschläge
4. Drücke `Enter`, um einen Vorschlag am Cursor einzufügen
5. Drücke `Backspace`, um Einträge zu ignorieren, die du nicht willst
6. Drücke `U`, um alle Ignorierungen zurückzusetzen

## Troubleshooting

### Plugin friert ein
- Stelle sicher, dass du die neueste Version verwendest
- Versuche den `regex`-Analyzer statt `treesitter`
- Erhöhe den Threshold

### Keine Vorschläge
- Prüfe, ob der Threshold zu hoch ist
- Stelle sicher, dass tatsächlich wiederholte Chains existieren
- Versuche beide Analyzer

### Treesitter funktioniert nicht
- Installiere den Lua-Parser: `:TSInstall lua`
- Verwende alternativ den `regex`-Analyzer

## Lizenz

MIT

## Autor

Dein Name
