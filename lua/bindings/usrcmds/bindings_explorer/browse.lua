---@module 'bindings.usrcmds.bindings_explorer.browse'
--- `:Bindings browse` — a grouped, read-only view of `records.lua`'s parsed
--- table rows (see docs/FEATURES.md). Not a fuzzy picker: the corpus rows are
--- short and structured, so this lays them out like the source cheatsheet —
--- one section per source table, an aligned column block under each — and
--- `<CR>` jumps to the row in its file.
---
--- Why not `kit.select`: that chooser is j/k navigation with no section
--- headers, no column header, and no unselectable lines — a browse of "every
--- binding pickers.nvim registers" wants all three.
---
--- Layout (`layout`):
---   * one **section** per source table (`plugin` + heading), titled with the
---     heading, set in `Title`;
---   * a **column-name row** under the title (bold) plus a rule line, and the
---     same names mirrored into the window's `winbar` so they stay visible
---     once the section scrolls past the top;
---   * cells stripped of Markdown/entities, `*None* (`nil`)`-style blanks
---     folded to `—` (dimmed), each column padded to the widest value (or
---     name) so the columns line up; a prose column is left unpadded and
---     dimmed;
---   * the first column (the key / command name / event) is accented.
---
--- User-facing strings here are German, deliberately (see status.lua).

local records = require("bindings.usrcmds.bindings_explorer.records")

local M = {}

---@return table lib.nvim notify handle
local function notify()
  return require("lib.nvim.notify").create("[bindings]")
end

--- Section title when a heading only restates its category.
local CATEGORY_LABEL = {
  Keymaps = "Keymaps",
  Usercmds = "User Commands",
  Autocmds = "Autocommands",
}

--- HTML entities and stray TeX a few corpus cells carry. Ordered: the
--- `$…$`-wrapped forms are resolved before the bare command they contain.
local LITERAL = {
  { "$\\rightarrow$", "→" },
  { "$\\to$", "→" },
  { "\\rightarrow", "→" },
  { "$→$", "→" },
  { "&middot;", "·" },
  { "&nbsp;", " " },
  { "&rarr;", "→" },
  { "&#8594;", "→" },
  { "&harr;", "↔" },
  { "&lt;", "<" },
  { "&gt;", ">" },
  { "&quot;", '"' },
  { "&#39;", "'" },
  { "&amp;", "&" },
}

--- Hard per-column cap (a prose column gets more room); the overall line cap
--- keeps the non-wrapping float from clipping a row mid-word.
local CELL_CAP = 40
local DESC_CAP = 60

--- Namespace for the layout's highlight extmarks.
local NS = vim.api.nvim_create_namespace("bindings_explorer_browse")

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
  for _, sub in ipairs(LITERAL) do
    s = s:gsub(vim.pesc(sub[1]), sub[2])
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

--- A column header for display: no Markdown, and without the trailing
--- `(config-field-name)` the cheatsheets append (`Default Key (`default`)` →
--- `Default Key`). Kept whole if stripping would empty it.
---@param col string
---@return string
local function column_name(col)
  local s = plain(col)
  local bare = vim.trim((s:gsub("%s*%b()%s*$", "")))
  return bare ~= "" and bare or s
end

--- A prose / free-text column — never a column to line others up against.
---@param col string|nil
---@return boolean
local function is_desc_col(col)
  local c = (col or ""):lower()
  for _, needle in ipairs({
    "desc",
    "beschreib",
    "erklär",
    "erläut",
    "zweck",
    "wirkung",
    "bedeutung",
    "note",
    "hinweis",
    "kommentar",
  }) do
    if c:find(needle, 1, true) then
      return true
    end
  end
  return false
end

--- Section title for one record: its heading, stripped of a leading `N.` and a
--- trailing `(`slug`)`, or the plain category name when the heading adds
--- nothing.
---@param rec Bindings.Record
---@return string
local function section_label(rec)
  local h = rec.heading
  if h and h ~= "" then
    local s = plain(vim.trim((h:gsub("^%s*%d+%.%s*", ""):gsub("%s*%b()%s*$", ""))))
    local generic = CATEGORY_LABEL[rec.category] or ""
    if s ~= "" and s ~= "—" and s:lower() ~= generic:lower() then
      return trunc(s, 56)
    end
  end
  return CATEGORY_LABEL[rec.category] or rec.category
