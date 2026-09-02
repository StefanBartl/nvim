---@module 'bindings.usrcmds.bindings_explorer.status'
--- `:Bindings status` — one screen answering "what does this thing know, and
--- what is this session actually running", after the model of
--- `:Reposcope status`.
---
--- Deliberately does NOT run the drift check. That takes ~650ms across four
--- axes and produces a report, which is what `:Bindings check` and
--- `:Bindings report` are for; a dashboard that made you wait would be opened
--- once. Everything here is either a cheap live API call or one pass over the
--- corpus, and the drift line only reports what the last written report says
--- — the file, not a fresh measurement.
---
--- The route list at the bottom exists because it is the honest answer to the
--- most common reason for typing `:Bindings` at all: the verb tree has grown
--- past what a `desc` string shows in completion, and this is the `?`-style
--- cheatsheet the roadmap point asked for.
---
--- Output language is German, like every other user-visible string of
--- `:Bindings`.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local config = require("bindings.usrcmds.bindings_explorer.config")
local records = require("bindings.usrcmds.bindings_explorer.records")

local M = {}

local CATEGORIES = { "Keymaps", "Usercmds", "Autocmds" }

--- Every mode `nvim_get_keymap` answers for. `!`, `ic` and friends are
--- rendered by Neovim into these, so asking for them too would double-count.
local MODES = { "n", "i", "v", "x", "s", "o", "t", "c" }

---@param root string
---@param category string
---@return integer
local function md_count(root, category)
  local dir = vim.fs.joinpath(root, category)
  if vim.fn.isdirectory(dir) ~= 1 then
    return 0
  end
  local n = 0
  for _, f in ipairs(collect_recursive.files(dir)) do
    if f:match("%.md$") then
      n = n + 1
    end
  end
  return n
end

