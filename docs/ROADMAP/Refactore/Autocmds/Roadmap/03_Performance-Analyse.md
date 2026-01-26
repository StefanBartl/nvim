# Performance-Schätzung

## Table of content

- [Performance-Schätzung](#performance-schtzung)
  - [Hot Path (`CursorMoved`)](#hot-path-cursormoved)
  - [Frequent Events (`BufEnter`)](#frequent-events-bufenter)
  - [Write Path (`BufWritePre`)](#write-path-bufwritepre)
  - [Weitere Goodies](#weitere-goodies)
    - [1. **Debugbarkeit**](#1-debugbarkeit)
    - [2. **Lazy Handler Loading**](#2-lazy-handler-loading)
    - [3. **Metriken**](#3-metriken)
    - [4. **User Commands**](#4-user-commands)

---

## Hot Path (`CursorMoved`)

**Vorher (5 separate Autocmds):**
```
BufEnter: nvim_buf_get_name()       ~0.02ms
          nvim_buf_get_lines()       ~0.15ms (1000 lines)
Git:      nvim_buf_get_name()       ~0.02ms
          nvim_buf_get_lines()       ~0.15ms
Cword:    nvim_win_get_cursor()     ~0.01ms
          nvim_buf_get_lines()       ~0.15ms
Indent:   nvim_buf_get_lines()       ~0.15ms
Breadcr:  nvim_buf_get_name()       ~0.02ms
────────────────────────────────────────────
Total:                               ~0.67ms
```

**Nachher (1 Dispatcher + Context):**
```
Context:  nvim_buf_get_name()       ~0.02ms
          nvim_buf_get_lines()       ~0.15ms (cached)
          nvim_win_get_cursor()     ~0.01ms
Dispatch: 4× handler.run(ctx)       ~0.30ms (parallel)
────────────────────────────────────────────
Total:                               ~0.48ms
```

**Gewinn:** ~28% (0.19ms pro Event)
**Bei 100 CursorMoved/s:** ~19ms/s gespart

## Frequent Events (`BufEnter`)

**Vorher:** 11 separate Callbacks → ~0.8ms
**Nachher:** 1 Dispatcher + Context → ~0.5ms
**Gewinn:** ~37%

## Write Path (`BufWritePre`)

**Vorher:** Sequenziell, keine Koordination → ~15ms
**Nachher:** Priorisierte Pipeline, deduplizierte Formatierung → ~8ms
**Gewinn:** ~47%

---

## Weitere Goodies

### 1. **Debugbarkeit**
```lua
-- autocmds/init.lua
local DEBUG = vim.env.NVIM_AUTOCMD_DEBUG == "1"

if DEBUG then
  vim.api.nvim_create_autocmd("*", {
    callback = function(ev)
      print(string.format("[%s] %s (buf=%d)", ev.event, ev.match, ev.buf))
    end,
  })
end
```

### 2. **Lazy Handler Loading**
```lua
-- autocmds/events/frequent/buf_enter.lua
local handlers = {
  markdown = function() return require("autocmds.handlers.markdown.keymaps") end,
  neotree = function() return require("autocmds.handlers.ui.neotree_sync") end,
}

for name, loader in pairs(handlers) do
  local handler = loader()
  if handler.should_run(ctx) then
    handler.run(ctx)
  end
end
```

### 3. **Metriken**
```lua
-- autocmds/context/cache.lua
local M = {}
M.stats = { hits = 0, misses = 0 }

function M.get(key)
  if cache[key] then
    M.stats.hits = M.stats.hits + 1
    return cache[key]
  end
  M.stats.misses = M.stats.misses + 1
  return nil
end

-- :lua print(vim.inspect(require("autocmds.context.cache").stats))
```

### 4. **User Commands**
```lua
-- usercmds/autocmds.lua
vim.api.nvim_create_user_command("AutocmdStats", function()
  local ctx = require("autocmds.context.cache")
  print(string.format("Cache hits: %d | misses: %d | ratio: %.2f%%",
    ctx.stats.hits, ctx.stats.misses,
    ctx.stats.hits / (ctx.stats.hits + ctx.stats.misses) * 100))
end, {})
```

---