end

---@class Bindings.Browse.Section
---@field key string  internal: `plugin \0 heading`, the run boundary
---@field plugin string
---@field label string
---@field columns string[]
---@field recs Bindings.Record[]

--- Split records into contiguous runs of one source table (`plugin` +
--- heading). `records.list` returns them file- and heading-ordered, so a run
--- is exactly one `|…|` table in one cheatsheet.
---@param recs Bindings.Record[]
---@return Bindings.Browse.Section[]
local function sections_of(recs)
  local out = {}
  for _, r in ipairs(recs) do
    local key = r.plugin .. "\0" .. (r.heading or r.category)
    local cur = out[#out]
    if not cur or cur.key ~= key then
      cur = {
        key = key,
        plugin = r.plugin,
        label = section_label(r),
        columns = r.columns,
        recs = {},
      }
      out[#out + 1] = cur
    end
    cur.recs[#cur.recs + 1] = r
  end
  return out
end

---@class Bindings.Browse.Layout
---@field lines string[]
---@field rec_at table<integer, Bindings.Record>  1-based line -> record (data rows only)
---@field winbar_at table<integer, string>        1-based line -> that section's column header
---@field hl { line: integer, col_start: integer, col_end: integer, group: string }[]  0-based rows
---@field first_row integer|nil                   1-based line of the first data row

--- Render the sections to buffer lines plus a highlight plan.
---@param sections Bindings.Browse.Section[]
---@param show_plugin boolean
---@return Bindings.Browse.Layout
local function layout(sections, show_plugin)
  local line_cap = math.min(((vim.o.columns or 0) > 0 and vim.o.columns or 120) - 8, 200)
  local lines, rec_at, winbar_at, hl = {}, {}, {}, {}
  local first_row

  --- Append one line; return its 1-based and 0-based index.
  ---@param text string
  ---@return integer, integer
  local function push(text)
    lines[#lines + 1] = text
    return #lines, #lines - 1
  end
  local function span(row0, cs, ce, group)
    if ce > cs then
      hl[#hl + 1] = { line = row0, col_start = cs, col_end = ce, group = group }
    end
  end

  for si, sec in ipairs(sections) do
    local ncol = #sec.columns
    local names, is_desc, width = {}, {}, {}
    for ci = 1, ncol do
      names[ci] = column_name(sec.columns[ci])
      is_desc[ci] = is_desc_col(sec.columns[ci])
      if not is_desc[ci] then
        width[ci] = vim.fn.strdisplaywidth(names[ci])
      end
    end

    local rows = {}
    for _, r in ipairs(sec.recs) do
      local cells = {}
      for ci = 1, ncol do
        cells[ci] = trunc(plain(r.cells[ci] or ""), is_desc[ci] and DESC_CAP or CELL_CAP)
        if not is_desc[ci] then
          width[ci] = math.max(width[ci] or 0, vim.fn.strdisplaywidth(cells[ci]))
        end
      end
      rows[#rows + 1] = { rec = r, cells = cells }
    end

    -- Widest non-empty column across the section; everything past it is empty.
    local last = 0
    for _, row in ipairs(rows) do
      for ci = ncol, last + 1, -1 do
        if row.cells[ci] ~= "" then
          last = ci
          break
        end
      end
    end
    if last == 0 then
      last = ncol
    end

    --- Assemble one row; `get(ci)` returns column ci's value. Returns the line
    --- text and, per column, the byte range its *value* occupies.
    ---@param get fun(ci: integer): string
    ---@return string, table<integer, {from: integer, to: integer}>
    local function assemble(get)
      local segs, ranges, col = {}, {}, 0
      for ci = 1, last do
        if ci > 1 then
          col = col + 2 -- "  " separator
        end
        local v = get(ci)
        ranges[ci] = { from = col, to = col + #v }
        local seg = (ci == last or is_desc[ci]) and v or pad(v, width[ci] or 0)
        segs[#segs + 1] = seg
        col = col + #seg
      end
      return trunc(table.concat(segs, "  "), line_cap), ranges
    end

    if si > 1 then
      push("")
    end

    local title = "▌ " .. (show_plugin and (sec.plugin .. "  —  ") or "") .. sec.label
    local _, title0 = push(title)
    span(title0, 0, #title, "Title")

    local header = (assemble(function(ci)
      return names[ci]
    end))
    local h1, h0 = push(header)
    span(h0, 0, #header, "Special")
    local rule = string.rep("─", math.min(vim.fn.strdisplaywidth(header), line_cap))
    local r1, r0 = push(rule)
    span(r0, 0, #rule, "NonText")
    winbar_at[title0 + 1] = header
    winbar_at[h1] = header
    winbar_at[r1] = header

    for _, row in ipairs(rows) do
      local text, ranges = assemble(function(ci)
        return row.cells[ci]
      end)
      local line1, line0 = push(text)
      rec_at[line1] = row.rec
      winbar_at[line1] = header
      first_row = first_row or line1
      for ci, rg in pairs(ranges) do
        local ce = math.min(rg.to, #text)
        if row.cells[ci] == "—" then
          span(line0, rg.from, ce, "Comment")
        elseif is_desc[ci] then
          span(line0, rg.from, ce, "Comment")
        elseif ci == 1 then
          span(line0, rg.from, ce, "Identifier")
        end
      end
    end
  end

  return { lines = lines, rec_at = rec_at, winbar_at = winbar_at, hl = hl, first_row = first_row }
end

---@param recs Bindings.Record[]
---@return integer
local function distinct_plugins(recs)
  local seen, n = {}, 0
  for _, r in ipairs(recs) do
    if not seen[r.plugin] then
      seen[r.plugin] = true
      n = n + 1
    end
  end
  return n
end

--- Test seam: the buffer lines for a set of records (same pattern as
--- `records.lua`'s exposed helpers).
---@param recs Bindings.Record[]
---@return string[]
function M._preview(recs)
  return layout(sections_of(recs), distinct_plugins(recs) > 1).lines
end

---@param recs Bindings.Record[]
---@param label string|nil plugin scope, for the title and the empty message
---@return nil
local function open_view(recs, label)
  if #recs == 0 then
    notify().warn(
      label and ("Keine Tabellenzeilen für %s gefunden"):format(label)
        or "Keine Tabellenzeilen gefunden"
    )
    return
  end

  local view = layout(sections_of(recs), distinct_plugins(recs) > 1)
  local title = label and ("Bindings — %s (%d Zeilen)"):format(label, #recs)
    or ("Bindings — %d Zeilen"):format(#recs)

  local surf = require("lib.nvim.ui.kit.surface").open({
    lines = view.lines,
    title = title,
    relative = "editor",
    enter = true,
    modifiable = false,
    nice_quit = true,
    filetype = "bindings-browse",
    wo = { cursorline = true, wrap = false },
  })
  if not surf then
    return
  end

  for _, h in ipairs(view.hl) do
    pcall(vim.api.nvim_buf_set_extmark, surf.bufnr, NS, h.line, h.col_start, {
      end_col = h.col_end,
      hl_group = h.group,
    })
  end

  --- Keep the current section's column names in the winbar. On a blank
  --- separator line, carry the section above it.
  local function sync_winbar()
    if not surf:is_valid() then
      return
    end
    local ln = vim.api.nvim_win_get_cursor(surf.winid)[1]
    local header = view.winbar_at[ln]
    while not header and ln > 1 do
      ln = ln - 1
      header = view.winbar_at[ln]
    end
    pcall(vim.api.nvim_set_option_value, "winbar", " " .. (header or ""), { win = surf.winid })
  end

  local group = vim.api.nvim_create_augroup("bindings_browse_" .. surf.winid, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
    group = group,
    buffer = surf.bufnr,
    callback = sync_winbar,
    desc = "bindings browse: section-aware winbar",
  })

  vim.keymap.set("n", "<CR>", function()
    local ln = vim.api.nvim_win_get_cursor(surf.winid)[1]
    local rec = view.rec_at[ln]
    if not rec then
      return
    end
    surf:close()
    vim.cmd("edit " .. vim.fn.fnameescape(rec.file))
    vim.api.nvim_win_set_cursor(0, { rec.line, 0 })
    vim.cmd("normal! zz")
  end, { buffer = surf.bufnr, nowait = true, desc = "bindings browse: jump to source" })

  if view.first_row then
    pcall(vim.api.nvim_win_set_cursor, surf.winid, { view.first_row, 0 })
  end
  sync_winbar()
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
    open_view(recs)
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
  open_view(scoped, match.label)
end

return M
