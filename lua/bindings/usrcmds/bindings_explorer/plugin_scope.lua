---@module 'bindings.usrcmds.bindings_explorer.plugin_scope'
--- Plugin scope: which cheatsheet files a plugin name stands for.
---
--- `:Bindings search keymaps hover.nvim` narrows the search to hover.nvim's
--- sheet instead of grepping all 166 of them. The corpus names one file per
--- plugin (`records.lua`'s `plugin` field IS the filename stem), so a scope is
--- resolved by matching a typed token against those stems and handing back the
--- files. `live.lua`/`search.lua` take a path list either way, so a scoped
--- search is the same search over fewer paths -- ripgrep accepts files where
--- it accepts directories, and so do all three picker engines' path options.
---
--- **Two matching strengths, on purpose.** The first positional of `search`
--- carries either a plugin or a query (`:Bindings search keymaps redact` is a
--- query, and was one before scopes existed), so a token only counts as a
--- scope when it names a sheet outright: the stem itself with case ignored, or
--- the same name modulo the `.nvim`/`nvim-` decoration everyone spells
--- differently (`hover` -> `hover.nvim`, `neotree` -> `NeoTree`). Prefix
--- matching would swallow queries -- `doc` is a word one searches for as well
--- as the head of `documentation.nvim` -- so it is reserved for the explicit
--- `plugin=` form, where the intent is not in doubt.
---
--- **A token may name more than one sheet, and that is not an error here.**
--- `dap` is `Keymaps/dap.nvim.md` (personal) and `Keymaps/Dap.md` (extern):
--- one plugin, documented from both sides. A search over both is what was
--- asked for. Only `check`/`report` need a single stem (they filter on
--- `rec.plugin == plugin`), and `init.lua` narrows there, not here.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local config = require("bindings.usrcmds.bindings_explorer.config")

local M = {}

M.CATEGORIES = { "Keymaps", "Usercmds", "Autocmds" }

--- Subcommand token -> the category folder it scopes to. Also the set of
--- tokens that must never be read as a plugin name.
M.CATEGORY_TOKENS = { keymaps = "Keymaps", usercmds = "Usercmds", autocmds = "Autocmds" }

--- `config.roots()` returns Personal then Extern, always in that order — same
--- index-based labelling as `records.lua`'s `ROOT_SCOPES`, and for the same
--- reason: a future rename of a root directory must not silently flip a label.
local ROOT_SCOPES = { "Personal", "Extern" }

--- A plugin name reduced to what a cheatsheet stem and a typed token have in
--- common: case, the `nvim`/`vim` affixes everyone spells differently, and the
--- separators.
---
--- Deliberately not a similarity score. Every transformation here removes
--- something both sides agree is decoration; nothing here shortens one name
--- towards another. `drift.lua` matches cheatsheet stems against lazy.nvim's
--- plugin names with exactly this function — it is required from here rather
--- than written twice, so a rule added for one side cannot go missing on the
--- other.
---@param s string
---@return string
function M.normalize(s)
  s = s:lower()
  s = s:gsub("%.nvim$", "")
    :gsub("^nvim%-", "")
    :gsub("^vim%-", "")
    :gsub("%-vim$", "")
    :gsub("%.vim$", "")
  return (s:gsub("[%-_%.]", ""))
end

---@class Bindings.Sheet
---@field stem string cheatsheet filename without extension, e.g. "hover.nvim"
---@field file string absolute path
---@field category "Keymaps"|"Usercmds"|"Autocmds"
---@field scope "Personal"|"Extern"

--- How long a corpus listing stays good. Completion asks per keystroke, and
--- re-reading six directories for every character typed is wasted work; the
--- corpus does change while one edits it, though, so the answer expires rather
--- than being cached for the session.
local CACHE_TTL_MS = 5000

---@type Bindings.Sheet[]|nil
local cache_entries = nil
local cache_at = 0

---@return integer  # monotonic milliseconds
local function now_ms()
  return (vim.uv or vim.loop).now()
end

--- Every cheatsheet in the corpus.
---
--- Only the three category folders, not the roots themselves: a file directly
--- under a root (`autocmds-by-event.md`, `autocmds-by-plugin.md`) indexes the
--- corpus across plugins rather than documenting one, so it is not a scope.
--- `All.md`/`Collisions.md`/`Overview.md` ARE offered — they sit in a category
--- folder, they are named like any other sheet, and scoping a search to them
--- is a reasonable thing to want; `records.lua`'s `META_FILES` marks them for
--- the drift axes, which is a different question from "can I search it".
---@return Bindings.Sheet[]
local function sheets()
  if cache_entries and (now_ms() - cache_at) < CACHE_TTL_MS then
    return cache_entries
  end

  local plugin_sheets = config.plugin_sheets() or {}

  -- Dieselbe Vorrang-Regel wie in `records.lua`s `each_file`: wo ein Plugin
  -- seine eigene `docs/BINDINGS.md` mitbringt, ist das alte Cheatsheet die
  -- Abschrift und wird übergangen. Ohne das stünde jeder Stamm zweimal in
  -- der Completion und `resolve` bekäme zwei Dateien für einen Namen.
  local superseded = {}
  for _, sheet in ipairs(plugin_sheets) do
    superseded[sheet.plugin] = true
    -- `buffer-ctx.md` heißt als einziges Cheatsheet nicht wie sein Plugin
    -- (`buffer-ctx.nvim`) -- siehe die gleichlautende Stelle in `records.lua`.
    superseded[(sheet.plugin:gsub("%.nvim$", ""))] = true
  end

  local out = {}
  for idx, root in ipairs(config.roots()) do
    local scope = ROOT_SCOPES[idx]
    for _, category in ipairs(M.CATEGORIES) do
      local dir = vim.fs.joinpath(root, category)
      if vim.fn.isdirectory(dir) == 1 then
        for _, f in ipairs(collect_recursive.files(dir)) do
          local stem = vim.fn.fnamemodify(f, ":t:r")
          if f:match("%.md$") and not superseded[stem] then
            out[#out + 1] = {
              stem = stem,
              file = f,
              category = category,
              scope = scope,
            }
          end
        end
      end
    end
  end

  -- Ein Personal-Plugin bringt seine drei Kategorien in **einer** Datei mit
  -- (`docs/BINDINGS.md`), der Cheatsheet-Korpus in dreien. Damit
  -- `:Bindings browse keymaps hover.nvim` weiter auflöst, steht das Repo-Sheet
  -- unter allen drei Kategorien -- mit demselben Pfad.
  --
  -- Die Folge, ausgesprochen statt versteckt: `browse` ist davon unberührt,
  -- weil es über `records.lua` geht und dort jede Zeile ihre eigene, aus dem
  -- Abschnitt abgeleitete Kategorie trägt. `search` greppt dagegen Dateien,
  -- und eine kategoriegescopte Suche auf einem Repo-Sheet durchsucht die
  -- ganze Datei -- ein Treffer aus dem Usercmds-Abschnitt kann bei
  -- `search keymaps <plugin>` also mitkommen. Das ist eine Ungenauigkeit im
  -- Volltext, kein falscher Befund: die Zeile steht wirklich in der Doku
  -- dieses Plugins.
  for _, sheet in ipairs(config.plugin_sheets() or {}) do
    for _, category in ipairs(M.CATEGORIES) do
      out[#out + 1] = {
        stem = sheet.plugin,
        file = sheet.file,
        category = category,
        scope = "Personal",
      }
    end
  end

  cache_entries, cache_at = out, now_ms()
  return out
end

---@class Bindings.ScopeOpts
---@field category ("Keymaps"|"Usercmds"|"Autocmds")|nil nil = all three
---@field scope ("personal"|"extern")|nil nil = both roots
---@field fuzzy boolean|nil allow prefix matching (only for the explicit `plugin=` form)

--- The sheets an opts pair selects, before any name matching.
---@param opts Bindings.ScopeOpts|nil
---@return Bindings.Sheet[]
local function pool(opts)
  opts = opts or {}
  local scope = opts.scope and opts.scope:lower() or nil
  local out = {}
  for _, sheet in ipairs(sheets()) do
    local cat_ok = not opts.category or sheet.category == opts.category
    local scope_ok = not scope or sheet.scope:lower() == scope
    if cat_ok and scope_ok then
      out[#out + 1] = sheet
    end
  end
  return out
end

---@param list string[]
---@return string[]
local function sorted_unique(list)
  local seen, out = {}, {}
  for _, v in ipairs(list) do
    if not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  table.sort(out, function(a, b)
    return a:lower() < b:lower()
  end)
  return out
end

--- Every cheatsheet stem in the corpus (or in one category/scope of it),
--- sorted, each name once however many categories it appears in.
---@param opts Bindings.ScopeOpts|nil
---@return string[]
function M.stems(opts)
  local names = {}
  for _, sheet in ipairs(pool(opts)) do
    names[#names + 1] = sheet.stem
  end
  return sorted_unique(names)
end

---@class Bindings.PluginMatch
---@field stems string[] every cheatsheet stem the token names, sorted
---@field exact string[] the subset matched verbatim (case ignored) — what breaks a tie for the single-stem callers
---@field files string[] the sheets those stems own, within the asked category/scope
---@field label string stems joined with "+", for prompts and titles

---@param matched Bindings.Sheet[]
---@param exact Bindings.Sheet[]
---@return Bindings.PluginMatch
local function to_match(matched, exact)
  local stems, files, exact_stems = {}, {}, {}
  for _, sheet in ipairs(matched) do
    stems[#stems + 1] = sheet.stem
    files[#files + 1] = sheet.file
  end
  for _, sheet in ipairs(exact) do
    exact_stems[#exact_stems + 1] = sheet.stem
  end
  stems = sorted_unique(stems)
  return {
    stems = stems,
    exact = sorted_unique(exact_stems),
    files = files,
    label = table.concat(stems, "+"),
  }
end

--- The stems whose normalized name contains the token's — for the "did you
--- mean" half of an error message, not for matching.
---@param token string
---@param opts Bindings.ScopeOpts|nil
---@return string[]  # at most six
function M.near(token, opts)
  local norm = M.normalize(token)
  if norm == "" then
    return {}
  end
  local hits = {}
  for _, stem in ipairs(M.stems(opts)) do
    if M.normalize(stem):find(norm, 1, true) then
      hits[#hits + 1] = stem
      if #hits == 6 then
        break
      end
    end
  end
  return hits
end

--- Why `token` names no sheet, in German, with the near misses if there are
--- any — the message every caller shows for an unresolvable scope.
---@param token string
---@param opts Bindings.ScopeOpts|nil
---@return string
function M.unknown_message(token, opts)
  local near = M.near(token, opts)
  if #near > 0 then
    return ("kein Cheatsheet zu '%s' — gemeint: %s?"):format(token, table.concat(near, ", "))
  end
  return ("kein Cheatsheet zu '%s' — <Tab> listet die %d Stämme"):format(token, #M.stems(opts))
end

--- Resolve a typed token to the cheatsheets it names.
---
--- Three steps, in this order (see the module doc for why the third one is
--- opt-in):
---   1. the stem verbatim, case ignored;
---   2. the stem modulo `.nvim`/`nvim-`/separators (`M.normalize`);
---   3. only with `opts.fuzzy`: normalized prefix, and only when every hit
---      belongs to ONE name — `d` naming four plugins is a question, not a
---      scope, and comes back as an error rather than as all four.
---
--- Steps 1 and 2 are unioned, not tried in sequence: `Dap` matches the extern
--- sheet verbatim and the personal `dap.nvim` after normalization, and both
--- document the same plugin.
---@param token string|nil
---@param opts Bindings.ScopeOpts|nil
---@return Bindings.PluginMatch|nil match nil when the token names nothing (with `fuzzy`, see `err`)
---@return string|nil err set only for `fuzzy`: unknown or ambiguous, ready to show
function M.resolve(token, opts)
  opts = opts or {}
  if type(token) ~= "string" or token == "" then
    return nil, nil
  end

  local lower, norm = token:lower(), M.normalize(token)
  local matched, exact = {}, {}
  for _, sheet in ipairs(pool(opts)) do
    if sheet.stem:lower() == lower then
      matched[#matched + 1] = sheet
      exact[#exact + 1] = sheet
    elseif norm ~= "" and M.normalize(sheet.stem) == norm then
      matched[#matched + 1] = sheet
    end
  end
  if #matched > 0 then
    return to_match(matched, exact), nil
  end

  if not opts.fuzzy or norm == "" then
    return nil, nil
  end

  -- Prefix, grouped by name: several sheets of ONE plugin are the scope,
  -- several plugins are an ambiguity the caller has to spell out.
  local by_stem, prefixed = {}, {}
  for _, sheet in ipairs(pool(opts)) do
    if M.normalize(sheet.stem):sub(1, #norm) == norm then
      prefixed[#prefixed + 1] = sheet
      by_stem[M.normalize(sheet.stem)] = true
    end
  end
  if #prefixed == 0 then
    return nil, M.unknown_message(token, opts)
  end
  if vim.tbl_count(by_stem) > 1 then
    local match = to_match(prefixed, {})
    return nil,
      ("'%s' ist mehrdeutig: %s — bitte den Stamm ausschreiben"):format(
        token,
        table.concat(match.stems, ", ")
      )
  end
  return to_match(prefixed, {}), nil
end

--- The category a half-typed command line already scopes to, so completion in
--- a plugin slot offers the sheets of THAT category rather than all of them.
--- `nil` when no category token was typed (`:Bindings search hover…`), which
--- is the whole corpus and therefore the right candidate list too.
---@param cmd_line string|nil
---@return ("Keymaps"|"Usercmds"|"Autocmds")|nil
function M.category_from_cmdline(cmd_line)
  if type(cmd_line) ~= "string" then
    return nil
  end
  for token in cmd_line:gmatch("%S+") do
    local category = M.CATEGORY_TOKENS[token:lower()]
    if category then
      return category
    end
  end
  return nil
end

--- Case-insensitive prefix filter. Composer's own `argtypes.prefix` is
--- case-sensitive (right for enum members, which are spelled one way); a
--- cheatsheet stem is spelled the way its plugin is, so `gits<Tab>` has to
--- reach `Gitsigns`.
---@param candidates string[]
---@param arg_lead string
---@param out string[] appended to in place
---@return nil
local function add_prefixed(candidates, arg_lead, out)
  local lead = arg_lead:lower()
  for _, c in ipairs(candidates) do
    if lead == "" or c:lower():sub(1, #lead) == lead then
      out[#out + 1] = c
    end
  end
end

--- The composer argument type for a plugin-scope slot: `<Tab>` offers the
--- cheatsheet stems of the category already typed, plus whatever the slot
--- declares in `values` (`browse` accepts `personal`/`extern` in the same
--- position).
---
--- Validation is deliberately a no-op. The slot holds a scope OR a query, and
--- only the route's handler knows which — rejecting a token here would reject
--- every query that is not a plugin name.
---@return Lib.UserCmd.Composer.TypeDef
function M.argtype()
  return {
    validate = function(raw)
      return true, raw, nil
    end,
    complete = function(arg_lead, spec, cmd_line)
      local out = {}
      add_prefixed(spec.values or {}, arg_lead, out)
      add_prefixed(M.stems({ category = M.category_from_cmdline(cmd_line) }), arg_lead, out)
      return out
    end,
  }
end

--- Every file the corpus can search, across all three sources (the two
--- physical trees plus each plugin's own `docs/BINDINGS.md`), deduplicated by
--- path.
---
--- Built for `search.lua`/`live.lua`'s **unscoped** searches. A plugin scope
--- already goes through `M.resolve` -> `Bindings.PluginMatch.files`, which has
--- read `plugin_sheets()` since the day this module was written; `init.lua`'s
--- `M.search` fell back to `config.roots()`/`config.roots_for(category)`
--- directly whenever no plugin was named, which are the two physical trees
--- only. `BND-04` then deleted the personal half of those trees plugin by
--- plugin (each sheet superseded by the plugin's own `docs/BINDINGS.md`, see
--- `sheets()` above), so a bare `:Bindings search <query>` or
--- `:Bindings search keymaps <query>` stopped finding anything in any of the
--- 31 personal plugins' own docs -- silently, because grep-over-nothing looks
--- exactly like grep-over-everything-with-no-hits. This function is `sheets()`
--- reduced to just the paths, so both call sites read the same corpus
--- `M.resolve` already does.
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil nil = all three
---@return string[]
function M.all_files(category)
  local seen, out = {}, {}
  for _, sheet in ipairs(pool({ category = category })) do
    if not seen[sheet.file] then
      seen[sheet.file] = true
      out[#out + 1] = sheet.file
    end
  end
  return out
end

--- Drop the corpus listing. For tests and for a caller that just wrote a
--- sheet and wants the next completion to see it.
---@return nil
function M.reset()
  cache_entries, cache_at = nil, 0
end

return M
