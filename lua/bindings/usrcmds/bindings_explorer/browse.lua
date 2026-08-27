---@module 'bindings.usrcmds.bindings_explorer.browse'
--- `:Bindings browse` — picker over `records.lua`'s parsed table rows
--- instead of `search.lua`'s raw text lines (docs/ROADMAP/personal/
--- bindings-explorer.nvim.md §3, Phase 2). Reuses `lib.nvim.ui.kit.select`
--- like `ui.lua`'s Phase-1 fallback does — a fixed row count per query,
--- no incremental live-filter engine needed the way `live.lua`'s
--- text-grep does.

local records = require("bindings.usrcmds.bindings_explorer.records")

local M = {}

---@return table notify-Handle aus lib.nvim
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
---@return nil
local function pick(recs)
  if #recs == 0 then
    notify().warn("Keine Tabellenzeilen gefunden")
    return
  end

  require("lib.nvim.ui.kit.select").open({
    items = recs,
    title = ("%d Zeilen"):format(#recs),
    format_item = format_record,
    on_select = function(rec)
      vim.cmd("edit " .. vim.fn.fnameescape(rec.file))
      vim.api.nvim_win_set_cursor(0, { rec.line, 0 })
      vim.cmd("normal! zz")
    end,
  })
end

--- Every table row, optionally narrowed to a category and/or scope.
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@param scope ("personal"|"extern")|nil
---@return nil
function M.open(category, scope)
  pick(records.list(category, scope))
end

return M
