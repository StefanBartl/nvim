# 1. Problem-Beschreibung

- bei großen cwd hängt es sich einfach auf

## Symptome
- Picker schließt sich nach Auswahl
- Cursor flackert/blinkt unregelmäßig schneller
- UI ist teilweise frozen (Neotree reagiert nicht auf Enter)
- Nach 2-3 Sekunden: Write-Erfolgsmeldung, dann normaler Betrieb
- Verhalten identisch bei `WRITE_STRATEGY = "async"` und `"sync"`

## Root Cause
**Die gesamte Migration-Pipeline läuft synchron im UI-Thread**, nur der finale `fs_write` Call ist asynchron.

### Blockierungs-Kette:
```lua
-- picker.lua: <CR> pressed
actions.select_default:replace(function()
  -- ... selection logic ...
  opts.on_apply(matches_to_apply)  -- ⚠️ BLOCKS HERE
end)

-- init.lua: apply_matches()
for bufnr, data in pairs(by_buffer) do
  buffer_ops.create_undo_point(bufnr)         -- sync
  refactor.inject_import(bufnr, module_name)  -- sync, nvim_buf_set_lines

  local fresh_matches = parser.scan_buffer(bufnr)  -- sync, regex parsing
  local updated_matches = to_common_matches(...)   -- sync

  for _, match in ipairs(updated_matches) do
    refactor.apply_match(bufnr, parser_match)  -- sync, nvim_buf_set_lines
  end

  refactor.remove_aliases(bufnr)  -- sync, nvim_buf_set_lines
end

-- write.lua: batch_write()
write_ops.batch_write(write_jobs, "async", callback)  -- ⚠️ Async, aber zu spät
```

### Warum blockiert es?
1. **Buffer-Operationen sind synchron**: `nvim_buf_set_lines()` ist nicht deferbar
2. **Kein Yield**: Zwischen den Buffer-Operationen gibt es kein `vim.schedule()` → kein Event-Loop-Durchlauf
3. **Neovim UI-Refresh**: Jeder `nvim_buf_set_lines()` Call triggert Screen-Redraw → Cursor-Flackern
4. **Async kommt zu spät**: `uv.fs_write()` läuft async, aber Migration davor blockiert bereits

### Measurements (geschätzt):
- **Picker Close → Migration Start**: 0ms (synchron)
- **Migration (5 Buffers)**: ~150-300ms (Parser + Buffer Ops)
- **Async Write**: ~50-100ms (I/O, non-blocking)
- **Total UI Freeze**: ~150-300ms

## Lösungsansätze

### Quick Fix (Lösung 1): Defer gesamte Migration
```lua
vim.schedule(function()
  -- Gesamte apply_matches Logik hier
end)
```
**Effekt**: Picker schließt sofort, Migration läuft im nächsten Event-Loop Tick.

### Best Practice (Lösung 2): Chunked Processing
```lua
local function process_chunk()
  -- Verarbeite 5 Buffers
  -- ...
  if more_work then
    vim.schedule(process_chunk)  -- Yield
  end
end
```
**Effekt**: UI bleibt responsive, Fortschritt sichtbar.

### Vergleich:
| Lösung | UI Freeze | Komplexität | CWD (50 Files) |
|--------|-----------|-------------|----------------|
| Aktuell | 300ms | Niedrig | 3000ms (!!) |
| Defer | ~0ms | Niedrig | ~0ms (aber spürbar langsamer) |
| Chunked | ~0ms | Mittel | ~0ms (optimal) |

## Empfehlung
1. **Sofort**: Lösung 1 implementieren (wrap in `vim.schedule`)
2. **Follow-up**: Lösung 2 für CWD-Scans mit >10 Files
3. **Nice-to-have**: Progress Indicator (`⏳ Migrating 5/50...`)

---

