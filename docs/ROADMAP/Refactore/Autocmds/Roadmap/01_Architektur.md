# Architektur-Vorschlag

## Table of content

- [Architektur-Vorschlag](#architektur-vorschlag)
  - [Neue Struktur](#neue-struktur)
  - [Context-Factory Pattern](#context-factory-pattern)
  - [Event-Dispatcher Beispiel](#event-dispatcher-beispiel)

---

## Neue Struktur

```vim
lua/
  autocmds/
    init.lua                    # Zentrale Registrierung
    groups.lua                  # Augroup-Definitionen
    context/
      buffer.lua                # Buffer-Context-Factory
      window.lua                # Window-Context-Factory
      cache.lua                 # Event-spezifische Caches
    events/
      hot_path/
        cursor_moved.lua        # P0
        cursor_moved_i.lua      # P0
      frequent/
        buf_enter.lua           # P1
        buf_win_enter.lua       # P1
        buf_write_pre.lua       # P2
      lifecycle/
        vim_enter.lua           # P3
        vim_leave_pre.lua       # P3
      visual/
        colorscheme.lua         # P3
      utils/
        filetype.lua            # P2 (FileType-Dispatcher)
    handlers/
      git/
        line_diff.lua
        blame.lua
        conflict_marks.lua
      lsp/
        symbols.lua
        formatter.lua
      ui/
        cword_occurrences.lua
        breadcrumbs.lua
        indent_scope.lua
      markdown/
        keymaps.lua
        usercmds.lua
```

## Context-Factory Pattern

```lua
-- autocmds/context/buffer.lua
local M = {}
local cache = setmetatable({}, { __mode = "k" }) -- weak keys

---@class AutoCmds.Context.BufferCtx
---@field bufnr integer
---@field name string
---@field filetype string
---@field buftype string
---@field modifiable boolean
---@field modified boolean
---@field lines string[]|nil  -- lazy
---@field tick integer

function M.get(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)

  if cache[bufnr] and cache[bufnr].tick == tick then
    return cache[bufnr]
  end

  local ctx = {
    bufnr = bufnr,
    name = vim.api.nvim_buf_get_name(bufnr),
    filetype = vim.bo[bufnr].filetype,
    buftype = vim.bo[bufnr].buftype,
    modifiable = vim.bo[bufnr].modifiable,
    modified = vim.bo[bufnr].modified,
    tick = tick,
  }

  -- Lazy line loading
  setmetatable(ctx, {
    __index = function(t, k)
      if k == "lines" then
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        rawset(t, "lines", lines)
        return lines
      end
    end
  })

  cache[bufnr] = ctx
  return ctx
end

function M.invalidate(bufnr)
  cache[bufnr] = nil
end

return M
```

## Event-Dispatcher Beispiel

```lua
-- autocmds/events/hot_path/cursor_moved.lua
local buffer_ctx = require("autocmds.benchmarks.context.buffer")
local handlers = {
  git_line_diff = require("autocmds.handlers.git.line_diff"),
  cword_occurrences = require("autocmds.handlers.ui.cword_occurrences"),
  indent_scope = require("autocmds.handlers.ui.indent_scope"),
  breadcrumbs = require("autocmds.handlers.ui.breadcrumbs"),
}

return function()
  local ctx = buffer_ctx.get()

  -- Early exits
  if ctx.buftype ~= "" then return end
  if not ctx.modifiable then return end

  -- Parallel dispatch (order irrelevant)
  for name, handler in pairs(handlers) do
    if handler.should_run(ctx) then
      handler.run(ctx)
    end
  end
end
```

---

