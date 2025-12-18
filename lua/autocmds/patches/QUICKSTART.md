# Quick Start - Patch-System

## 🚀 Sofort loslegen

### 1. Installation überprüfen

```vim
:lua vim.print(require("autocmds.patches").list())
```

Sollte die Liste der registrierten Patches anzeigen.

---

### 2. Alle Patches anwenden

```vim
:lua require("autocmds.patches").apply_all_async()
```

**Was passiert:**
- Asynchrone Anwendung aller enabled Patches
- Automatisches Skip bereits angewendeter Patches
- Benachrichtigung bei Erfolg/Fehlschlag

---

### 3. Status prüfen

```vim
:lua vim.print(require("autocmds.patches").get_status())
```

**Status-Typen:**
- `applied` ✅ - Erfolgreich angewendet
- `already_applied` ⏭️ - Bereits vorhanden (übersprungen)
- `failed` ❌ - Fehlgeschlagen
- `disabled` ⏸️ - Deaktiviert

---

### 4. Logs anzeigen

```vim
:lua require("autocmds.patches").show_logs_buffer()
```

Öffnet Log-Datei in neuem Buffer.

---

## 🔧 Häufige Kommandos

### Nur bestimmte Repos patchen

```lua
require("autocmds.patches").apply_async({
  repos = { "gitsigns.nvim" }
})
```

### Nur bestimmte Patches

```lua
require("autocmds.patches").apply_async({
  keys = { "gitsigns-system-compat" }
})
```

### Status abfragen

```lua
-- Nur fehlgeschlagene
local failed = require("autocmds.patches").get_status({
  status_filter = { "failed" }
})
vim.print(failed)

-- Nur gitsigns.nvim
local gitsigns = require("autocmds.patches").get_status({
  repos = { "gitsigns.nvim" }
})
vim.print(gitsigns)
```

### Validierung (Dry-Run)

```lua
require("autocmds.patches").validate_all(function(results)
  print("Validation complete:", #results)
end)
```

---

## 🐛 Debugging

### Verbose-Modus aktivieren

```lua
-- In init.lua NACH dem require von patches
require("autocmds.patches").setup({
  verbose = true,  -- Aktiviert DEBUG-Logging
})
```

### Logs filtern

```lua
-- Nur ERROR-Level
local errors = require("autocmds.patches").get_logs({
  level = "ERROR",
  limit = 20
})
vim.print(errors)
```

### Einzelnen Patch testen

```lua
require("autocmds.patches").apply_async({
  keys = { "gitsigns-system-compat" },
  callback = function(results)
    vim.print(results[1])
  end
})
```

---

## 💡 Tipps

### 1. Nach Plugin-Update prüfen

```vim
:Lazy update
" System wendet automatisch Patches an (nach 500ms)
" Oder manuell:
:lua require("autocmds.patches").apply_all_async()
```

### 2. Status-Cache leeren (bei Problemen)

```vim
:lua require("autocmds.patches").clear_status()
```

### 3. Patch temporär deaktivieren

In `paths.lua`:

```lua
{
  key = "my-patch",
  enabled = false,  -- Deaktiviert
  -- ...
}
```

### 4. Logs rotieren

Logs rotieren automatisch bei >100KB. Manuell leeren:

```bash
rm ~/.local/share/nvim/cache/patches/patches.log
```

---

## ⚡ Performance-Tuning

### Mehr parallele Patches

```lua
require("autocmds.patches").setup({
  max_concurrency = 5,  -- Default: 3
})
```

### Kürzerer Timeout

```lua
require("autocmds.patches").setup({
  timeout_ms = 15000,  -- Default: 30000 (30s)
})
```

### Lazy-Update-Delay anpassen

```lua
require("autocmds.patches").setup({
  lazy_update_delay_ms = 1000,  -- Default: 500
})
```

---

## 🔍 Fehlerbehebung

### Problem: "Patch file not found"

**Lösung:**
1. Pfad in `paths.lua` prüfen
2. Datei existiert?
   ```bash
   ls -la ~/.config/nvim/patches/gitsigns/system/compat/diff.patch
   ```

### Problem: "Target file not found"

**Lösung:**
1. Plugin installiert?
   ```vim
   :Lazy
   ```
2. Pfad korrekt?
   ```bash
   ls -la ~/.local/share/nvim/lazy/gitsigns.nvim/lua/gitsigns/system/compat.lua
   ```

### Problem: "Patch already applied"

**Status:**
✅ Normal - bedeutet Patch ist bereits aktiv.

**Force Re-Apply:**
```vim
" Status leeren
:lua require("autocmds.patches").clear_status()
" Neu anwenden
:lua require("autocmds.patches").apply_all_async()
```

### Problem: "Failed with exit code 1"

**Lösung:**
1. Logs prüfen:
   ```vim
   :lua require("autocmds.patches").show_logs_buffer()
   ```
2. Manuell testen:
   ```bash
   cd ~/.local/share/nvim/lazy/gitsigns.nvim
   patch --dry-run -p0 -i ~/.config/nvim/patches/gitsigns/system/compat/diff.patch lua/gitsigns/system/compat.lua
   ```
3. Strip-Level anpassen (meist 0, 1, oder 2):
   ```lua
   {
     strip = 1,  -- Statt 0
     -- ...
   }
   ```

---

## 📖 Weitere Hilfe

- **Vollständige Doku:** Siehe `README.md`
- **API-Referenz:** Siehe `@types.lua`
- **Changelog:** Siehe `CHANGELOG.md`
