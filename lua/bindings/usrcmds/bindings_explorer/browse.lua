---@module 'bindings.usrcmds.bindings_explorer.browse'
--- `:Bindings browse` — picker over `records.lua`'s parsed table rows instead
--- of `search.lua`'s raw text lines (see docs/FEATURES.md). Reuses
--- `lib.nvim.ui.kit.select` like `ui.lua`'s fallback does — a fixed row count
--- per query, no incremental live-filter engine needed.
---
--- Rendering (`render`): the picker float does not wrap, so a row has to fit
--- one line. Instead of `[Scope/Plugin] Heading — Col: val  Col: val …`
--- repeated verbatim on every row (unreadable past the second column), the
--- rows are laid out as an aligned table:
---   * the `[Scope/Plugin]` prefix is dropped when every row shares one plugin
---     (the title already names it), shown as a short stem otherwise;
---   * the heading collapses to a short tag (`key`/`cmd`/`au`, or the heading
---     itself when it carries more than the category — sandbox.nvim's
---     `:Sandbox <thing> <sub>` sections);
---   * cell values are stripped of Markdown, `*None* (`nil`)`-style blanks
---     become `—`, and each column is padded to the widest value in its group
---     (`plugin` + heading), so the columns line up;
---   * the whole line is capped to the editor width with an ellipsis.
--- `<CR>` still jumps to the row in its source file.
---
--- User-facing strings here are German, deliberately (see status.lua).

local records = require("bindings.usrcmds.bindings_explorer.records")

local M = {}

---@return table lib.nvim notify handle
local function notify()
  return require("lib.nvim.notify").create("[bindings]")
end

