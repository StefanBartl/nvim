# Kernproblem

NvChad's tabufline ist nur verfügbar, wenn `require("nvconfig").ui.tabufline.enabled` true ist. Wenn deaktiviert, gibt `require("nvchad.tabufline")` ein boolean zurück statt einer Tabelle.

## Lösung: Defensive Detection

```lua
--- Check if NvChad tabufline is available and enabled.
--- Returns the tabufline module if available, nil otherwise.
---@return table|nil
local function get_nvchad_tabufline()
  -- First check if tabufline is enabled in config
  local ok_config, nvconfig = pcall(require, "nvconfig")
  if not ok_config then
    return nil
  end

  -- Check if UI and tabufline are enabled
  if type(nvconfig) ~= "table"
     or type(nvconfig.ui) ~= "table"
     or type(nvconfig.ui.tabufline) ~= "table"
     or not nvconfig.ui.tabufline.enabled then
    return nil
  end

  -- Now try to load the actual module
  local ok_tabufline, tabufline = pcall(require, "nvchad.tabufline")

  -- Verify it's actually a table with the close_buffer function
  if not ok_tabufline
     or type(tabufline) ~= "table"
     or type(tabufline.close_buffer) ~= "function" then
    return nil
  end

  return tabufline
end
```

Die neue Funktion `get_nvchad_tabufline()`:

1. **Prüft zuerst die Config**: Ob `nvconfig.ui.tabufline.enabled` true ist
2. **Dann erst das Modul**: Lädt `nvchad.tabufline` nur wenn enabled
3. **Verifiziert den Typ**: Stellt sicher, dass es eine Tabelle mit `close_buffer()` ist
4. **Gibt nil zurück**: Wenn irgendeine Bedingung fehlschlägt

### Debug-Schritte

Prüfe, was bei dir aktuell gesetzt ist:

```lua
:lua vim.print(require("nvconfig").ui.tabufline)
```

Falls tabufline deaktiviert ist, aktiviere es in deiner `nvconfig.lua` (normalerweise in `lua/nvconfig.lua` oder als Teil der NvChad-Config):

```lua
M.ui = {
  tabufline = {
    enabled = true,  -- Stelle sicher, dass das true ist
    lazyload = true,
  },
}
```

