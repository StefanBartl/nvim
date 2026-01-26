# Fehleranalyse: "Invalid 'window': Expected Lua number"

## Ursache

Der Fehler tritt auf, weil die Neo-tree-Callbacks (`neo-tree-follow`, `filesystem_navigate`) versuchen, auf ein ungültiges Window-Handle zuzugreifen. Das passiert in folgender Sequenz:

1. Buffer-Wechsel triggert `cwd_sync`
2. `sync_now()` führt `cmd.execute()` aus
3. Neo-tree schließt das alte Fenster und öffnet ein neues
4. Während dieser Transition sind Window-Handles ungültig
5. Neo-tree's debounced Callbacks greifen auf das mittlerweile ungültige Window zu

## Root Cause

In `sync_now()` fehlt die **Window-Validierung** vor und nach dem `cmd.execute()` Call. Neo-tree's interne Callbacks erwarten ein gültiges Window, aber der Übergang zwischen Close/Open invalidiert das Handle.

## Fix-Strategie

```lua
-- BEFORE: Ungesichert
cmd.execute({
  action = "show",
  source = "filesystem",
  position = "left",
  dir = dir,
  reveal = true,
  reveal_file = path,
})

-- AFTER: Mit Window-Validierung
local neo_win = find_neotree_win()
if not neo_win and not cfg.open_if_closed then
  return -- Kein Window und sollte nicht öffnen
end

-- Validiere Window vor Execute
if neo_win and not vim.api.nvim_win_is_valid(neo_win) then
  neo_win = nil
end

local ok = pcall(function()
  cmd.execute({
    action = "show",
    source = "filesystem",
    position = "left",
    dir = dir,
    reveal = true,
    reveal_file = path,
  })
end)

if not ok then
  -- Cleanup und Retry-Logik
end
```

---