--- Short per-category tag; the full heading wins when it says more than the
--- category already does (sandbox.nvim's per-subcommand sections).
local CATEGORY_TAG = { Keymaps = "key", Usercmds = "cmd", Autocmds = "au" }

--- Headings that only restate their category — no point showing them over the
--- tag. Matched after stripping a leading `N.` and a trailing `(`slug`)`.
local GENERIC_HEADING = {
  ["keymaps"] = true,
  ["key maps"] = true,
  ["preset keymaps"] = true,
  ["picker keymaps"] = true,
  ["in-picker keys"] = true,
  ["user commands"] = true,
  ["user command"] = true,
  ["usercmds"] = true,
  ["usrcmds"] = true,
  ["collection-generated commands"] = true,
  ["autocommands"] = true,
  ["autocommand"] = true,
  ["autocmds"] = true,
}

--- HTML entities and stray TeX a few corpus cells carry.
local LITERAL = {
  ["&middot;"] = "·",
  ["&nbsp;"] = " ",
  ["&amp;"] = "&",
  ["&lt;"] = "<",
  ["&gt;"] = ">",
  ["&quot;"] = '"',
  ["&#39;"] = "'",
  ["&rarr;"] = "→",
  ["&#8594;"] = "→",
  ["&harr;"] = "↔",
  ["$\\rightarrow$"] = "→",
  ["$\\to$"] = "→",
  ["\\rightarrow"] = "→",
}

--- Hard per-column cap (a description column gets more room), the tag-column
--- cap (per-category tags are 2-3 chars; sandbox.nvim's headings ride here
--- too), and the overall line cap so the non-wrapping float never clips a row
--- mid-word.
local CELL_CAP = 40
local DESC_CAP = 56
local TAG_CAP = 14

---@param s string
---@param n integer
---@return string
local function trunc(s, n)
  if n <= 0 then
    return ""
  end
  if vim.fn.strdisplaywidth(s) <= n then
    return s
  end
  return vim.fn.strcharpart(s, 0, math.max(1, n - 1)) .. "…"
end

---@param s string
---@param w integer
---@return string
local function pad(s, w)
  local gap = w - vim.fn.strdisplaywidth(s)
  return gap > 0 and (s .. string.rep(" ", gap)) or s
end

--- One cell as plain display text: no Markdown, entities resolved, blanks
--- folded to a dash.
---@param s string
---@return string
local function plain(s)
  for from, to in pairs(LITERAL) do
    s = s:gsub(vim.pesc(from), to)
  end
  s = (s:gsub("`", ""):gsub("%*+", ""):gsub("<br%s*/?>", " "))
  s = vim.trim((s:gsub("%s+", " ")))
  local low = s:lower()
  if
    low == ""
    or low == "none"
    or low == "nil"
    or low == "none (nil)"
    or low == "n/a"
    or low == "-"
    or low == "--"
  then
    return "—"
  end
  return s
end

--- A short tag for one row: the heading when it distils to something brief and
--- more specific than the category (`### Owned`, or sandbox.nvim's
--- `## `:Sandbox image <subcommand>`` → `image`), otherwise `key`/`cmd`/`au`.
---@param rec Bindings.Record
---@return string
local function group_tag(rec)
  local h = rec.heading
  if h then
    local s = plain(vim.trim((h:gsub("^%s*%d+%.%s*", ""):gsub("%s*%b()%s*$", ""))))
    s = s:gsub("%s*<[^>]*>%s*$", ""):gsub("%s*%[[^%]]*%]%s*$", "") -- trailing <ph>/[ph]
    s = vim.trim((s:gsub("^:%a[%w_]*%s+", ""))) -- leading command word (`:Sandbox `)
    if
      s ~= ""
      and s ~= "—"
      and vim.fn.strdisplaywidth(s) <= TAG_CAP
      and not GENERIC_HEADING[s:lower()]
    then
      return s
    end
  end
  return CATEGORY_TAG[rec.category] or "?"
end

---@param col string|nil
---@return boolean
local function is_desc_col(col)
  local c = (col or ""):lower()
  return c:find("desc", 1, true) ~= nil
    or c:find("beschreib", 1, true) ~= nil
    or c:find("erklär", 1, true) ~= nil
    or c:find("erläut", 1, true) ~= nil
    or c:find("zweck", 1, true) ~= nil
    or c:find("wirkung", 1, true) ~= nil
    or c:find("bedeutung", 1, true) ~= nil
    or c:find("note", 1, true) ~= nil
    or c:find("hinweis", 1, true) ~= nil
    or c:find("kommentar", 1, true) ~= nil
end

--- Build one aligned display line per record, in `recs` order.
---@param recs Bindings.Record[]
---@return string[]
local function render(recs)
  local seen, plugin_count = {}, 0
  for _, r in ipairs(recs) do
    if not seen[r.plugin] then
      seen[r.plugin] = true
      plugin_count = plugin_count + 1
    end
  end
  local show_plugin = plugin_count > 1

  local plugin_w = 0
  if show_plugin then
    for p in pairs(seen) do
      plugin_w = math.max(plugin_w, vim.fn.strdisplaywidth(p))
    end
    plugin_w = math.min(plugin_w, 22)
  end

  -- Pass 1: plain cells, per-group column widths, tag width. A "group" is one
  -- source table (plugin + heading), which is where a column layout is shared.
  local prepared, group_w, tag_w = {}, {}, 0
  for i, r in ipairs(recs) do
    local group = r.plugin .. "\0" .. (r.heading or r.category)
    local tag = group_tag(r)
    tag_w = math.max(tag_w, vim.fn.strdisplaywidth(tag))
    group_w[group] = group_w[group] or {}
    local cells, is_desc = {}, {}
    for ci = 1, #r.columns do
      is_desc[ci] = is_desc_col(r.columns[ci])
      local v = trunc(plain(r.cells[ci] or ""), is_desc[ci] and DESC_CAP or CELL_CAP)
      cells[ci] = v
      -- A prose column is never a column to line others up against — leave it
      -- out of the width tally so one long sentence can't push every row over.
      if not is_desc[ci] then
        group_w[group][ci] = math.max(group_w[group][ci] or 0, vim.fn.strdisplaywidth(v))
      end
    end
    prepared[i] = { tag = tag, cells = cells, is_desc = is_desc, group = group }
  end
  tag_w = math.min(tag_w, TAG_CAP)

  -- Pass 2: assemble. Trailing empty columns are dropped; the last column and
  -- any prose column are not padded; the whole line is capped to editor width.
  local line_cap = math.min(((vim.o.columns or 0) > 0 and vim.o.columns or 120) - 8, 170)
  local out = {}
  for i, r in ipairs(recs) do
    local p = prepared[i]
    local segs = {}
    if show_plugin then
      segs[#segs + 1] = pad(trunc(r.plugin, plugin_w), plugin_w)
    end
    segs[#segs + 1] = pad(p.tag, tag_w)

    local last = 0
    for ci = 1, #p.cells do
      if p.cells[ci] ~= "" then
        last = ci
      end
    end
    for ci = 1, last do
      if ci == last or p.is_desc[ci] then
        segs[#segs + 1] = p.cells[ci]
      else
        segs[#segs + 1] = pad(p.cells[ci], group_w[p.group][ci] or 0)
      end
    end

    out[i] = trunc(table.concat(segs, "  "), line_cap)
  end
  return out
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

  local display = render(recs)
  local by_rec = {}
  for i, rec in ipairs(recs) do
    by_rec[rec] = display[i]
  end

  require("lib.nvim.ui.kit.select").open({
    items = recs,
    title = label and ("%d Zeilen — %s"):format(#recs, label) or ("%d Zeilen"):format(#recs),
    format_item = function(rec)
      return by_rec[rec] or ""
    end,
    on_select = function(rec)
      vim.cmd("edit " .. vim.fn.fnameescape(rec.file))
      vim.api.nvim_win_set_cursor(0, { rec.line, 0 })
      vim.cmd("normal! zz")
    end,
  })
end

--- Test seam: the row renderer, exercised directly against synthetic records
--- (same pattern as `records.lua`'s exposed helpers).
M._render = render

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
