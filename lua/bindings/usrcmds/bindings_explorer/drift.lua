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
--- 3. **Buffer-local / filetype-scoped keymaps are a known false-positive
---    source.** `nvim_get_keymap` only sees GLOBAL maps. A documented
---    `<leader>im` that's actually registered per-filetype
---    (`keymaps.filetypes = {"markdown",...}`) reports as
---    "documented-not-live" even though it IS correctly registered —
---    there's no live buffer of every relevant filetype to check against
---    from a single report call.
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

---@param modes string[]
---@return table<string, table<string, boolean>> mode -> set of live lhsraw
local function live_keymaps(modes)
  local out = {}
  for _, mode in ipairs(modes) do
    local set = {}
    local ok, maps = pcall(vim.api.nvim_get_keymap, mode)
    if ok then
      for _, m in ipairs(maps) do
        if m.lhsraw then set[m.lhsraw] = true end
      end
    end
    out[mode] = set
  end
  return out
end

---@class Bindings.DriftFinding
---@field kind "keymap-not-live"|"usercmd-not-live"|"usercmd-undocumented"
---@field plugin string|nil
---@field notation string
---@field file string|nil
---@field line integer|nil

--- @param plugin string|nil narrow to one plugin's own files
---   (`records.lua`'s `plugin` field, i.e. the filename stem). With a
---   plugin given, the usercmd-undocumented direction is skipped — there
---   is no reliable way to attribute a live, undocumented command to one
---   specific plugin.
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
        checkable[#checkable + 1] = { rec = rec, lhs = lhs, modes = modes }
      end
    elseif not plugin or rec.plugin == plugin then
      skipped[rec.plugin] = true
    end
  end
  local mode_list = vim.tbl_keys(needed_modes)
  local live_maps = live_keymaps(mode_list)

  for _, entry in ipairs(checkable) do
    local live_anywhere = false
    for _, m in ipairs(entry.modes) do
      if live_maps[m] and live_maps[m][entry.lhs] then
        live_anywhere = true
        break
      end
    end
    if not live_anywhere then
      findings[#findings + 1] = {
        kind = "keymap-not-live",
        plugin = entry.rec.plugin,
        notation = entry.lhs,
        file = entry.rec.file,
        line = entry.rec.line,
      }
    end
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

  -- Usercmds: live but undocumented anywhere (Personal or Extern) — only
  -- meaningful unscoped, see the `plugin` param doc above.
  if not plugin then
    local documented_anywhere = {}
    for _, rec in ipairs(records.list("Usercmds")) do
      local name = extract_usercmd(rec)
      if name then documented_anywhere[name] = true end
    end

    local names = vim.tbl_keys(live_cmds)
    table.sort(names)
    for _, name in ipairs(names) do
      if not documented_anywhere[name] then
        findings[#findings + 1] = { kind = "usercmd-undocumented", plugin = nil, notation = ":" .. name }
      end
    end
  end

  local skipped_list = vim.tbl_keys(skipped)
  table.sort(skipped_list)
  return findings, skipped_list
end

---@param findings Bindings.DriftFinding[]
---@param skipped string[]|nil `M.check`'s second return value
---@return string[]
function M.describe(findings, skipped)
  local lines = {}
  if #findings == 0 then
    lines[1] = "No drift found (Keymaps: documented-not-live only; Usercmds: both directions)."
  else
    for _, f in ipairs(findings) do
      if f.kind == "keymap-not-live" then
        lines[#lines + 1] = ("[keymap missing]  %-20s %-20s %s:%d"):format(f.plugin, f.notation, f.file, f.line)
      elseif f.kind == "usercmd-not-live" then
        lines[#lines + 1] = ("[usercmd missing] %-20s %-20s %s:%d"):format(f.plugin, f.notation, f.file, f.line)
      else
        lines[#lines + 1] = ("[undocumented]    %s"):format(f.notation)
      end
    end
  end
  if skipped and #skipped > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Not loaded this session, skipped (%d): %s"):format(#skipped, table.concat(skipped, ", "))
  end
  return lines
end

return M
