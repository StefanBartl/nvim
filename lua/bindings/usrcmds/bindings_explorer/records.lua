---@module 'bindings.usrcmds.bindings_explorer.records'
--- Phase 2 (see this module's own docs/FEATURES.md): tolerant
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

--- Files in the corpus that are ABOUT the corpus rather than a cheatsheet for
--- one plugin: `All.md` indexes the folder, `Collisions.md` and `Overview.md`
--- are cross-plugin analyses. Their tables hold real keys and real command
--- names, so they parse like any other sheet — but nobody registers them, and
--- `drift.lua` reported 17 of them as "documented, not live" (`Collisions`'
--- own point being that those keys are claimed *twice*, which is the opposite
--- of missing).
---
--- Marked rather than dropped: `browse`/`search` want these rows, and so does
--- drift's other direction — a command named in `Overview.md` IS documented,
--- it just is not owned there. See `drift.lua`'s use of the flag.
local META_FILES = { All = true, Collisions = true, Overview = true }

--- A section that declares its own rows unverifiable against a live session.
---
--- Written directly under the heading, on its own line:
---
---     ### Durch `VM_default_mappings = 0` deaktiviert
---
---     **Nicht live:** Plugin-Defaults, die diese Config abschaltet.
---
--- Three shapes of table need it, and all three exist in the corpus today:
--- keys a plugin ships but this config switched off, keys of a foreign TUI
--- that Neovim never registers (`Keymaps/Lazygit.md`'s LazyGit column), and
--- cross-reference tables that point at other sheets rather than claiming
--- anything.
---
--- **Why not just rename the column.** `normalize_header` strips a
--- parenthesised group on purpose, so `Default-Mapping (Plugin)` and
--- `Taste (in LazyGit)` both reduce to a known lhs header -- deliberately, so
--- the scraper survives the corpus' dozen spellings. Renaming a header to
--- dodge that would couple prose wording to parser internals and break the
--- next time someone rewords it. A marker says what it means.
---
--- Only the LIVE direction honours it. The rows still parse, still show up in
--- `:Bindings browse`, and still count as documentation for the
--- live-but-undocumented direction -- the same split `META_FILES` makes.
local NOT_LIVE_MARKER = "^%*%*Nicht live:%*%*"

---@class Bindings.Record
---@field scope "Personal"|"Extern"
---@field category "Keymaps"|"Usercmds"|"Autocmds"
---@field plugin string filename without extension, e.g. "images.nvim" or "Telescope"
---@field meta boolean true for a corpus-level file (see `META_FILES`), which owns no bindings of its own
---@field not_live boolean true when the section this row sits in declared itself unverifiable against a running session (see `NOT_LIVE_MARKER`)
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

--- Split a row at its column separators, which are the UNESCAPED `|`
--- only. `\|` is markdown's literal-pipe escape — the sole way to write a
--- `|` inside a cell — and is resolved back to a plain `|` in the cell
--- value, so a caller sees the text the row renders as. Splitting on it
--- too (this function's original behaviour) shredded every such row into
--- fragments: `` `]\|` / `[\|` `` in `Keymaps/markdown.nvim.md` became a
--- cell `` `]\ ``, which `drift.lua` then dutifully reported as a
--- documented-but-not-live keymap.
---
--- `\` before anything else is NOT an escape here and stays literal — the
--- corpus writes keys like `` `g\` `` (gopath.nvim), and only `|` needs
--- escaping for a table row to survive. It does consume the next byte
--- though, so a doubled `\\` cannot swallow the separator behind it.
---@param line string
---@return string[]
local function split_cells(line)
  local trimmed = vim.trim(line):gsub("^|", "")
  -- Only an unescaped trailing `|` closes the row; a `\|` ending the line
  -- is a literal pipe whose cell simply runs to the end.
  if trimmed:sub(-1) == "|" and trimmed:sub(-2, -2) ~= "\\" then
    trimmed = trimmed:sub(1, -2)
  end

  local cells, buf, i = {}, {}, 1
  while i <= #trimmed do
    local c = trimmed:sub(i, i)
    if c == "\\" then
      local nxt = trimmed:sub(i + 1, i + 1)
      buf[#buf + 1] = nxt == "|" and "|" or (c .. nxt)
      i = i + 2
    elseif c == "|" then
      cells[#cells + 1] = vim.trim(table.concat(buf))
      buf, i = {}, i + 1
    else
      buf[#buf + 1] = c
      i = i + 1
    end
  end
  cells[#cells + 1] = vim.trim(table.concat(buf))

  return cells
end

---@param path string
---@param scope "Personal"|"Extern"
---@param category "Keymaps"|"Usercmds"|"Autocmds"
---@return Bindings.Record[]
local function parse_file(path, scope, category)
  local content = read(path)
  if not content then
    return {}
  end

  local plugin = vim.fn.fnamemodify(path, ":t:r")
  local meta = META_FILES[plugin] == true
  local records = {}
  local heading, columns, awaiting_separator = nil, nil, false
  -- Scoped to the section, not to the file: a sheet can hold one unverifiable
  -- table next to five ordinary ones, and `Keymaps/VisualMulti.md` does.
  local not_live = false

  local lines = vim.split(content:gsub("\r", ""), "\n", { plain = true })
  for lnum, line in ipairs(lines) do
    local h = line:match("^##+%s+(.+)$")
    if h then
      heading, columns, awaiting_separator = vim.trim(h), nil, false
      not_live = false
    elseif line:match(NOT_LIVE_MARKER) then
      -- Ends a running table exactly like any other prose line would, so the
      -- marker behaves as text that happens to carry a flag rather than as a
      -- third kind of line the parser has to be careful around.
      not_live = true
      columns, awaiting_separator = nil, false
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
          meta = meta,
          not_live = not_live,
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

--- Call `fn(path, root_scope, category)` for every `.md` file of the corpus.
---@param categories string[]
---@param scope ("personal"|"extern")|nil
---@param fn fun(path: string, scope: "Personal"|"Extern", category: string): nil
---@return nil
local function each_file(categories, scope, fn)
  for idx, root in ipairs(config.roots()) do
    local root_scope = ROOT_SCOPES[idx]
    if not scope or scope:lower() == root_scope:lower() then
      for _, cat in ipairs(categories) do
        local dir = vim.fs.joinpath(root, cat)
        if vim.fn.isdirectory(dir) == 1 then
          for _, f in ipairs(collect_recursive.files(dir)) do
            if f:match("%.md$") then
              fn(f, root_scope, cat)
            end
          end
        end
      end
    end
  end
end

--- Every table row across the BINDINGS corpus, optionally narrowed to one
--- category and/or one scope.
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil nil = all three
---@param scope ("personal"|"extern")|nil nil = both
---@return Bindings.Record[]
function M.list(category, scope)
  local categories = category and { category } or { "Keymaps", "Usercmds", "Autocmds" }
  local out = {}
  each_file(categories, scope, function(path, root_scope, cat)
    vim.list_extend(out, parse_file(path, root_scope, cat))
  end)
  return out
end

--- The command names written in `text`, in order.
---
--- A name only counts when the `:` does NOT follow a word character. Without
--- that guard `path:L1-L2` — prose in `Usercmds/buffer-ctx.md` explaining the
--- `location` subcommand's output — reads as a command `:L1`, and `drift.lua`
--- reported it as documented-but-not-registered. Neovim's own `:` notation
--- never appears glued to a preceding word, so the rule costs nothing and
--- removes the whole class.
---@param text string
---@return string[]
function M.command_names(text)
  local out, init = {}, 1
  while true do
    local s, e, name = text:find(":(%u[%w_]*)", init)
    if not s then
      return out
    end
    local prev = s > 1 and text:sub(s - 1, s - 1) or ""
    if not prev:match("[%w_]") then
      out[#out + 1] = name
    end
    init = e + 1
  end
end

--- What a wildcard may stand for, per kind of name.
---
--- Command names are Lua-identifier-shaped, so `[%w_]` is the whole alphabet.
--- Augroup names are not: this config runs `ra_telemetry_lib.nvim` and
--- `ra_telemetry_runtime-analysis.nvim`, both named after a plugin, dot and
--- hyphen included. A shared class would either miss those or let a command
--- family reach across a `.` it has no business crossing.
--- Written with DOUBLED percent signs because these go through `gsub`'s
--- replacement argument, where `%` is an escape: a literal `[%w_]+` there is
--- "invalid use of '%' in replacement string", and the class has to arrive as
--- `[%%w_]+` to come out as `[%w_]+`. The original inline version had this
--- right; hoisting it into a named table lost it, and the damage was silent
--- in the worst way -- the command families stopped matching and 18 findings
--- came back that had been correctly suppressed for two days.
local WILDCARD_CLASS = {
  command = "[%%w_]+",
  augroup = "[%%w_%%.%%-]+",
}

--- One `*`- or `<name>`-bearing token as an anchored Lua pattern.
---
--- **Two spellings, and the corpus chose the second one first.** `:*Files`
--- reads well for commands, where the varying part has no name worth writing.
--- For augroups the corpus already wrote `ra_telemetry_<namespace>`
--- (`runtime-analysis.nvim.md`) and `LspSignaturePopup_<winid>`
--- (`lsp.nvim.md`) long before anything could read them -- a placeholder that
--- *names* what varies, which is better documentation than a star. Both are
--- accepted; `<name>` is the one to write for augroups.
---
--- At least three literal word characters are required. `<x>` or `*` alone
--- would claim every name in the corpus at once, which is not documentation.
---@param token string
---@param kind "command"|"augroup"
---@return string|nil  # nil when the token carries no wildcard, or too little else
function M.wildcard_pattern(token, kind)
  if not token:find("%*") and not token:find("<.->") then
    return nil
  end
  local literal = token:gsub("<.->", ""):gsub("%*", "")
  if #literal:gsub("[^%w_]", "") < 3 then
    return nil
  end
  local class = WILDCARD_CLASS[kind] or WILDCARD_CLASS.command
  local escaped = token:gsub("[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0")
  -- The escape above turned `<name>` into `<name>` still (angle brackets are
  -- not pattern syntax), so both placeholder forms are replaced here.
  escaped = escaped:gsub("<.->", class):gsub("%*", class)
  return "^" .. escaped .. "$"
end

--- The command-name FAMILIES a text claims with a `*`, as Lua patterns.
---
--- A generated family has no business being listed one member at a time. The
--- 2026-09-02 drift report made the case on pickers.nvim's 23 scope commands
--- (`:NotesFiles`, `:WkdbooksGrep`, `:SpickzettelSmart`, ...): they come out
--- of a loop over a collection list in the config, so writing them into a
--- cheatsheet by hand would be exactly the hand-kept mirror this repo treats
--- as a defect everywhere else. Its conclusion was that the sheet should
--- document the GENERATOR, and that the check should accept a family
--- described that way. This is the second half of that.
---
--- `*` stands for one or more word characters, so `:*Files` claims
--- `:NotesFiles` but not a bare `:Files`. At least three literal word
--- characters are required: `:*` or `:A*` would claim most of the corpus at
--- once, which is not documentation.
---
--- **Only for the live-but-undocumented direction.** A family carries no
--- concrete command, so nothing about it can be checked for liveness -- the
--- same asymmetry `M.mentions` has, and for the same reason.
---
--- Text in, patterns out. Which text counts as a claim is `M.family_claims`'
--- decision, and it is narrower than "anywhere in the file".
---@param text string
---@return string[] lua patterns, anchored
function M.command_globs(text)
  local out, init = {}, 1
  while true do
    local s, e, glob = text:find(":([%w_]*%*[%w_%*]*)", init)
    if not s then
      return out
    end
    local prev = s > 1 and text:sub(s - 1, s - 1) or ""
    if not prev:match("[%w_]") then
      local pattern = M.wildcard_pattern(glob, "command")
      if pattern then
        out[#out + 1] = pattern
      end
    end
    init = e + 1
  end
end

--- Every command name mentioned ANYWHERE in the corpus, tables and prose
--- alike.
---
--- The scraper reads table rows, so a command documented as a bullet or in a
--- sentence counts as undocumented — 31 of them in the 2026-09-02 drift run
--- (`:LuaLsReloadLibrary` in `Usercmds/lsp.nvim.md`'s prose, `:AllDrives` and
--- `:RepoGrep` as a `·`-separated list in `pickers.nvim.md`). For the
--- live-but-undocumented direction the question is only "does this corpus
--- mention it at all", and this answers exactly that. The other direction
--- still needs a row: a mention carries no key, mode or file position to
--- check anything against.
---@return table<string, true>
function M.mentions()
  local out = {}
  each_file({ "Keymaps", "Usercmds", "Autocmds" }, nil, function(path)
    local content = read(path)
    if not content then
      return
    end
    for _, name in ipairs(M.command_names(content)) do
      out[name] = true
    end
  end)
  return out
end

--- What a sheet says its plugin is called, for the sheets where guessing
--- would be wrong.
---
--- A cheatsheet's stem is a human's name for a plugin (`NvChadUI`), the
--- package manager's is the repository's (`ui`). For 21 of the extern
--- corpus' 24 stems the two meet after normalization; for three they do not,
--- and no amount of string surgery gets `Blink` to `blink.cmp` or `Dap` to
--- one of `dap.nvim`/`nvim-dap` rather than the other. Those three say it
--- themselves, in a line the reader sees too:
---
---     **Repo:** `NvChad/ui`
---
--- Either half of an `owner/name` slug is accepted; the last segment is what
--- lazy.nvim keys its plugin table by. Read from the file's prose rather
--- than from a table row on purpose -- it is a statement about the sheet,
--- not a binding, and a table row would have to be excluded from every other
--- axis by hand.
---@return table<string, string>  # sheet stem -> plugin name
function M.repo_hints()
  local out = {}
  each_file({ "Keymaps", "Usercmds", "Autocmds" }, nil, function(path)
    local stem = vim.fn.fnamemodify(path, ":t:r")
    if out[stem] then
      return
    end
    local content = read(path)
    if not content then
      return
    end
    local slug = content:match("%*%*Repo:%*%*%s*`([^`]+)`")
    if slug then
      out[stem] = vim.trim(slug:match("([^/]+)$") or slug)
    end
  end)
  return out
end

--- The raw text of one plugin's sheets in `category`, both roots joined.
---
--- For the questions a table row cannot answer. `Autocmds/sessions.nvim.md`
--- names its augroup in a sentence above the table ("Single augroup
--- `SessionsNvim`") and has no Augroup column at all -- six rows that document
--- their group perfectly well and that a column reader cannot see.
---
--- Scoped to the owning plugin's own sheet, not the whole corpus: an augroup
--- named after its plugin (`pickers.nvim` is one) would match somewhere in
--- 33 files no matter what, and "documented" would stop meaning anything.
---@param category "Keymaps"|"Usercmds"|"Autocmds"
---@param plugin string  # a `Bindings.Record.plugin`, i.e. a filename stem
---@return string  # "" when the plugin has no sheet in this category
function M.sheet_text(category, plugin)
  local parts = {}
  each_file({ category }, nil, function(path)
    if vim.fn.fnamemodify(path, ":t:r") == plugin then
      parts[#parts + 1] = read(path) or ""
    end
  end)
  return table.concat(parts, "\n")
end

---@class Bindings.FamilyClaim
---@field plugin string the claiming cheatsheet's stem, e.g. "pickers.nvim"
---@field pattern string anchored Lua pattern over the command name

--- Every command FAMILY the corpus claims, each tied to the sheet claiming it.
---
--- Two deliberate narrowings, both found by measuring the loose version
--- against the real corpus:
---
--- **Table rows only, never prose.** The corpus writes `:Lsp*`, `:Diff*`,
--- `:Copy*`, `:Image*` in sentences as a typographic shorthand for "those
--- commands", not as a claim to every name that fits. Reading prose globs
--- turned 18 families loose on the report, `^Lsp[%w_]+$` among them. A table
--- row is the deliberate statement; a sentence is not.
---
--- **A family only covers its own plugin's commands.** `:*Files` from
--- `pickers.nvim.md` otherwise also claimed diffview.nvim's
--- `:DiffviewFocusFiles` and `:DiffviewToggleFiles` -- two third-party
--- commands silently marked as documented by a sheet that says nothing about
--- them. `drift.lua` pairs each claim with `command_owner`'s answer, which is
--- the piece that only became available once the owner was recorded at all.
---@return Bindings.FamilyClaim[]
function M.family_claims()
  local out = {}
  for _, rec in ipairs(M.list("Usercmds")) do
    for _, cell in ipairs(rec.cells) do
      for _, pattern in ipairs(M.command_globs(cell)) do
        out[#out + 1] = { plugin = rec.plugin, pattern = pattern }
      end
    end
  end
  return out
end

return M
