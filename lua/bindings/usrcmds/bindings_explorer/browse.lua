---@module 'bindings.usrcmds.bindings_explorer.browse'
--- `:Bindings browse` — picker over `records.lua`'s parsed table rows instead
--- of `search.lua`'s raw text lines (see docs/FEATURES.md). Reuses
--- `lib.nvim.ui.kit.select` like `ui.lua`'s fallback does — a fixed row count
--- per query, no incremental live-filter engine needed.
---
--- User-facing strings here are German, deliberately (see status.lua).

local records = require("bindings.usrcmds.bindings_explorer.records")

local M = {}

---@return table lib.nvim notify handle
local function notify()
  return require("lib.nvim.notify").create("[bindings]")
end

--- `{ ["Key"] = "<leader>iv", ["Mode"] = "n", ... }`-style rendering, one
--- row: `Key: <leader>iv  Mode: n  ...` — column names stay whatever the
--- source file used (see records.lua doc comment), so this can't assume
--- Key/Mode/Effect specifically.
---@param rec Bindings.Record
---@return string
local function format_record(rec)
  local parts = {}
  for i, col in ipairs(rec.columns) do
    local cell = rec.cells[i]
    if cell and cell ~= "" then
      parts[#parts + 1] = ("%s: %s"):format(col, cell)
    end
  end
  return ("[%s/%s] %s — %s"):format(
    rec.scope,
    rec.plugin,
    rec.heading or rec.category,
    table.concat(parts, "  ")
  )
end

---@param recs Bindings.Record[]
---@param label string|nil plugin scope, for the title and the empty message
---@return nil
local function pick(recs, label)
  if #recs == 0 then
    notify().warn(
      label and ("Keine Tabellenzeilen für %s gefunden"):format(label)
        or "Keine Tabellenzeilen gefunden"
    )
    return
  end

  require("lib.nvim.ui.kit.select").open({
    items = recs,
    title = label and ("%d Zeilen — %s"):format(#recs, label) or ("%d Zeilen"):format(#recs),
    format_item = format_record,
    on_select = function(rec)
      vim.cmd("edit " .. vim.fn.fnameescape(rec.file))
      vim.api.nvim_win_set_cursor(0, { rec.line, 0 })
      vim.cmd("normal! zz")
    end,
  })
end

--- Every table row, optionally narrowed to a category, a scope and/or a
--- plugin.
---
--- The plugin narrowing is a filter on `rec.plugin` rather than a second
--- corpus walk: `records.list` reads the same files either way, and the stems
--- come pre-resolved from `plugin_scope.resolve` (so `dap` here means both
--- `dap.nvim` and `Dap`, exactly as it does for `:Bindings search`).
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@param scope ("personal"|"extern")|nil
---@param match Bindings.PluginMatch|nil nil = every plugin
---@return nil
function M.open(category, scope, match)
  local recs = records.list(category, scope)
  if not match then
    pick(recs)
    return
  end

  local wanted = {}
  for _, stem in ipairs(match.stems) do
    wanted[stem] = true
  end
  local scoped = {}
  for _, rec in ipairs(recs) do
    if wanted[rec.plugin] then
      scoped[#scoped + 1] = rec
    end
  end
  pick(scoped, match.label)
end

return M
