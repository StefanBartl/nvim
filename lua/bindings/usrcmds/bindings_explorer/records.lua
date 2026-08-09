---@module 'bindings.usrcmds.bindings_explorer.records'
--- Phase 2 (docs/ROADMAP/personal/bindings-explorer.nvim.md §3): tolerant
--- table-row scraper. Every `|…|…|` line found under the nearest preceding
--- `##`/`###` heading becomes a flat record — column names and count stay
--- free-form (`docs/NOTES/BINDINGS-FORMAT.md` only mandates a heading right
--- above every table, not a fixed schema across the whole corpus, see that
--- file §1's "jede Tabelle ... bekommt eine eigene Überschrift" rule, added
--- specifically so this scraper wouldn't need one). Files without a table
--- under a heading (prose-only sections, `Telescope.md`-style stretches)
--- simply contribute no records — no error, just fewer hits, same
--- graceful-degradation stance as `search.lua`.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")
local config = require("bindings.usrcmds.bindings_explorer.config")

local M = {}

--- `config.roots()` returns Personal then Extern, always in that order —
--- see its doc comment. Index-based instead of matching "PersonelPlugins"/
--- "ExternPlugins" in the path so a future root rename can't silently break
--- the scope label.
local ROOT_SCOPES = { "Personal", "Extern" }

---@class Bindings.Record
---@field scope "Personal"|"Extern"
---@field category "Keymaps"|"Usercmds"|"Autocmds"
---@field plugin string filename without extension, e.g. "images.nvim" or "Telescope"
---@field heading string|nil nearest `##`/`###` heading above the table, nil if the table opens the file with no heading yet
---@field columns string[] header-row cells, free-form
---@field cells string[] this row's cells, same length as `columns` when the table is well-formed
---@field file string absolute path
---@field line integer 1-based line number of this row

---@param line string
---@return boolean
local function is_table_row(line)
  return line:match("^%s*|.*|%s*$") ~= nil
end

--- A markdown header-separator row, e.g. `| --- | --- |` or `|:---|---:|`.
---@param line string
---@return boolean
local function is_separator_row(line)
  return line:match("^%s*|[%s%-:|]+|%s*$") ~= nil
end

---@param line string
---@return string[]
local function split_cells(line)
  local trimmed = vim.trim(line):gsub("^|", ""):gsub("|$", "")
  local cells = {}
  for cell in (trimmed .. "|"):gmatch("(.-)|") do
    cells[#cells + 1] = vim.trim(cell)
  end
  return cells
end

---@param path string
---@param scope "Personal"|"Extern"
---@param category "Keymaps"|"Usercmds"|"Autocmds"
---@return Bindings.Record[]
local function parse_file(path, scope, category)
  local content = read(path)
  if not content then return {} end

  local plugin = vim.fn.fnamemodify(path, ":t:r")
  local records = {}
  local heading, columns, awaiting_separator = nil, nil, false

  local lines = vim.split(content:gsub("\r", ""), "\n", { plain = true })
  for lnum, line in ipairs(lines) do
    local h = line:match("^##+%s+(.+)$")
    if h then
      heading, columns, awaiting_separator = vim.trim(h), nil, false
    elseif is_table_row(line) then
      if not columns then
        columns, awaiting_separator = split_cells(line), true
      elseif awaiting_separator and is_separator_row(line) then
        awaiting_separator = false
      else
        awaiting_separator = false
        records[#records + 1] = {
          scope = scope,
          category = category,
          plugin = plugin,
          heading = heading,
          columns = columns,
          cells = split_cells(line),
          file = path,
          line = lnum,
        }
      end
    else
      -- Blank line or prose ends the current table; the next `|…|` line
      -- starts a fresh one and re-reads its own header row.
      columns, awaiting_separator = nil, false
    end
  end

  return records
end

--- Every table row across the BINDINGS corpus, optionally narrowed to one
--- category and/or one scope.
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil nil = all three
---@param scope ("personal"|"extern")|nil nil = both
---@return Bindings.Record[]
function M.list(category, scope)
  local categories = category and { category } or { "Keymaps", "Usercmds", "Autocmds" }
  local out = {}

  for idx, root in ipairs(config.roots()) do
    local root_scope = ROOT_SCOPES[idx]
    if not scope or scope:lower() == root_scope:lower() then
      for _, cat in ipairs(categories) do
        local dir = vim.fs.joinpath(root, cat)
        if vim.fn.isdirectory(dir) == 1 then
          for _, f in ipairs(collect_recursive.files(dir)) do
            if f:match("%.md$") then
              vim.list_extend(out, parse_file(f, root_scope, cat))
            end
          end
        end
      end
    end
  end

  return out
end

return M
