---@module 'bindings.usrcmds.bindings_explorer.drift'
--- Phase 3 (see this module's own docs/FEATURES.md, "Drift-Bericht"): drift
--- report between documented bindings (`records.lua`'s parsed rows) and
--- what's actually registered right now (`nvim_get_keymap`/
--- `nvim_get_commands`). Read-only, no autofix — same stance as
--- casedesk's `:Cases doctor` (see its module doc): a cheatsheet's
--- handwritten rationale is worth more than what an autofix could
--- reconstruct, so this only ever reports.
---
--- Deliberately narrower than the roadmap's original sketch, in four ways:
---
--- 1. **Keymaps checked one direction only** (documented-but-not-live).
---    The reverse (live-but-undocumented) would mean diffing against
---    EVERY global keymap — vim's own defaults, matchit, every plugin's
---    own bindings — which floods the report with things this corpus was
---    never meant to document. Not attempted here.
--- 2. **Personal only, not Extern**, for the "documented" side. Extern/
---    documents third-party plugins' own bindings; most of those are
---    never registered by this config's own code, so comparing them
---    against this Neovim's live state would report "missing" for
---    bindings that were never ours to register. Personal/ is exactly the
---    corpus the motivating case (images.nvim.md, see the roadmap's
---    opening paragraph) came from. Usercmds' reverse direction (below)
---    still consults Extern, just not to decide what's "ours to check".
--- 3. **Buffer-local / filetype-scoped keymaps — mitigated, not solved.**
---    `nvim_get_keymap` only sees GLOBAL maps, so a documented `<leader>im`
---    registered per-filetype (`keymaps.filetypes = {"markdown",...}`), or
---    a picker key bound to its own prompt buffer, used to report as
---    "documented-not-live" while being correctly registered. This was the
---    dominant false-positive class by volume: a real report ran to 682
---    findings, unreadable and dominated by in-window keys of plugins whose
---    UI simply wasn't open. Two things address it now, neither of which
---    drops a finding:
---      - `live_keymaps` also reads `nvim_buf_get_keymap` for every loaded
---        buffer, so a UI that IS open is verified properly.
---      - what remains gets a per-table verdict (see `M.check`): a
---        documented table where not one key is live is reported as one
---        "not verifiable from here" line naming the table, instead of N
---        "missing" lines. `M.describe` renders it in its own section,
---        below the findings that are worth acting on.
---    A table needs more than one row for the verdict to apply, so a
---    genuinely one-row scope (github_stats' detail-view float) still
---    reports as a single finding. That is the intended floor: one absent
---    key is no evidence about scope.
---
---    Two things had to land together for this to work on the corpus. The
---    docs half: `github_stats.nvim.md` was one unnamed table mixing four
---    scopes, giving the verdict nothing to group on — now split per scope,
---    as BINDINGS-FORMAT.md §1 already required. The code half: splitting
---    it alone changed nothing, because each resulting table still held one
---    key that *looked* live. See `is_live` — matching on lhs alone let an
---    unrelated global map satisfy a documented row, and one such row per
---    table was enough to suppress the verdict for the whole table.
--- 4. **Lazy-loaded plugins are handled, not ignored**: a binding whose
---    owning plugin hasn't loaded yet in the current session (event/cmd/
---    ft-triggered lazy loading) isn't registered yet either — checking
---    it anyway would report it as missing even though nothing is wrong.
---    Empirically, in a freshly started headless session this was NOT a
---    minor edge case: roughly two thirds of plugins with Personal
---    Keymaps entries were still unloaded, and checking them anyway
---    roughly tripled the false "missing" count. `records.lua`'s `plugin`
---    field (the cheatsheet's filename stem) is checked against
---    `require("lazy.core.config").plugins[name]._.loaded` — a plugin
---    name lazy.nvim doesn't know about at all (a core, non-plugin
---    mapping module) is treated as always-loaded, since those load
---    unconditionally at startup. Skipped plugins are reported by name,
---    not silently dropped — see `M.check`'s second return value.
--- 5. **A loaded plugin can still lazily register a command on first API
---    use, not at load time** — a narrower case than point 4, and NOT
---    covered by the `lazy.nvim`-loaded check there. Confirmed against a
---    real example: `Usercmds/lib.nvim.md` documents `:LibLogger` as
---    "Registered when: automatically, on the first `logger.new()`" — in
---    a fresh session where nothing has called `logger.new()` yet, this
---    reports as `usercmd-not-live` even though nothing is broken.
---    Verified headless: the command is genuinely absent from
---    `nvim_get_commands({})` beforehand and appears the instant
---    `logger.new({name=...})` runs. No general fix here — a "Registered
---    when" column, when a cheatsheet documents one at all, is free text,
---    not a machine-checkable condition. Treat any single
---    `usercmd-not-live` finding for a documented-lazy command as
---    suspect; re-run `:Bindings check` after actually exercising that
---    plugin's feature before trusting the finding.
---
--- Usercmds are checked BOTH directions, since `nvim_get_commands({})`
--- only ever returns user-defined commands (no vim-default flood): the
--- live-undocumented direction is cross-checked against Personal AND
--- Extern documented commands, to avoid flagging things documented
--- elsewhere — but plugin-manager/infra commands (`:Lazy`, `:Mason`, ...)
--- with no cheatsheet at all will still show up; no ignore-list is
--- maintained for those.

local records = require("bindings.usrcmds.bindings_explorer.records")

local M = {}

--- Header names (after `normalize_header`) that mark a Keymaps column as
--- the lhs/mode — see the module doc on how inconsistent real column
--- naming turned out to be across the 137-file corpus (checked
--- empirically before writing this list).
local LHS_HEADERS = { lhs = true, key = true, keys = true, ["action key"] = true }
local MODE_HEADERS = { mode = true, modes = true }
local USERCMD_HEADERS = { command = true, invocation = true, subcommand = true }
local DESC_HEADERS = { desc = true, description = true }

--- Cells that fill a `desc` column without naming a description. Checked
--- lowercased, after `strip_quotes`.
local EMPTY_DESC = { [""] = true, none = true, ["-"] = true, ["—"] = true, ["n/a"] = true }

local VALID_MODE_CHARS =
  { n = true, i = true, v = true, x = true, s = true, o = true, t = true, c = true, l = true }

---@param h string
---@return string
local function normalize_header(h)
  h = vim.trim((h:lower():gsub("%s*%b()", "")))
  h = h:gsub("^default%s+", ""):gsub("^config%s+", ""):gsub("^user%-chosen%s+", "")
  return h
end

---@param rec Bindings.Record
---@param headers table<string, boolean>
---@return integer|nil
local function column_index(rec, headers)
  for i, col in ipairs(rec.columns) do
    if headers[normalize_header(col)] then return i end
  end
  return nil
end

--- The literal key notation out of `cell`. Two shapes found empirically in
--- the real corpus:
---  - `` `navigate_down` (`j`) `` — a Lua config-key NAME followed by its
---    literal default key in parens (`github_stats.nvim.md`'s "lhs
---    (config key / default)" columns). The parenthesized group is the
---    actual key; the leading name is never live-checkable and picking it
---    by mistake was this function's original bug (produced findings like
---    "navigate_down"/"cfg.adapter_keymaps" that could never match
---    anything live).
---  - a plain `` `<leader>cnl` `` or `` `gj`/`gk` `` — first backtick
---    group, deliberately only the first of several alternatives, rather
---    than guessing at a combined, unparseable string.
--- Falls back to the whole trimmed cell if there are no backticks at all.
---@param cell string
---@return string
local function first_token(cell)
  local default_key = cell:match("%(`([^`]+)`%)")
  if default_key then return vim.trim(default_key) end
  local inner = cell:match("`([^`]+)`")
  return vim.trim(inner or cell)
end

--- `<leader>iv` -> the same raw byte string `nvim_get_keymap` reports as
--- `.lhsraw` (leader/localleader expanded to their live value, special
--- keys turned into their raw bytes) — empirically just
--- `nvim_replace_termcodes(s, true, true, true)`, nothing more. An
--- earlier version of this ran the result through `vim.fn.keytrans()` and
--- compared against `.lhs` instead — wrong: `.lhs` is a DISPLAY rendering
--- (e.g. `<CR>` stays bracket-notation) but a *printable* result of the
--- leader substitution, like the literal space from `<leader>iv` with
--- `mapleader=" "`, is kept as a raw space in `.lhs` while `keytrans()`
--- re-renders that same space as the text `"<Space>"` — a real Neovim
--- keymap and this function's output would silently never match. `.lhsraw`
--- has no such rendering step, so comparing raw-to-raw is exact.
---@param doc_lhs string
---@return string|nil nil if `doc_lhs` doesn't look like a single, clean token
local function normalize_lhs(doc_lhs)
  -- Reject whitespace/`/`/`,` (ambiguous multi-value cells, see
  -- `first_token`'s doc) AND `.`/`_` — real vim key notation never
  -- contains either, but a Lua config-path/identifier leaking through as
  -- the "lhs" (`cfg.adapter_keymaps`, `keymap_global`) always does. Empirically
  -- the single highest-precision guard found against this corpus.
  if doc_lhs == "" or doc_lhs:find("[%s/,._]") then return nil end
  local ok, raw = pcall(vim.api.nvim_replace_termcodes, doc_lhs, true, true, true)
  if not ok then return nil end
  return raw
end

---@param rec Bindings.Record
---@return string[]
local function extract_modes(rec)
  local idx = column_index(rec, MODE_HEADERS)
  if not idx or not rec.cells[idx] then return { "n" } end
  local out = {}
  for m in rec.cells[idx]:lower():gmatch("%a") do
    if VALID_MODE_CHARS[m] then out[#out + 1] = m end
  end
  return #out > 0 and out or { "n" }
end

--- The corpus writes descs as `"[DAP] Continue"` — the exact string handed
--- to `vim.keymap.set`'s `desc`, quoted. Backticks appear too.
---@param s string
---@return string
local function strip_quotes(s)
  s = vim.trim(s or "")
  s = s:gsub("^[`\"']+", ""):gsub("[`\"']+$", "")
  return vim.trim(s)
end

--- The documented `desc` of a row, or nil when the row does not claim one.
--- Only an explicit `desc`/`description` column counts: other columns hold
--- free prose about the action, which is not what `vim.keymap.set` was
--- given and would never compare equal.
---@param rec Bindings.Record
---@return string|nil
local function extract_desc(rec)
  local idx = column_index(rec, DESC_HEADERS)
  local cell = idx and rec.cells[idx]
  if not cell then return nil end
  local desc = strip_quotes(cell)
  if EMPTY_DESC[desc:lower()] then return nil end
  return desc
end

---@param rec Bindings.Record
---@return string|nil normalized lhs, nil if no usable lhs column/cell
local function extract_lhs(rec)
  local idx = column_index(rec, LHS_HEADERS)
  local cell = idx and rec.cells[idx]
  if not cell or cell == "" then return nil end
  return normalize_lhs(first_token(cell))
end

---@param rec Bindings.Record
---@return string|nil base command name, e.g. "Bindings" from "`:Bindings search`"
local function extract_usercmd(rec)
  local idx = column_index(rec, USERCMD_HEADERS)
  local cell = idx and rec.cells[idx]
  if cell then
    local name = cell:match(":(%u[%w_]*)")
    if name then return name end
  end
  -- Header didn't match a known column, but the command notation might
  -- still be in one of the other cells (e.g. a table this scraper's
  -- header allow-list doesn't recognize).
  for _, c in ipairs(rec.cells) do
    local name = c:match(":(%u[%w_]*)")
    if name then return name end
  end
  return nil
end

--- Whether `plugin` (a `records.lua` `plugin` field, i.e. a cheatsheet's
--- filename stem) is loaded in THIS session — see the module doc's point
--- 4. A name lazy.nvim's plugin registry doesn't know about at all (a
--- core, non-plugin mapping module, or lazy.nvim itself unavailable) is
--- treated as always-loaded rather than skipped.
---@param plugin string
---@return boolean
local function is_plugin_loaded(plugin)
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if not ok then return true end
  local spec = lazy_config.plugins[plugin]
  if not spec then return true end
  return spec._ ~= nil and spec._.loaded ~= nil
end

---@return table<string, boolean>
local function live_commands()
  local out = {}
  for name in pairs(vim.api.nvim_get_commands({})) do
    out[name] = true
  end
  return out
end

--- Command name -> the lazy.nvim plugin whose `cmd` spec declares it.
---
--- Lazy registers a stub command per `cmd` entry so the plugin can load on
--- first use, which means the stub's callback points at lazy's own
--- `handler/cmd.lua`, never at the owner. The spec is the only place that
--- mapping survives.
---@return table<string, string>
local function lazy_cmd_owners()
  local out = {}
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if not ok then return out end
  for name, spec in pairs(lazy_config.plugins) do
    local cmd = spec.cmd
    if type(cmd) == "string" then cmd = { cmd } end
    if type(cmd) == "table" then
      for _, entry in ipairs(cmd) do
        if type(entry) == "string" then out[entry] = name end
      end
    end
  end
  return out
end

--- Best-effort answer to "who registered this command", for the live
--- commands that have no cheatsheet. Not a verdict and never a filter —
--- the section stays complete either way; this only lets a reader see at a
--- glance that a run of lines is somebody else's plugin.
---
--- Three sources, in descending order of how directly they know:
---   1. lazy.nvim's `cmd` spec, for lazy-load stubs (see `lazy_cmd_owners`).
---   2. the callback's defining file, via `debug.getinfo` — reliable for a
---      plugin that registers its own commands directly.
---   3. the `script_id`, for anything defined in Vimscript, where there is
---      no callback to inspect.
---
--- One case stays unresolved and is labelled as such rather than guessed
--- at: commands registered through lib.nvim's usercmd helpers all report
--- that shared registrar as their origin (64 of them here), and lib.nvim
--- keeps no owner alongside them — `composer.registry()` hands out handles
--- with `check`/`document`/`name`/`spec` and no source. Recovering those
--- would mean lib.nvim recording its caller at registration time, which is
--- a change in that repository, not something to fake from this side.
---@param name string
---@param lazy_owners table<string, string>
---@param defs table  # `nvim_get_commands({})`, passed in: rebuilding it per
---                     name would mean one full command-table build per
---                     finding, 156 of them in a real run
---@return string
local function command_owner(name, lazy_owners, defs)
  if lazy_owners[name] then return lazy_owners[name] .. " (lazy cmd stub)" end

  local def = defs[name]
  if def and type(def.callback) == "function" then
    local info = debug.getinfo(def.callback, "S")
    local src = ((info and info.short_src) or ""):gsub("\\", "/")
    local lib = src:match("/lib%.nvim/") or src:match("^%a:/repos/lib%.nvim")
    if lib then return "via lib.nvim usercmd helpers — owner not recorded" end
    local plugin = src:match("/lazy/([^/]+)/") or src:match("^%a:/repos/([^/]+)")
    if plugin then return plugin end
    local runtime = src:match("/runtime/(.+)$") or src:match("^vim/(.+)$")
    if runtime then return "neovim runtime: " .. runtime end
    if src ~= "" then return src end
  end
  if def and def.script_id then return ("vimscript script_id=%d"):format(def.script_id) end
  return "unknown"
end

--- Global keymaps PLUS the buffer-local keymaps of every buffer that
--- happens to be loaded right now.
---
--- The buffer-local half directly attacks the module doc's limitation 3.
--- `nvim_get_keymap` is global-only, so a plugin that registers its
--- bindings on its own window's buffer (filetree.nvim via
--- `tree_attach.on_attach`, every picker-style float, ...) had *all* of its
--- documented keys reported as missing. Scanning loaded buffers recovers
--- exactly those whose window is open while the report runs — an honest
--- partial fix, not a complete one: nothing here can conjure a filetree
--- buffer that was never opened this session. What the remaining, still
--- unverifiable ones are worth is decided in `M.check`, not here.
--- Every live lhs maps to the list of `desc`s registered under it, not to a
--- bare `true`: `is_live` below needs them to tell a documented binding
--- apart from an unrelated one that merely shares the key.
---@param modes string[]
---@return table<string, table<string, string[]>> mode -> lhsraw -> descs
local function live_keymaps(modes)
  local out = {}
  local bufs = vim.api.nvim_list_bufs()
  for _, mode in ipairs(modes) do
    local set = {}
    local function add(maps)
      for _, m in ipairs(maps) do
        if m.lhsraw then
          set[m.lhsraw] = set[m.lhsraw] or {}
          table.insert(set[m.lhsraw], m.desc or "")
        end
      end
    end
    local ok, maps = pcall(vim.api.nvim_get_keymap, mode)
    if ok then add(maps) end
    for _, buf in ipairs(bufs) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local ok_buf, buf_maps = pcall(vim.api.nvim_buf_get_keymap, buf, mode)
        if ok_buf then add(buf_maps) end
      end
    end
    out[mode] = set
  end
  return out
end

--- Whether a documented binding is actually registered.
---
--- Matching on lhs alone was wrong in a way that mattered: an unrelated
--- global map satisfies a documented row just by sharing the key. Confirmed
--- across the corpus — github_stats' `<CR>`/`<Esc>` were "live" because
--- this config binds `<CR>` to "Insert blank line" and `<Esc>` to "Clear
--- copilot NES overlays or nohl"; `language.nvim`'s `]s` matched Snacks'
--- "Snacks Scope: Next"; reposcope's `<Esc>` matched the same nohl map
--- twice. Five rows, none of them the binding the cheatsheet describes, and
--- each one was enough to keep its whole table out of the "not verifiable"
--- verdict — which is why `github_stats.nvim.md` kept reporting ~20 keys
--- even after being split into per-scope tables.
---
--- So when BOTH sides name a desc, they must agree. Everything else falls
--- back to lhs-only, which is all the older behaviour ever was:
---   - the row has no `desc` column, or fills it with `none`/`-`
---   - nothing registered under that key carries a desc at all
---
--- Compared exactly (after `strip_quotes`), deliberately. Measured over
--- every currently-live documented row: 8 exact matches, 0 that needed
--- case-insensitive comparison, 0 where the live side had no desc, and 5
--- mismatches — all five genuine. There was nothing for a looser rule to
--- rescue, and a substring or fuzzy compare would only start re-admitting
--- the collisions this exists to catch.
---@param live_maps table<string, table<string, string[]>>
---@param modes string[]
---@param lhs string
---@param doc_desc string|nil
---@return boolean
local function is_live(live_maps, modes, lhs, doc_desc)
  for _, mode in ipairs(modes) do
    local descs = live_maps[mode] and live_maps[mode][lhs]
    if descs then
      if not doc_desc then return true end
      local any_desc = false
      for _, d in ipairs(descs) do
        if d ~= "" then
          any_desc = true
          if strip_quotes(d) == doc_desc then return true end
        end
      end
      if not any_desc then return true end
    end
  end
  -- Either the key is registered nowhere, or every desc under it names a
  -- different binding. Both are "documented, not registered".
  return false
end

---@class Bindings.DriftFinding
---@field kind "keymap-not-live"|"usercmd-not-live"|"usercmd-undocumented"
---@field plugin string|nil
---@field heading string|nil  # the record's table heading, keymap axis only
---@field group string|nil    # plugin + heading, the verdict's grouping key
---@field notation string
---@field file string|nil
---@field line integer|nil
---@field unverifiable boolean|nil  # see `M.check`'s per-table verdict

--- @param plugin string|nil narrow to one plugin's own files
---   (`records.lua`'s `plugin` field, i.e. the filename stem). With a
---   plugin given, the usercmd-undocumented direction is skipped — there
---   is no reliable way to attribute a live, undocumented command to one
---   specific plugin, and the per-plugin `unverifiable` verdict below is
---   not applied — asking about one plugin explicitly is a request to see
---   its findings, not to have them summarized away.
--- @return Bindings.DriftFinding[]
--- @return string[] skipped_plugins plugin names excluded because they
---   aren't loaded in this session (module doc point 4), sorted, deduped
function M.check(plugin)
  local findings = {}
  local skipped = {}

  -- Keymaps: documented (Personal) but not live.
  local checkable, needed_modes = {}, {}
  for _, rec in ipairs(records.list("Keymaps", "personal")) do
    if (not plugin or rec.plugin == plugin) and is_plugin_loaded(rec.plugin) then
      local lhs = extract_lhs(rec)
      if lhs then
        local modes = extract_modes(rec)
        for _, m in ipairs(modes) do
          needed_modes[m] = true
        end
        checkable[#checkable + 1] = { rec = rec, lhs = lhs, modes = modes, desc = extract_desc(rec) }
      end
    elseif not plugin or rec.plugin == plugin then
      skipped[rec.plugin] = true
    end
  end
  local mode_list = vim.tbl_keys(needed_modes)
  local live_maps = live_keymaps(mode_list)

  -- Tallies for the verdict below, keyed per *table* — plugin plus the
  -- heading above it — not per plugin.
  --
  -- Per plugin was tried first and does not work: these plugins document
  -- one or two global `<leader>` entry points alongside a dozen in-window
  -- keys, so "not one key of this plugin is live" is never true and the
  -- verdict would never fire. The table is the right unit, and not by
  -- accident — `BINDINGS-FORMAT.md` §1 makes a heading above every table
  -- mandatory precisely so a parser has "das Scope-Label, das der Scraper
  -- pro Zeile braucht". Empirically the corpus honours that: the groups
  -- this fires on carry headings like "Prompt-field keymaps
  -- (`M.set_prompt_keymaps`, buffer-local to every prompt buffer)" and
  -- "Component-local". Grouping is on the heading itself rather than on
  -- keywords inside it — the free text says the same thing, but matching
  -- on "buffer-local" would be a guess about phrasing, while "not one key
  -- in this whole table is live" is a fact about the data.
  local checked_count, found_count = {}, {}
  local keymap_findings = {}

  ---@param rec Bindings.Record
  ---@return string
  local function group_of(rec)
    return rec.plugin .. "\0" .. (rec.heading or "")
  end

  for _, entry in ipairs(checkable) do
    local group = group_of(entry.rec)
    checked_count[group] = (checked_count[group] or 0) + 1
    if is_live(live_maps, entry.modes, entry.lhs, entry.desc) then
      found_count[group] = (found_count[group] or 0) + 1
    else
      keymap_findings[#keymap_findings + 1] = {
        kind = "keymap-not-live",
        plugin = entry.rec.plugin,
        heading = entry.rec.heading,
        group = group,
        notation = entry.lhs,
        file = entry.rec.file,
        line = entry.rec.line,
      }
    end
  end

  -- Per-table verdict: "missing" versus "not verifiable from here".
  --
  -- `live_keymaps` now also reads buffer-local maps, so a UI that happens
  -- to be open is checked properly. What is left is the case the module
  -- doc's limitation 3 describes: a documented table where NOT ONE of its
  -- keys is live in any mode, global or buffer-local. Claiming N
  -- independent regressions there is a claim the data does not support —
  -- the one explanation consistent with every row at once is that this
  -- table describes a scope that is not open right now, which is not drift.
  -- A table where *some* keys are live is the opposite case: registration
  -- demonstrably happened, so the ones that did not show up are real
  -- candidates and stay in the main section.
  --
  -- The `> 1` guard keeps a one-row table out of it: a single absent key is
  -- no evidence about scope, and is exactly the shape a real regression has.
  --
  -- Deliberately a verdict about *reportability*, not a filter: these
  -- findings are still returned, still counted, and `M.describe` renders
  -- them under their own header. Nothing is dropped, and a plugin asked
  -- about by name (see the `plugin` param doc) is never summarized at all.
  for _, f in ipairs(keymap_findings) do
    if not plugin and (found_count[f.group] or 0) == 0 and (checked_count[f.group] or 0) > 1 then
      f.unverifiable = true
    end
    findings[#findings + 1] = f
  end

  -- Usercmds: documented (Personal) but not live.
  local live_cmds = live_commands()
  local seen_personal = {}
  for _, rec in ipairs(records.list("Usercmds", "personal")) do
    if (not plugin or rec.plugin == plugin) and is_plugin_loaded(rec.plugin) then
      local name = extract_usercmd(rec)
      if name and not seen_personal[name] then
        seen_personal[name] = true
        if not live_cmds[name] then
          findings[#findings + 1] = {
            kind = "usercmd-not-live",
            plugin = rec.plugin,
            notation = ":" .. name,
            file = rec.file,
            line = rec.line,
          }
        end
      end
    elseif not plugin or rec.plugin == plugin then
      skipped[rec.plugin] = true
    end
  end

  -- Third axis (source) is resolved BEFORE the live-undocumented direction
  -- below, which consults it to avoid reporting the same command twice —
  -- see there.
  local source_findings, source_reason
  if plugin then
    source_reason =
      "not attributable to a single plugin — run :Bindings check without an argument"
  else
    source_findings, source_reason = M.source_check(nil)
  end

  -- Usercmds: live but undocumented anywhere (Personal or Extern) — only
  -- meaningful unscoped, see the `plugin` param doc above.
  if not plugin then
    local documented_anywhere = {}
    for _, rec in ipairs(records.list("Usercmds")) do
      local name = extract_usercmd(rec)
      if name then documented_anywhere[name] = true end
    end

    -- A command this config's own source registers, live and undocumented,
    -- is one fact, and the source axis already reported it — with a
    -- file:line this direction cannot produce. Reporting it here as well
    -- was pure duplication (42 of the 198 findings in a real run). The
    -- source axis wins; this direction keeps only what it alone can see.
    local reported_by_source = {}
    for _, f in ipairs(source_findings or {}) do
      if f.kind == "usercmd-undocumented-source" then
        reported_by_source[f.notation:sub(2)] = true
      end
    end

    local lazy_owners = lazy_cmd_owners()
    local command_defs = vim.api.nvim_get_commands({})
    local names = vim.tbl_keys(live_cmds)
    table.sort(names)
    for _, name in ipairs(names) do
      if not documented_anywhere[name] and not reported_by_source[name] then
        findings[#findings + 1] = {
          kind = "usercmd-undocumented",
          plugin = nil,
          notation = ":" .. name,
          owner = command_owner(name, lazy_owners, command_defs),
        }
      end
    end
  end

  -- Third axis (source): registered in THIS repository's own Lua, but not
  -- documented anywhere. This is the direction limitation 1 above rules out
  -- for the *live* axis, and the reason it is answerable here: the source
  -- axis contains only our own registrations, never vim's defaults or a
  -- plugin's own bindings, so it cannot flood.
  --
  -- Best-effort by design: the artifact may be absent or stale, and that is
  -- reported as a reason (second return value of `M.source_check`) rather
  -- than silently yielding no findings.
  --
  -- Skipped entirely when scoped to one plugin, for the same reason the
  -- usercmd-undocumented direction above is: the axis cannot be attributed
  -- to a cheatsheet stem. `M.source_check` only ever *labelled* its
  -- findings with the given plugin, it never filtered by it, so a scoped
  -- run used to return the whole config's source axis alongside the one
  -- plugin's own findings — 218 findings for `:Bindings check
  -- reposcope.nvim` where 24 were about reposcope. Skipping is the honest
  -- half of the fix; the reason line says so rather than leaving a silently
  -- absent axis.
  --
  -- Resolved further up, before the live-undocumented direction that
  -- dedupes against it; only the folding-in happens here.
  if source_findings then vim.list_extend(findings, source_findings) end

  local skipped_list = vim.tbl_keys(skipped)
  table.sort(skipped_list)
  return findings, skipped_list, source_reason
end

---The source axis on its own — `M.check` folds this in, exposed separately
---so a caller can ask only "what is registered but undocumented" without
---paying for the live probes.
---
---**Only ever reports the source -> documented direction.** The reverse
---("documented but not in the source") is deliberately absent: a documented
---binding legitimately lives in a plugin's own repository rather than this
---config, and the existing `keymap-not-live` check already covers the case
---where a documented binding is genuinely gone.
---@param plugin string|nil Label only — stamped onto every finding's
---`plugin` field. This axis is NOT filterable by cheatsheet stem (a source
---entry knows its module path, not which cheatsheet ought to cover it),
---which is why `M.check` skips the axis outright when scoped rather than
---passing a value through here.
---@return Bindings.DriftFinding[]
---@return string|nil reason  # why the source axis could not be consulted
function M.source_check(plugin)
  local ok_src, source = pcall(require, "bindings.usrcmds.bindings_explorer.source")
  if not ok_src then
    return {}, "source axis unavailable (bindings_explorer.source missing)"
  end

  local entries, reason = source.load()
  if not entries then
    return {}, reason
  end

  -- Documented across BOTH corpora here, unlike the keymap check above: the
  -- question is "is this registration written down anywhere at all", and a
  -- binding this config registers on a plugin's behalf may well be
  -- documented on that plugin's own sheet.
  local documented_keys, documented_cmds = {}, {}
  for _, rec in ipairs(records.list("Keymaps")) do
    local lhs = extract_lhs(rec)
    if lhs then documented_keys[lhs] = true end
  end
  for _, rec in ipairs(records.list("Usercmds")) do
    local name = extract_usercmd(rec)
    if name then documented_cmds[name] = true end
  end

  local out = {}
  local seen = {}
  for _, e in ipairs(entries) do
    if e.kind == "keymap" and e.lhs then
      -- Compared through the SAME normalization the documented side goes
      -- through (`nvim_replace_termcodes`), or `<leader>x` on one side and
      -- its resolved form on the other would never match.
      local raw = normalize_lhs(e.lhs)
      if raw and not documented_keys[raw] and not seen["k" .. raw] then
        seen["k" .. raw] = true
        out[#out + 1] = {
          kind = "keymap-undocumented",
          plugin = plugin,
          notation = e.lhs,
          file = e.path,
          line = e.line,
        }
      end
    elseif e.kind == "usercmd" and e.name then
      if not documented_cmds[e.name] and not seen["c" .. e.name] then
        seen["c" .. e.name] = true
        out[#out + 1] = {
          kind = "usercmd-undocumented-source",
          plugin = plugin,
          notation = ":" .. e.name,
          file = e.path,
          line = e.line,
        }
      end
    end
  end

  table.sort(out, function(a, b)
    return a.notation < b.notation
  end)
  return out, nil
end

--- A finding's `notation` back in readable key notation, for display only.
---
--- `keymap-not-live` findings carry the RAW byte string `normalize_lhs`
--- produced (that is the whole point — it is what `.lhsraw` is compared
--- against), and for anything with a modifier that string is neither
--- readable nor valid UTF-8: `<M-->` is stored as
--- `K_SPECIAL KS_MODIFIER 0x08 -`, i.e. the bytes `\128\252\8-`. Rendering
--- that verbatim was a real bug with two effects — the report showed
--- `<80><fc>^H-` instead of `<M-->`, and, worse, the invalid UTF-8 made the
--- whole buffer uncopyable: `win32yank.exe -i` (this config's clipboard
--- provider on Windows, see `options.lua`) panics with "stream did not
--- contain valid UTF-8" and aborts the ENTIRE write, so a single such
--- finding silently broke `y`/`<C-c>` over the report. Verified against
--- both the real report buffer and win32yank standalone (exit 101).
---
--- `keytrans()` is the exact inverse of the `nvim_replace_termcodes` call
--- in `normalize_lhs`, and is an identity on plain printable text, so it is
--- safe to apply to the source axis's notations too (those are already
--- written as `<leader>x`, never raw). Guarded with `pcall` regardless —
--- display must never take the report down.
---@param notation string
---@return string
local function readable(notation)
  local ok, out = pcall(vim.fn.keytrans, notation)
  if ok and type(out) == "string" and out ~= "" then return out end
  return notation
end

--- One rendered line per finding, without any section context.
---@param f Bindings.DriftFinding
---@return string
local function render(f)
  if f.kind == "keymap-not-live" then
    return ("  %-22s %-20s %s:%d"):format(f.plugin, readable(f.notation), f.file, f.line)
  elseif f.kind == "usercmd-not-live" then
    return ("  %-22s %-20s %s:%d"):format(f.plugin, f.notation, f.file, f.line)
  elseif f.kind == "keymap-undocumented" then
    return ("  %-20s %s:%d"):format(readable(f.notation), f.file or "?", f.line or 0)
  elseif f.kind == "usercmd-undocumented-source" then
    return ("  %-20s %s:%d"):format(f.notation, f.file or "?", f.line or 0)
  end
  return ("  %-28s %s"):format(f.notation, f.owner or "unknown")
end

--- The sections, in descending order of how much a finding in them is
--- worth acting on, each with the `kind`s it collects and a subtitle
--- naming its known noise. Order matters: a 600-line report is only usable
--- if the first screen is the part worth reading.
local SECTIONS = {
  {
    kinds = { ["usercmd-not-live"] = true },
    title = "Usercmds — documented, not registered",
    note = "highest-signal axis; a documented-lazy command may need its feature exercised first",
  },
  {
    kinds = { ["keymap-not-live"] = true },
    title = "Keymaps — documented, not registered",
    -- Accurate for a scoped run too, where the per-table verdict does not
    -- run at all and this section holds every keymap finding.
    note = "not found globally, nor in any buffer open right now",
  },
  {
    kinds = { ["keymap-undocumented"] = true, ["usercmd-undocumented-source"] = true },
    title = "Registered in this config's source, not documented",
    note = "from docs/map/module_map.json — only as fresh as the last :DocMap",
  },
  {
    kinds = { ["usercmd-undocumented"] = true },
    title = "Live commands with no cheatsheet, by origin",
    note = "mostly third-party infra this corpus never covered; grouped so it can be skimmed",
    -- Sorted by owner, not by name: this section is read to find out
    -- whether anything in it is *yours*, and clustering a plugin's dozen
    -- commands onto adjacent lines answers that in one glance.
    sort = function(a, b)
      local oa, ob = a.owner or "", b.owner or ""
      if oa ~= ob then return oa < ob end
      return a.notation < b.notation
    end,
  },
}

---@param findings Bindings.DriftFinding[]
---@param skipped string[]|nil `M.check`'s second return value
---@param source_reason string|nil `M.check`'s third return value — why the
---source axis could not be consulted, when it could not. Rendered rather
---than dropped: a report silently missing a whole axis reads exactly like
---one where that axis found nothing.
---@return string[]
function M.describe(findings, skipped, source_reason)
  local lines = {}
  if #findings == 0 then
    lines[1] = "No drift found (Keymaps: documented-not-live + source-not-documented; "
      .. "Usercmds: both directions)."
  else
    -- The unverifiable keymap findings (see `M.check`'s verdict) are pulled
    -- out first: they are reported per plugin, not per key, so they never
    -- reach the per-kind sections below.
    local unverifiable, order, rest = {}, {}, {}
    for _, f in ipairs(findings) do
      if f.unverifiable then
        local bucket = unverifiable[f.group]
        if not bucket then
          bucket = { n = 0, plugin = f.plugin, heading = f.heading, file = f.file, line = f.line }
          unverifiable[f.group] = bucket
          order[#order + 1] = f.group
        end
        bucket.n = bucket.n + 1
      else
        rest[#rest + 1] = f
      end
    end

    for _, section in ipairs(SECTIONS) do
      local matched = {}
      for _, f in ipairs(rest) do
        if section.kinds[f.kind] then matched[#matched + 1] = f end
      end
      if section.sort then table.sort(matched, section.sort) end
      local hits = {}
      for _, f in ipairs(matched) do
        hits[#hits + 1] = render(f)
      end
      if #hits > 0 then
        if #lines > 0 then lines[#lines + 1] = "" end
        lines[#lines + 1] = ("%s (%d)"):format(section.title, #hits)
        lines[#lines + 1] = ("  -- %s"):format(section.note)
        vim.list_extend(lines, hits)
      end
    end

    table.sort(order)
    if #order > 0 then
      local total = 0
      for _, key in ipairs(order) do
        total = total + unverifiable[key].n
      end
      if #lines > 0 then lines[#lines + 1] = "" end
      lines[#lines + 1] =
        ("Keymaps — not verifiable from here (%d in %d tables)"):format(total, #order)
      lines[#lines + 1] = "  -- not one key of these tables is live, globally or in any open buffer:"
      lines[#lines + 1] = "  -- a buffer-local scope whose UI is not open right now, not drift."
      lines[#lines + 1] = "  -- Open it and re-run, or :Bindings check <plugin> to list them in full."
      for _, key in ipairs(order) do
        local b = unverifiable[key]
        lines[#lines + 1] = ("  %-22s %2d keys   %s   %s:%d"):format(
          b.plugin,
          b.n,
          b.heading and ("## " .. b.heading) or "(table without heading)",
          b.file or "?",
          b.line or 0
        )
      end
    end
  end
  if source_reason then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Source axis not consulted: " .. source_reason
  end
  if skipped and #skipped > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Not loaded this session, skipped (%d): %s"):format(#skipped, table.concat(skipped, ", "))
  end
  return lines
end

return M
