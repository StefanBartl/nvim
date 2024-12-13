Um ein benutzerdefiniertes Lua-Plugin für NVChad zu erstellen, das die gewünschte Funktionalität direkt im Plugin implementiert, folgen wir diesen Schritten:

1. **Erstelle ein neues Lua-Plugin in der NVChad-Konfiguration.**
2. **Implementiere die Funktionalität im Plugin selbst, ohne ein externes Skript zu verwenden.**
3. **Stelle sicher, dass die Lazy-Plugin-Manager-Konfiguration und NVChad-spezifische Mappingsyntax eingehalten wird.**

Hier ist eine Schritt-für-Schritt-Anleitung:

### Schritt 1: Verzeichnisstruktur erstellen

Füge das Plugin zu NVChad hinzu, indem du in `~/.config/nvim/lua/plugins/` eine neue Datei für das Plugin erstellst. 

**Erstelle die Datei:**
```bash
mkdir -p ~/.config/nvim/lua/plugins
nano ~/.config/nvim/lua/plugins/underline_headings.lua
```

### Schritt 2: Plugin-Code schreiben

In der Datei `underline_headings.lua` fügst du den folgenden Code hinzu:

```lua
-- Datei: ~/.config/nvim/lua/plugins/underline_headings.lua

return {
  "custom/underline-headings",
  lazy = false, -- Plugin wird sofort geladen
  config = function()
    -- Funktion zur Bearbeitung der aktuellen Datei
    local function add_underline_to_headings()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local new_lines = {}
      
      for _, line in ipairs(lines) do
        -- Überprüfen, ob es sich um eine Überschrift handelt
        local is_heading = line:match("^%s*#+%s")
        table.insert(new_lines, line)

        if is_heading then
          -- Länge des Textes ohne "#" zählen
          local heading_text = line:gsub("^%s*#+%s*", "")
          local underline = string.rep("=", #heading_text)
          table.insert(new_lines, underline)
        end
      end

      -- Neue Zeilen in den aktuellen Buffer schreiben
      vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
    end

    -- NVChad-spezifische Keymap-Syntax
    local map = {
      n = { -- Normalmodus
        ["<leader>mm"] = {
          function() add_underline_to_headings() end,
          "Add underline to Markdown headings",
        },
      },
    }

    -- Funktion zum Registrieren der Mappings
    require("core.utils").load_mappings(map)
  end,
}
```

### Schritt 3: Lazy-Plugin-Manager-Konfiguration

Der obige Code erstellt ein Plugin namens `underline-headings` und definiert die Funktionalität sowie eine entsprechende Keymap. Da NVChad den Lazy-Manager verwendet, haben wir das Plugin so konfiguriert, dass es direkt geladen wird (`lazy = false`). 

### Erklärung des Codes:
1. **Funktion `add_underline_to_headings`:** 
   - Liest alle Zeilen der aktuellen Datei.
   - Überprüft, ob eine Zeile eine Überschrift ist (beginnt mit `#`).
   - Fügt eine Zeile mit `=`-Zeichen hinzu, deren Länge der Überschrift entspricht.
   - Schreibt die neuen Zeilen in den Buffer zurück.

2. **NVChad-Mappings:** 
   - Wir haben die Mappings in der Form konfiguriert, die `core.utils.load_mappings` verwendet. Dies entspricht der Syntax und Struktur, die NVChad erwartet.

### Schritt 4: Plugin in NVChad aktivieren

Öffne die Datei `~/.config/nvim/lua/custom/chadrc.lua` und füge das Plugin zu `plugins` hinzu:
```lua
plugins = {
  -- Dein Plugin hinzufügen
  { import = "plugins.underline_headings" },
}
```

### Schritt 5: NVChad neu laden

Starte Neovim neu oder lade die Plugins und Konfiguration neu:
```vim
:Lazy sync
```

### Anwendung:
Drücke `<leader>mm` im Normalmodus, um die Funktion `add_underline_to_headings` auszuführen. Sie wird die aktuellen Überschriften der Markdown-Datei finden und entsprechend mit `=`-Zeichen unterstreichen.

### Vorteile:
- **Direkt in Lua implementiert:** Kein externes Skript erforderlich.
- **Lazy-Kompatibel:** Plugin wird ordnungsgemäß in NVChad integriert.
- **Einheitliche NVChad-Mappings:** Sauber und konsistent mit anderen Plugins und Mappings. 

Damit hast du ein elegantes, benutzerdefiniertes Plugin, das voll in NVChad integriert ist und einfach erweitert werden kann.