--- Rows and files per scope and category, plus how many of the rows come from
--- a corpus-level file (`records.lua`'s `META_FILES`) rather than a plugin's
--- own sheet — the number that explains why the row total is larger than the
--- number of documented bindings.
---@return table
local function corpus()
  local rows, meta_rows, files_with_rows = {}, 0, {}
  for _, rec in ipairs(records.list()) do
    local key = rec.scope .. "/" .. rec.category
    rows[key] = (rows[key] or 0) + 1
    files_with_rows[rec.file] = true
    if rec.meta then
      meta_rows = meta_rows + 1
    end
  end

  local scopes = {}
  for idx, root in ipairs(config.roots()) do
    local scope = idx == 1 and "Personal" or "Extern"
    local cats = {}
    for _, cat in ipairs(CATEGORIES) do
      cats[#cats + 1] = {
        name = cat,
        files = md_count(root, cat),
        rows = rows[scope .. "/" .. cat] or 0,
      }
    end
    scopes[#scopes + 1] = { name = scope, root = root, categories = cats }
  end

  local total_rows = 0
  for _, n in pairs(rows) do
    total_rows = total_rows + n
  end

  local n_files = 0
  for _ in pairs(files_with_rows) do
    n_files = n_files + 1
  end

  return { scopes = scopes, rows = total_rows, meta_rows = meta_rows, files_with_rows = n_files }
end

--- Live counts. Buffer-local keymaps are counted separately because the drift
--- check treats them separately: they are the class that reads as "documented
--- but not live" whenever the owning UI is closed.
---@return table
local function live()
  local global_by_mode, global_total, buf_total = {}, 0, 0
  for _, mode in ipairs(MODES) do
    local n = #vim.api.nvim_get_keymap(mode)
    if n > 0 then
      global_by_mode[#global_by_mode + 1] = ("%s %d"):format(mode, n)
    end
    global_total = global_total + n
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        buf_total = buf_total + #vim.api.nvim_buf_get_keymap(buf, mode)
      end
    end
  end

  local groups, autocmds = {}, {}
  local ok, list = pcall(vim.api.nvim_get_autocmds, {})
  if ok then
    autocmds = list
    for _, au in ipairs(list) do
      if au.group_name then
        groups[au.group_name] = true
      end
    end
  end

  return {
    keymaps_global = global_total,
    keymaps_by_mode = table.concat(global_by_mode, ", "),
    keymaps_buffer = buf_total,
    usercmds = vim.tbl_count(vim.api.nvim_get_commands({})),
    autocmds = #autocmds,
    autocmd_groups = vim.tbl_count(groups),
  }
end

---@return integer loaded, integer total
local function plugins()
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if not ok or type(lazy_config.plugins) ~= "table" then
    return 0, 0
  end
  local loaded, total = 0, 0
  for _, p in pairs(lazy_config.plugins) do
    total = total + 1
    if p._ and p._.loaded then
      loaded = loaded + 1
    end
  end
  return loaded, total
end

--- The most recent `BINDINGS-DRIFT-*.md` in `config.report_dir()`, or nil.
--- Sorted by name, not by mtime: the name carries the date the report is
--- ABOUT, and a file touched later still describes its own day.
---@return string|nil name, string|nil dir
local function last_report()
  local dir = config.report_dir()
  if vim.fn.isdirectory(dir) ~= 1 then
    return nil, dir
  end
  local names = {}
  for name, type_ in vim.fs.dir(dir) do
    if type_ == "file" and name:match("^BINDINGS%-DRIFT%-.*%.md$") then
      names[#names + 1] = name
    end
  end
  if #names == 0 then
    return nil, dir
  end
  table.sort(names)
  return names[#names], dir
end

local ROUTES = {
  { ":Bindings search [keymaps|usercmds|autocmds] [query]", "Live-Grep über den Korpus" },
  { ":Bindings browse [keymaps|usercmds|autocmds] [scope]", "Picker über die Tabellenzeilen" },
  { ":Bindings check [plugin] [repo] [root=<dir>]", "Driftbericht im Viewer" },
  { ":Bindings report [plugin] [repo] [root=<dir>] [out=<pfad>]", "derselbe Bericht als Datei" },
  { ":Bindings path [personal|extern]", "Wurzel(n) in die Zwischenablage" },
  { ":Bindings status", "diese Seite" },
}

--- The dashboard, as viewer lines.
---@return string[]
function M.lines()
  local c = corpus()
  local l = live()
  local loaded, total = plugins()
  local report, report_dir = last_report()

  local out = { "Korpus", "" }
  for _, scope in ipairs(c.scopes) do
    out[#out + 1] = ("  %-10s %s"):format(scope.name, scope.root)
    for _, cat in ipairs(scope.categories) do
      out[#out + 1] = ("    %-10s %3d Dateien   %4d Tabellenzeilen"):format(
        cat.name,
        cat.files,
        cat.rows
      )
    end
  end
  out[#out + 1] = ""
  out[#out + 1] = ("  gesamt: %d Zeilen in %d Dateien, davon %d Zeilen aus Korpus-Dateien"):format(
    c.rows,
    c.files_with_rows,
    c.meta_rows
  )
  out[#out + 1] =
    "          (All/Collisions/Overview — die prüft der Driftlauf nicht gegen live)"

  out[#out + 1] = ""
  out[#out + 1] = "Live in dieser Session"
  out[#out + 1] = ""
  out[#out + 1] = ("  Keymaps    %4d global (%s)"):format(l.keymaps_global, l.keymaps_by_mode)
  out[#out + 1] = ("             %4d buffer-lokal in den offenen Buffern"):format(l.keymaps_buffer)
  out[#out + 1] = ("  Usercmds   %4d"):format(l.usercmds)
  out[#out + 1] = ("  Autocmds   %4d in %d Gruppen"):format(l.autocmds, l.autocmd_groups)

  out[#out + 1] = ""
  out[#out + 1] = "Plugins"
  out[#out + 1] = ""
  if total > 0 then
    out[#out + 1] = ("  lazy.nvim kennt %d, geladen sind %d — die %d ungeladenen prüft"):format(
      total,
      loaded,
      total - loaded
    )
    out[#out + 1] = "  nur `:Bindings check repo` (Quelltext statt laufender Session)"
  else
    out[#out + 1] = "  lazy.nvim nicht verfügbar — jedes Plugin gilt dem Driftlauf als geladen"
  end

  local dirs, reason = config.repo_dirs()
  out[#out + 1] = dirs and ("  Checkouts für die Repo-Achse: %d aufgelöst"):format(#dirs)
    or ("  Checkouts für die Repo-Achse: keine — %s"):format(reason or "unbekannt")

  out[#out + 1] = ""
  out[#out + 1] = "Letzter geschriebener Driftbericht"
  out[#out + 1] = ""
  out[#out + 1] = report and ("  %s"):format(report)
    or "  keiner — `:Bindings report` schreibt den ersten"
  out[#out + 1] = ("  %s"):format(report_dir)

  out[#out + 1] = ""
  out[#out + 1] = "Routen"
  out[#out + 1] = ""
  for _, r in ipairs(ROUTES) do
    out[#out + 1] = ("  %-60s %s"):format(r[1], r[2])
  end

  return out
end

---@return nil
function M.open()
  require("lib.nvim.ui.kit.viewer").open({
    title = "Bindings — status",
    lines = M.lines(),
  })
end

return M
