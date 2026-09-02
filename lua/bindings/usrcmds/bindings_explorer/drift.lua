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
--- 0. **All three categories are checked** since 2026-09-02. Keymaps and
---    Usercmds were the original two; `Autocmds/` was read for command names
---    and never compared against anything, so 241 documented rows sat outside
---    every number this module printed. What closed it is described at
---    `live_autocmds` — including why the reverse direction is answerable
---    there when limitation 1 rules it out for keymaps, and how the corpus'
---    call-site counting is reconciled with `nvim_get_autocmds`' per-event
---    counting without the two ever being compared.
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
--- 6. **Two false-positive classes were removed on 2026-08-30**, both of
---    them silent: a row the scraper could not read yielded no lhs and was
---    dropped from every axis without a word. See `LHS_HEADERS` (the header
---    allow-list was English-only against a bilingual corpus -- 601 rows
---    invisible) and `key_forms` (the live and documented sides encode a
---    modifier chord differently, so every documented Ctrl key read as
---    missing). Measured on this config, both fixes plus the two
---    `nvim-config` cheatsheets they made writable: 150 source-axis findings
---    became 0, and the whole report went from 680 findings to 260.
---
--- Usercmds are checked BOTH directions, since `nvim_get_commands({})`
--- only ever returns user-defined commands (no vim-default flood): the
--- live-undocumented direction is cross-checked against Personal AND
--- Extern documented commands, to avoid flagging things documented
--- elsewhere — but plugin-manager/infra commands (`:Lazy`, `:Mason`, ...)
--- with no cheatsheet at all will still show up; no ignore-list is
--- maintained for those.
---
--- **The repo axis (opt-in, `opts.repo`).** Point 4 above is honest but
--- empty: a skipped plugin is not a checked plugin, and in a normal session
--- most personal plugins are skipped, so most of the corpus is judged by
--- nothing at all. The one thing available for those is the plugin's own
--- local checkout, which is on disk whether or not lazy.nvim loaded it —
--- so `opts.repo` searches it for the documented lhs / command name as a
--- quoted string literal (`repo.lua`), and reports what is written down
--- nowhere. Three properties, all deliberate:
---
---   - **Off by default.** The existing axes probe an already-running
---     session and cost nothing worth mentioning; reading ~20 checkouts off
---     disk is not in that class, and should never be a silent cost of a
---     command someone ran to see the usual report.
---   - **A grep, not an API query, and ranked accordingly.** A computed lhs
---     (`prefix .. "v"`, a key read out of a user config) is registered and
---     ungreppable, so the axis produces false findings that the live axis
---     never would. `M.describe` says so on the section itself.
---   - **Three suppressors, so what survives is worth reading**: the
---     literal is absent from the plugin's checkout AND absent from this
---     config's own `lua/` tree (a personal plugin's `<leader>` entry point
---     is very often registered here, in a lazy `keys` spec, not over
---     there) AND not live right now (`is_live`, desc-matched like
---     everywhere else). Only then is it reported.
---
--- A plugin the repo axis actually answered for is no longer counted as
--- "skipped" — it was checked, just by a weaker instrument, and saying
--- otherwise would understate the report in one direction while
--- overstating the axis in the other. One with no resolvable checkout, or
--- whose checkout yielded no readable source, stays skipped.
---
--- **The repo fallback (always on, 2026-09-02).** The axis above answers for
--- plugins that never loaded. The fallback answers a different question, for
--- plugins that DID load: a documented key the live probe cannot find is
--- looked for in the plugin's own source before it becomes a finding. Same
--- primitive, same two trees, opposite default — and the reason for the
--- opposite default is the measurement:
---
--- ```
--- :Bindings check          keymap-not-live   52 -> 1     (51 confirmed by source)
--- :Bindings check extern   keymap-not-live  309 -> 84   (225 confirmed by source)
--- ```
---
--- The one survivor in the default scope is `cmdlog.nvim`'s `ctrl-f`, which
--- is written in fzf-lua notation where the corpus otherwise uses vim's —
--- a real defect, and the only one. **One finding in 52.** A section that is
--- 98% noise is a section nobody reads, and the axis that removes the noise
--- costs a grep.
---
--- The `extern` scope profits from the same fallback for a different reason:
--- a third-party cheatsheet's stem had no local checkout, so the tree that
--- answered there was this config's own `lua/` — which is exactly where
--- those keys are bound, in a lazy `keys` spec. Hence the note in `SECTIONS`
--- says "any source that could be read" rather than naming the plugin's.
--- Since `stem_plugin` resolves the extern stems too, that half now has the
--- plugin's own tree available as well.
---
--- **The fallback runs on the usercmd axis too (2026-09-02).** It always
--- should have — it is the same question about the same two trees — and the
--- asymmetry was an omission, not a decision. One difference, and it is
--- deliberate: the usercmd side is case-SENSITIVE, because folding case
--- makes `:Images` match the word "images" in half of images.nvim's own
--- source, and every command would then count as written down. The opt-in
--- axis below already draws that line, for the same reason.
---
--- What it cannot answer is structural rather than a gap to close:
--- `repo.mentions` matches quoted literals, and a Vimscript
--- `com! -bang UnicodeDownload …` is unquoted. `:UnicodeDownload` and
--- `:DigraphNew` therefore stay reported however loaded their plugin is.
---
--- Why not the obvious alternative — dropping buffer-local keys from the
--- live axis wholesale? Because `keymap-not-live` is not a collision check:
--- it never compares buffer-local against global, it only asks whether a
--- documented key exists. Excusing a whole class from that question means a
--- buffer-local key its plugin has since renamed would never be noticed
--- again. The fallback keeps the question and answers it better.
---
--- Cost, measured on this config: `check` is ~150 ms without the fallback
--- and ~550 ms with it, because a checkout is only indexed once a key of
--- that plugin actually came up missing. Paid deliberately, for a report
--- whose keymap section is worth reading.
---
--- The two are still separate switches. `opts.repo` indexes the checkout of
--- every unloaded plugin, twenty-odd trees whether or not anything is wrong
--- with them; the fallback touches a checkout only after a key came up
--- missing. That is why one is opt-in and the other is not.

local records = require("bindings.usrcmds.bindings_explorer.records")
local config = require("bindings.usrcmds.bindings_explorer.config")
local repo = require("bindings.usrcmds.bindings_explorer.repo")

local M = {}

--- Header names (after `normalize_header`) that mark a Keymaps column as
--- the lhs/mode — see the module doc on how inconsistent real column
--- naming turned out to be across the 137-file corpus (checked
--- empirically before writing this list).
---
--- **The corpus is bilingual and this list was not** (fixed 2026-08-30).
--- `ExternPlugins/Bindings/*` is written in German throughout, so its key
--- column is spelled `Taste`, `Mapping`, `Taste(n)` or `Taste (in LazyGit)`,
--- never `lhs`/`key`. A row whose header matches nothing here yields no lhs
--- at all, and both axes then drop it without saying so: the source axis
--- reported `<leader>gb` as undocumented while it sat in `Snacks.md`'s Git
--- table, and the live axis never checked those rows in either direction.
--- 601 rows of the corpus were invisible this way -- counted, not estimated.
---
--- Four German-corpus headers are deliberately NOT added, because their
--- cells are not keys and admitting them would let unrelated text
--- "document" a binding:
---   - `Eintrag` (`Menu.md`) -- nvzone/menu entry labels ("Format Buffer").
---   - `Tab` (`Search.md`) -- search.nvim tab names ("All Files").
---   - `Modul` (`Snacks.md`) -- module names (`snacks.picker`).
---   - `Vorschlag (README)` (`Gitsigns.md`) -- keys upstream's README
---     *suggests* and this config did not bind. Counting those as
---     documented would suppress a real finding for a key bound elsewhere.
--- `` `lhs` key `` (fileops.nvim.md) and `` `keymaps.<name>` ``
--- (diff.nvim.md) name a config KEY (`delete_force`), not a keystroke, and
--- stay excluded for the same reason -- `normalize_lhs`'s `_`/`.` guard
--- would reject their cells anyway.
local LHS_HEADERS = {
  lhs = true,
  key = true,
  keys = true,
  ["action key"] = true,
  -- German corpus. Every one checked against its actual cells first.
  mapping = true,
  taste = true,
  -- `Telescope.md`'s in-picker table, whose cells read `` `<A-c>` / `c` ``;
  -- `first_token` takes the first backticked group, i.e. the insert-mode key.
  ["insert/normal"] = true,
  -- `pickers.nvim.md`'s cross-picker table (`Action | Default | telescope |
  -- fzf-lua | snacks`), whose `Default` column holds `<C-Left>` and friends.
  default = true,
}
local MODE_HEADERS = { mode = true, modes = true, modus = true, modi = true }
local USERCMD_HEADERS = {
  command = true,
  invocation = true,
  subcommand = true,
  -- `Dap.md`/`Harpoon.md`/`NvChadUI.md`/`Treesitter.md` head their verb
  -- tables `Aufruf`; `lsp.nvim.md`/`Harpoon.md` list the flat shorthand for
  -- a verb route under `Alias`.
  aufruf = true,
  alias = true,
}
local DESC_HEADERS = { desc = true, description = true }

--- Autocmds columns. `normalize_header` lowercases and strips a trailing
--- parenthesis group, so `Augroup (clear=true)` and `Event(s)` arrive here as
--- `augroup` and `event` -- the corpus spells both a dozen ways across its 33
--- Autocmds sheets and every spelling below was read off a real header row.
local AUGROUP_HEADERS = {
  augroup = true,
  ["augroup name"] = true,
  group = true,
  gruppe = true,
}

--- Two event-ish headers are deliberately absent. `Neo-tree-Event`
--- (`NeoTree.md`) names neo-tree's own callback events, which no augroup ever
--- registers; `Trigger` (`buffer-ctx.md`'s module summary) names what causes a
--- module to load. Admitting either would let unrelated text claim an autocmd.
local EVENT_HEADERS = { event = true, events = true, ereignis = true }

--- Cells that fill a `desc` column without naming a description. Checked
--- lowercased, after `strip_quotes`.
local EMPTY_DESC = { [""] = true, none = true, ["-"] = true, ["—"] = true, ["n/a"] = true }

local VALID_MODE_CHARS =
  { n = true, i = true, v = true, x = true, s = true, o = true, t = true, c = true, l = true }

---@param h string
---@return string
local function normalize_header(h)
  -- Backticks come off first: a column headed `` `lhs` key `` has to
  -- normalize the same way as `lhs key`, or the markup alone would decide
  -- whether the column is findable.
  h = vim.trim((h:lower():gsub("`", ""):gsub("%s*%b()", "")))
  -- `Default-Mapping (Plugin)` (`VisualMulti.md`) is the hyphenated spelling
  -- of `Default lhs` -- one character apart, same meaning, so one pattern.
  -- A bare `Default` keeps its name (nothing follows to strip) and is
  -- matched by `LHS_HEADERS` instead.
  h = h:gsub("^default[%s%-]+", ""):gsub("^config%s+", ""):gsub("^user%-chosen%s+", "")
  return h
end

---@param rec Bindings.Record
---@param headers table<string, boolean>
---@return integer|nil
local function column_index(rec, headers)
  for i, col in ipairs(rec.columns) do
    if headers[normalize_header(col)] then
      return i
    end
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
  if default_key then
    return vim.trim(default_key)
  end
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
  if doc_lhs == "" or doc_lhs:find("[%s/,._]") then
    return nil
  end
  local ok, raw = pcall(vim.api.nvim_replace_termcodes, doc_lhs, true, true, true)
  if not ok then
    return nil
  end
  return raw
end

---@param rec Bindings.Record
---@return string[]
local function extract_modes(rec)
  local idx = column_index(rec, MODE_HEADERS)
  if not idx or not rec.cells[idx] then
    return { "n" }
  end
  local out = {}
  for m in rec.cells[idx]:lower():gmatch("%a") do
    if VALID_MODE_CHARS[m] then
      out[#out + 1] = m
    end
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
  if not cell then
    return nil
  end
  local desc = strip_quotes(cell)
  if EMPTY_DESC[desc:lower()] then
    return nil
  end
  return desc
end

--- Whether a key cell says "there is no key here" rather than naming one.
---
--- Three spellings, all real and all previously reported as documented keys
--- that are not live:
---   - a bare dash of any kind (`Keymaps/lib.nvim.md`'s row for the
---     experimental re-run trigger, whose Option column reads
---     `setup({ experimental = false })` — the row documents the feature
---     being OFF),
---   - `*(unset)*` (`Keymaps/buffer-ctx.md`'s `clear`, which ships unbound),
---   - `*(your lhs)*` (the same file's row for a key the user supplies).
---
--- The `*(…)*` form generalizes: markdown emphasis around a parenthesis is
--- how this corpus writes a placeholder, and no key notation looks like that.
---@param cell string
---@return boolean
local function is_placeholder_key(cell)
  local s = vim.trim(cell:gsub("`", ""))
  if s == "" or s:match("^[%-–—]+$") then
    return true
  end
  return s:match("^%*+%(.*%)%*+$") ~= nil
end

--- The lhs of a row exactly as the cheatsheet writes it (`<leader>iv`),
--- before `normalize_lhs` turns it into the raw bytes the live axis needs.
--- The repo axis wants this form and not that one: a checkout's source
--- spells its keymaps the same way the cheatsheet does, in `<>` notation,
--- never in expanded termcodes.
---@param rec Bindings.Record
---@return string|nil
local function extract_lhs_token(rec)
  local idx = column_index(rec, LHS_HEADERS)
  local cell = idx and rec.cells[idx]
  if not cell or cell == "" or is_placeholder_key(cell) then
    return nil
  end
  return first_token(cell)
end

---@param rec Bindings.Record
---@return string|nil normalized lhs, nil if no usable lhs column/cell
local function extract_lhs(rec)
  local token = extract_lhs_token(rec)
  return token and normalize_lhs(token)
end

--- The augroup a row names, or nil when the row names none that can be
--- checked.
---
--- Three shapes are rejected rather than guessed at, all real:
---   * no augroup column at all -- eight sheets document events without one
---     (`| Event(s) | Condition | Action | desc |`). An event on its own is
---     not checkable: every plugin registers `BufEnter`.
---   * a placeholder (`—`, `*(none)*`), same guard the key column uses.
---   * a name built at runtime, spelled with a `<...>` slot --
---     `LspSignaturePopup_<winid>` is one augroup per window and matches no
---     literal.
---@param rec Bindings.Record
---@return string|nil
local function extract_augroup(rec)
  local idx = column_index(rec, AUGROUP_HEADERS)
  local cell = idx and rec.cells[idx]
  if not cell or cell == "" or is_placeholder_key(cell) then
    return nil
  end
  -- `**none** -- registered directly via `nvim_create_autocmd`, id tracked
  -- manually ...` is `Autocmds/reposcope.nvim.md`'s way of saying there is no
  -- augroup. `first_token` dutifully returns the first backticked group of
  -- that sentence, which is a function name, and the axis then reported a
  -- missing augroup called `nvim_create_autocmd`. A cell that OPENS with a
  -- none-word is answering "which augroup" with "there is none".
  local bare = vim.trim((cell:gsub("[%*_]", "")):lower())
  if bare:match("^none%f[%W]") or bare:match("^keine%f[%W]") then
    return nil
  end

  local token = first_token(cell)
  if token == "" or token:find("<") or token:find("%s") then
    return nil
  end
  return token
end

--- Every event name a row lists, validated against Neovim itself.
---
--- `vim.fn.exists("##" .. name)` is the authoritative answer and costs nothing
--- -- an allowlist of event names would be one more hand-kept mirror, and it
--- would go stale on the next Neovim release rather than on a corpus edit.
--- It also does the filtering this needs for free: the events cell often
--- carries prose beside the names (`User LspRootScopeChanged`, `BufWritePre`
--- *on save*), and only the real event names survive.
---@param rec Bindings.Record
---@return string[]
local function extract_events(rec)
  local idx = column_index(rec, EVENT_HEADERS)
  local cell = idx and rec.cells[idx]
  if not cell or cell == "" then
    return {}
  end
  local seen, out = {}, {}
  for word in cell:gmatch("[%a][%w_]*") do
    if not seen[word] and vim.fn.exists("##" .. word) == 1 then
      seen[word] = true
      out[#out + 1] = word
    end
  end
  return out
end

---@param rec Bindings.Record
---@return string|nil base command name, e.g. "Bindings" from "`:Bindings search`"
local function extract_usercmd(rec)
  local idx = column_index(rec, USERCMD_HEADERS)
  local cell = idx and rec.cells[idx]
  if cell then
    local name = records.command_names(cell)[1]
    if name then
      return name
    end
  end
  -- Header didn't match a known column, but the command notation might
  -- still be in one of the other cells (e.g. a table this scraper's
  -- header allow-list doesn't recognize).
  for _, c in ipairs(rec.cells) do
    local name = records.command_names(c)[1]
    if name then
      return name
    end
  end
  return nil
end

--- A plugin name reduced to what a cheatsheet stem and a repository name
--- have in common: case, the `nvim`/`vim` affixes everyone spells
--- differently, and the separators.
---
--- Deliberately not a similarity score. Every transformation here removes
--- something both sides agree is decoration; nothing here shortens one name
--- towards another.
---@param s string
---@return string
local function normalize_plugin_name(s)
  s = s:lower()
  s = s:gsub("%.nvim$", ""):gsub("^nvim%-", ""):gsub("^vim%-", ""):gsub("%-vim$", ""):gsub("%.vim$", "")
  return (s:gsub("[%-_%.]", ""))
end

---@type table<string, string>|nil  normalized name -> the one plugin with it
local plugin_by_norm_cache = nil
---@type table<string, string|false>|nil  stem -> plugin name, false = none
local stem_plugin_cache = nil
---@type table<string, string>|nil  `records.repo_hints()`, read once per run
local repo_hints_cache = nil

--- Drop what one run resolved. Called at the top of `M.check` for the same
--- reason `repo.reset()` is: the corpus and the loaded-plugin set both change
--- between two runs in one session, and a report that answers from the
--- previous run's cache is a report about the previous run.
local function reset_plugin_cache()
  plugin_by_norm_cache = nil
  stem_plugin_cache = nil
  repo_hints_cache = nil
end

--- Every lazy plugin whose normalized name is unambiguous.
---
--- Ambiguity is dropped rather than resolved: `dap.nvim` and `nvim-dap` both
--- normalize to `dap`, and picking either would be a coin flip printed as a
--- fact. A sheet in that position says which one it means (`repo_hints`).
---@return table<string, string>
local function plugin_by_norm()
  if plugin_by_norm_cache then
    return plugin_by_norm_cache
  end
  local out, seen = {}, {}
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if ok then
    for name in pairs(lazy_config.plugins) do
      local key = normalize_plugin_name(name)
      if seen[key] then
        out[key] = nil
      else
        seen[key] = true
        out[key] = name
      end
    end
  end
  plugin_by_norm_cache = out
  return out
end

--- The lazy.nvim plugin a cheatsheet stem names, or `nil`.
---
--- **Why this is not just `lazy_config.plugins[stem]`.** It was, and the
--- consequence ran through the whole extern scope: not one of the corpus'
--- 24 extern stems is spelled the way lazy.nvim keys its table.
--- `Diffview` is `diffview.nvim`, `Fugitive` is `vim-fugitive`, `NeoTree`
--- is `neo-tree.nvim`. Every lookup missed, and a missed lookup was read as
--- "not a plugin, so treat it as always loaded" -- which made `skipped` 0 in
--- the extern scope and checked every documented row against a session that
--- may never have loaded its plugin.
---
--- Three steps, in this order, and none of them guesses:
---   1. the sheet's own `**Repo:**` line, which always wins;
---   2. the stem verbatim, for a sheet already named after its repository;
---   3. the unique normalized match (`normalize_plugin_name`).
---
--- **No substring fallback.** The obvious "longest matching substring" is
--- wrong twice over the real corpus, and silently: `Telescope` resolves to
--- `telescope-file-browser.nvim` and `NeoTree` to
--- `neo-tree-tests-source.nvim`. Shortest-match instead only moves which
--- pairs it gets wrong. Measured, the three steps above resolve 21 of the 24
--- stems on their own; the remaining three (`Blink`, `Dap`, `NvChadUI`) name
--- their repository, so the substring guess buys nothing and costs
--- correctness.
---@param stem string
---@return string|nil
local function stem_plugin(stem)
  stem_plugin_cache = stem_plugin_cache or {}
  local cached = stem_plugin_cache[stem]
  if cached ~= nil then
    if cached == false then
      return nil
    end
    return cached
  end

  local ok, lazy_config = pcall(require, "lazy.core.config")
  local resolved = nil
  if ok then
    repo_hints_cache = repo_hints_cache or records.repo_hints()
    local hint = repo_hints_cache[stem]
    if hint and lazy_config.plugins[hint] then
      resolved = hint
    elseif lazy_config.plugins[stem] then
      resolved = stem
    else
      resolved = plugin_by_norm()[normalize_plugin_name(stem)]
    end
  end
  stem_plugin_cache[stem] = resolved or false
  return resolved
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
  if not ok then
    return true
  end
  local name = stem_plugin(plugin)
  local spec = name and lazy_config.plugins[name]
  if not spec then
    return true
  end
  return spec._ ~= nil and spec._.loaded ~= nil
end

--- The on-disk checkout of every extern cheatsheet's plugin, keyed by the
--- stem the corpus uses.
---
--- The counterpart to `config.repo_dirs()`, which resolves the *personal*
--- plugins and by construction knows nothing about a third-party one. Both
--- feed the same two lookups -- the source fallback and the opt-in repo axis
--- -- and until this existed the extern half of both could only ever grep
--- this config's own `lua/` tree, never the tree of the plugin whose key was
--- missing.
---@return table<string, string>  # stem -> absolute directory
local function extern_plugin_dirs()
  local out = {}
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if not ok then
    return out
  end
  for _, rec in ipairs(records.list(nil, "extern")) do
    if not out[rec.plugin] then
      local name = stem_plugin(rec.plugin)
      local spec = name and lazy_config.plugins[name]
      local dir = spec and spec.dir
      if type(dir) == "string" and dir ~= "" and vim.fn.isdirectory(dir) == 1 then
        out[rec.plugin] = dir
      end
    end
  end
  return out
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
  if not ok then
    return out
  end
  for name, spec in pairs(lazy_config.plugins) do
    local cmd = spec.cmd
    if type(cmd) == "string" then
      cmd = { cmd }
    end
    if type(cmd) == "table" then
      for _, entry in ipairs(cmd) do
        if type(entry) == "string" then
          out[entry] = name
        end
      end
    end
  end
  return out
end

---@type string|nil
local config_root_cached = nil

---@return string
local function config_root()
  if not config_root_cached then
    config_root_cached = vim.fs.normalize(vim.fn.stdpath("config")):gsub("/+$", "")
  end
  return config_root_cached
end

--- Who owns a source path, and where inside their tree it sits.
---
--- `nil` for a path this config cannot place -- which is an answer, and a
--- different one from "third-party": it means the file is neither a plugin
--- checkout, nor a lazy install, nor this config.
---@param path string  # a plain path, or lib.nvim's recorded `file:line`
---@return string|nil owner, string rest
local function owner_of_path(path)
  local src = (path or ""):gsub("\\", "/")
  if src == "" then
    return nil, ""
  end

  local plugin, rest = src:match("/lazy/([^/]+)/(.*)$")
  if plugin then
    return plugin, rest
  end

  plugin, rest = src:match("^%a:/repos/([^/]+)/(.*)$")
  if plugin then
    return plugin, rest
  end

  local prefix = config_root() .. "/"
  if src:sub(1, #prefix) == prefix then
    return "nvim-config", src:sub(#prefix + 1)
  end

  local runtime = src:match("/runtime/(.+)$") or src:match("^vim/(.+)$")
  if runtime then
    return "neovim runtime", runtime
  end

  return nil, src
end

--- The plugin names this config considers its own, plus `nvim-config`
--- itself.
---
--- Derived, never hand-kept: `config.repo_dirs()` resolves the enabled
--- personal plugins from the lazy spec (see `plugins/personal/list.lua`'s
--- module doc on why the Markdown list was given up as a source).
---
--- `nil` rather than an empty set when the resolution fails, and the caller
--- must treat that as "cannot tell" instead of "nothing is ours" -- silently
--- classifying every command as third-party would make the default scope
--- hide real findings, which is the one failure mode this whole axis exists
--- to prevent.
---@return table<string, true>|nil
---@return string|nil reason
local function own_plugins()
  local dirs, reason = config.repo_dirs()
  if not dirs then
    return nil, reason or "personal plugin list unresolvable"
  end
  local set = { ["nvim-config"] = true }
  for _, d in ipairs(dirs) do
    if d.name then
      set[d.name] = true
    end
  end
  return set, nil
end

--- The bare plugin name inside a `command_owner` answer.
---
--- `command_owner` returns one of a handful of shapes, and only the leading
--- token identifies the plugin: `"noice.nvim (lazy cmd stub)"`,
--- `"lib.nvim (lua/lib/...:644)"`, `"nvim-treesitter"`. The two that carry
--- no plugin at all -- `"neovim runtime: ..."` and
--- `"vimscript script_id=7"` -- are third-party by construction and must not
--- accidentally parse into one, hence the explicit rejects.
---
--- The second reject used to cover 11 commands and now covers close to none:
--- since `command_owner` resolves a `script_id` back to its file
--- (`script_path`), a Vimscript command normally arrives here as
--- `"todo-comments.nvim"` or `"nvim-config"` and takes part in the scope
--- split like any other. The reject stays for the case that resolution
--- fails, where the shape means "origin unresolved" -- and "cannot tell"
--- must not read as "ours".
---@param owner string
---@return string|nil
local function owner_plugin(owner)
  if owner == "" or owner == "unknown" then
    return nil
  end
  if owner:match("^neovim runtime") or owner:match("^vimscript script_id=") then
    return nil
  end
  return (owner:match("^([^%s(]+)"))
end

---@class Bindings.AutocmdRegistration
---@field group string augroup name
---@field event string one event; a handler on four events yields four of these
---@field src string  # "file:line" of the registering call
---@field desc string|nil

--- Every `(augroup, event)` pair registered right now, plus the same pairs
--- restricted to what THIS config and its plugins registered.
---
--- **Why two sets and not one.** `nvim_get_autocmds({})` is complete but
--- unattributable -- 324 entries here, most of them Neovim's own and every
--- plugin's. It answers "is this documented pair live", which is the
--- documented->live direction. It cannot answer the reverse without flooding,
--- exactly as `M.check`'s limitation 1 says for keymaps.
---
--- `lib.nvim.bindings.autocmd.registered()` answers the reverse precisely: it
--- holds only registrations that went through the helpers, with the call site
--- attached. Same shape of trick as the usercmd registry, and the reason an
--- Autocmds axis is cheaper to build than the three before it.
---
--- **The counting trap this sidesteps.** The corpus counts *call sites* (a
--- handler on four events is one documented row), `nvim_get_autocmds` counts
--- *event registrations* (the same handler appears four times). Nothing here
--- compares counts: both sides are flattened to `(group, event)` pairs, so a
--- four-event handler contributes four pairs on both sides and the two
--- notions never meet.
---@return table<string, true> live_pairs  # "group::event"
---@return Bindings.AutocmdRegistration[] ours
local function live_autocmds()
  local live, ours = {}, {}

  local by_id = {}
  local ok, entries = pcall(vim.api.nvim_get_autocmds, {})
  if ok then
    for _, au in ipairs(entries) do
      -- `id` is present only for autocmds created through the API; one
      -- defined in Vimscript has none, and indexing with it threw.
      if au.group_name and au.event then
        live[au.group_name .. "::" .. au.event] = true
        if au.id then
          by_id[au.id] = au.group_name
        end
      end
    end
  end

  local ok_lib, autocmd = pcall(require, "lib.nvim.bindings.autocmd")
  if not ok_lib or type(autocmd.registered) ~= "function" then
    return live, ours
  end
  for _, r in ipairs(autocmd.registered()) do
    -- `record.group` is only filled when the augroup was created through
    -- lib.nvim; the raw `nvim_create_augroup` half of this config passes an
    -- integer id, and lib.nvim has no name for it. The live table does --
    -- `nvim_get_autocmds` reports `group_name` however the group was made --
    -- so the id closes the gap exactly, without guessing.
    local group = r.group or by_id[r.id]
    if group and r.src then
      for _, event in ipairs(r.events or {}) do
        ours[#ours + 1] = { group = group, event = event, src = r.src, desc = r.desc }
      end
    end
  end
  return live, ours
end

--- `name -> file:line` for every global command lib.nvim's usercmd registry
--- knows about.
---
--- Built once per report: `registered()` deep-copies its whole list per call.
--- Buffer-local records are left out -- the live axis this feeds compares
--- against `nvim_get_commands({})`, which is global only, so a buffer-local
--- record could only mis-attribute a same-named global one.
---@return table<string, string>
local function lib_command_sites()
  local ok, usercmd = pcall(require, "lib.nvim.bindings.usercmd")
  if not ok or type(usercmd.registered) ~= "function" then
    return {}
  end
  local out = {}
  for _, r in ipairs(usercmd.registered()) do
    if r.name and r.src and not r.buffer then
      out[r.name] = r.src
    end
  end
  return out
end

--- The file a Vimscript `script_id` came from, or `nil` when Neovim cannot
--- say.
---
--- **Why this exists at all.** `nvim_get_commands` answers "defined in
--- Vimscript" with a number, and the number is *session-local*. Measured
--- across two runs of the same config, nothing changed in between:
---
---     TodoLocList   sid=25 -> sid=12
---     StartupTime   sid=9  -> sid=25
---     DoMatchParen  sid=13 -> sid=16
---
--- Printing it -- which this column did for 11 of its 54 lines -- claimed an
--- origin that identified nothing and read differently on the next
--- invocation. `getscriptinfo` turns the number back into the path, which is
--- exactly the shape `owner_of_path` already places for Lua sources:
--- `sid=19` is `lazy/todo-comments.nvim/plugin/todo.vim`, and
--- `todo-comments.nvim` is a name -- one the extern corpus even has a
--- cheatsheet stem for.
---@param sid integer
---@return string|nil
local function script_path(sid)
  if type(sid) ~= "number" or sid <= 0 then
    return nil
  end
  -- Guarded rather than trusted: a filter dict is a newer `getscriptinfo`
  -- than the bare call, and an id whose script is no longer sourced answers
  -- with an empty list rather than an error.
  local ok, info = pcall(vim.fn.getscriptinfo, { sid = sid })
  if not ok or type(info) ~= "table" or type(info[1]) ~= "table" then
    return nil
  end
  local name = info[1].name
  if type(name) ~= "string" or name == "" then
    return nil
  end
  return name
end

--- Best-effort answer to "who registered this command", for the live
--- commands that have no cheatsheet. Not a verdict and never a filter -- the
--- section stays complete either way; this only lets a reader see at a glance
--- which run of lines is somebody else's plugin and which is their own.
---
--- Four sources, in descending order of how directly they know:
---   1. lazy.nvim's `cmd` spec, for lazy-load stubs (`lazy_cmd_owners`).
---   2. lib.nvim's usercmd registry, which records the call site.
---   3. the callback's defining file, via `debug.getinfo` -- for a plugin
---      that calls `nvim_create_user_command` itself.
---   4. the `script_id` resolved back to its file (`script_path`), for
---      anything defined in Vimscript, where there is no callback to
---      inspect.
---
--- **Source 2 is new (2026-09-02) and it is the one that mattered.** Until
--- it existed this function went straight to `debug.getinfo`, which reports
--- the pcall wrapper `usercmd.create` builds -- a closure defined in
--- lib.nvim. Every command created through the helpers therefore came back
--- as the library, and the report filed 88 of them under "owner not
--- recorded", beneath a heading note apologizing for third-party
--- infrastructure the corpus never covered. That note was right about the
--- other 78 and wrong about these: they were almost all ours.
---
--- The registry had the answer the whole time (`Lib.UserCommand.Record.src`,
--- the caller site). What it did not have was the composer's verbs, which
--- were all recorded at `composer/init.lua`'s own `create` call -- fixed on
--- the lib.nvim side by passing `src`, so `:Lsp`, `:Lib`, `:Session` and the
--- other nine name their declaring file too.
---@param name string
---@param lazy_owners table<string, string>
---@param defs table  # `nvim_get_commands({})`, passed in: rebuilding it per
---                     name would mean one full command-table build per
---                     finding, 156 of them in a real run
---@param lib_sites table<string, string>  # `lib_command_sites()`, likewise
---@return string
local function command_owner(name, lazy_owners, defs, lib_sites)
  if lazy_owners[name] then
    return lazy_owners[name] .. " (lazy cmd stub)"
  end

  -- lib.nvim's registry BEFORE `debug.getinfo`, and this order is the whole
  -- point. `usercmd.create` wraps every callback in a pcall closure defined
  -- inside lib.nvim, so the live command's function reports lib.nvim as its
  -- source for every command created through the helpers -- 88 of them in the
  -- 2026-09-02 report, all lumped under "owner not recorded" beneath a note
  -- apologizing for third-party infrastructure, when almost every one was
  -- ours. The registry records the CALL SITE, which is the question being
  -- asked; `nvim_get_commands` was only ever able to answer "it exists".
  local recorded = lib_sites[name]
  if recorded then
    local owner, rest = owner_of_path(recorded)
    return owner and ("%s (%s)"):format(owner, rest) or recorded
  end

  local def = defs[name]
  if def and type(def.callback) == "function" then
    local src = ((debug.getinfo(def.callback, "S") or {}).short_src or ""):gsub("\\", "/")
    -- Still reachable, and now it means something narrower: a command whose
    -- callback lives in lib.nvim but which the registry does not hold was
    -- created around the helpers, not through them.
    if src:match("/lib%.nvim/") or src:match("^%a:/repos/lib%.nvim") then
      return "lib.nvim (created outside its own usercmd registry)"
    end
    local owner, rest = owner_of_path(src)
    if owner then
      return owner == "neovim runtime" and ("neovim runtime: " .. rest) or owner
    end
    if src ~= "" then
      return src
    end
  end
  if def and def.script_id then
    -- Same answer as source 3, reached differently: a Vimscript command has
    -- no callback to inspect, so the path comes from the id instead of from
    -- `debug.getinfo`. Shaped identically on purpose -- the report's reading
    -- rule ("a bare plugin name is third-party infra") has to keep holding.
    local path = script_path(def.script_id)
    if path then
      local owner, rest = owner_of_path(path)
      if owner then
        return owner == "neovim runtime" and ("neovim runtime: " .. rest) or owner
      end
      return path
    end
    -- Only when `getscriptinfo` cannot place the id. The number is
    -- session-local and identifies nothing (see `script_path`), so it is a
    -- last resort that says "Vimscript, origin unresolved" -- not an origin.
    return ("vimscript script_id=%d"):format(def.script_id)
  end
  return "unknown"
end

--- Every byte string that legitimately spells the same keystroke.
---
--- The two sides of the live comparison do not agree on how to encode a
--- modifier chord, and both are right:
---   - `nvim_get_keymap` reports `<C-a>` modifier-preserving, as
---     `K_SPECIAL KS_MODIFIER MOD_CTRL 'A'` = `{128,252,4,65}`.
---   - the documented side goes through `nvim_replace_termcodes`, which
---     collapses the same key to the traditional control byte `{1}`.
--- Comparing those raw made EVERY documented Ctrl chord in the corpus report
--- as "documented, not live" -- measured, and the single largest remaining
--- false-positive class after the buffer-local one. `<C-S-k>` disagreed
--- twice over (`{128,252,6,75}` vs `{128,252,2,11}`).
---
--- `keytrans()` renders both spellings as `<C-A>`, which fixes most of it,
--- but not the keys whose control byte has an older name: byte 10 renders as
--- `<NL>` from the collapsed side and `<C-J>` from the modifier-preserving
--- one. Feeding the display form back through `nvim_replace_termcodes` lands
--- both on `{10}`, so the third form closes that gap.
---
--- Returned as a LIST of forms rather than one canonical string, and indexed
--- in addition to the raw key rather than instead of it: nothing that matched
--- before this can stop matching. Both sides go through this same function,
--- which is what keeps `normalize_lhs`'s warning from applying -- that one is
--- about comparing `keytrans()` output against `.lhs`, an asymmetry where a
--- leader space stays a literal space on one side and renders as `<Space>` on
--- the other. Symmetric use has no such problem.
---@param raw string
---@return string[]
local function key_forms(raw)
  local forms, seen = { raw }, { [raw] = true }
  local function push(v)
    if type(v) == "string" and v ~= "" and not seen[v] then
      seen[v] = true
      forms[#forms + 1] = v
    end
  end

  local ok_disp, disp = pcall(vim.fn.keytrans, raw)
  if ok_disp then
    push(disp)
    if type(disp) == "string" and disp ~= "" then
      local ok_back, back = pcall(vim.api.nvim_replace_termcodes, disp, true, true, true)
      if ok_back then
        push(back)
      end
    end
  end

  return forms
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
          for _, form in ipairs(key_forms(m.lhsraw)) do
            set[form] = set[form] or {}
            table.insert(set[form], m.desc or "")
          end
        end
      end
    end
    local ok, maps = pcall(vim.api.nvim_get_keymap, mode)
    if ok then
      add(maps)
    end
    for _, buf in ipairs(bufs) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local ok_buf, buf_maps = pcall(vim.api.nvim_buf_get_keymap, buf, mode)
        if ok_buf then
          add(buf_maps)
        end
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
  -- Looked up under every spelling `live_keymaps` indexed, for the encoding
  -- mismatch `key_forms` documents.
  local forms = key_forms(lhs)

  for _, mode in ipairs(modes) do
    local in_mode = live_maps[mode]
    local descs
    if in_mode then
      for _, form in ipairs(forms) do
        descs = in_mode[form]
        if descs then
          break
        end
      end
    end
    if descs then
      if not doc_desc then
        return true
      end
      local any_desc = false
      for _, d in ipairs(descs) do
        if d ~= "" then
          any_desc = true
          if strip_quotes(d) == doc_desc then
            return true
          end
        end
      end
      if not any_desc then
        return true
      end
    end
  end
  -- Either the key is registered nowhere, or every desc under it names a
  -- different binding. Both are "documented, not registered".
  return false
end

---@class Bindings.DriftFinding
---@field kind "keymap-not-live"|"usercmd-not-live"|"usercmd-undocumented"|"keymap-undocumented"|"usercmd-undocumented-source"|"keymap-not-in-repo"|"usercmd-not-in-repo"|"autocmd-not-live"|"autocmd-undocumented"
---@field plugin string|nil
---@field heading string|nil  # the record's table heading, keymap axis only
---@field group string|nil    # plugin + heading, the verdict's grouping key
---@field notation string
---@field file string|nil
---@field line integer|nil
---@field unverifiable boolean|nil  # see `M.check`'s per-table verdict
---@field repo_absent boolean|nil   # `keymap-not-live` only: the source
---  fallback looked and did not find the key either, so the finding says
---  "written down nowhere" and not just "not registered right now"
---@field owner string|nil    # `usercmd-undocumented` only: who registered it

---@class Bindings.RepoInfo
---@field ran boolean whether `opts.repo` asked for the axis at all
---@field reason string|nil why it could not be consulted, when it could not
---@field checked string[] plugins the axis actually answered for, sorted
---@field root string|nil the scanned collection directory, when `opts.repo_root` named one
---@field resolved string[] every project the resolver returned, sorted
---@field undocumented string[] resolved projects with no cheatsheet in this corpus, sorted
---@field fallback boolean whether the default source fallback had a
---  checkout mapping to work with -- false means every `keymap-not-live`
---  finding below is the weaker, live-only claim
---@field fallback_confirmed integer documented keys AND command names that
---  were not live but ARE written in their plugin's own source, and are
---  therefore not reported. Carried so a reader can reconcile this run's
---  count with one from before the fallback existed. One number for both
---  axes on purpose: it answers "how many findings did the fallback
---  suppress", and splitting it would invite the two halves to be compared
---  with each other, which means nothing.
---@field skipped_rows integer documented rows dropped because their plugin
---  is not loaded — the same reasoning as `AutocmdInfo.unanchored`. The
---  skipped *plugin* count was always printed; the row count was not, and
---  the two are far apart: the 17 skipped extern stems of a normal run are
---  541 unexamined rows. A report that prints "0 findings" over that has
---  to say so, or the number reads as a verdict about the corpus instead
---  of a fact about this session.

---@class Bindings.AutocmdInfo
---@field registry integer  # `(augroup, event)` pairs lib.nvim's registry could attribute
---@field unanchored integer  # documented Autocmds rows this axis cannot reach

---@class Bindings.ScopeInfo
---@field scope "personal"|"extern"|"all" what was asked for
---@field applied boolean whether the own/third-party split could be made
---@field hidden integer live undocumented commands the scope filtered out
---@field reason string|nil why the split could not be made, when it could not

--- @param plugin string|nil narrow to one plugin's own files
---   (`records.lua`'s `plugin` field, i.e. the filename stem). With a
---   plugin given, the usercmd-undocumented direction is skipped — there
---   is no reliable way to attribute a live, undocumented command to one
---   specific plugin, and the per-plugin `unverifiable` verdict below is
---   not applied — asking about one plugin explicitly is a request to see
---   its findings, not to have them summarized away.
--- @param opts { repo?: boolean, repo_root?: string, scope?: "personal"|"extern"|"all" }|nil additive; every
---   field defaults to off. `repo` enables the checkout axis for plugins
---   that never loaded (module doc, "The repo axis") -- NOT the source
---   fallback for the ones that did, which runs in every scope with no
---   option at all (module doc, "The repo fallback"). `repo_root` points
---   the axis at one collection directory holding several Lua projects
---   instead of the
---   default per-plugin resolution, and implies `repo` -- naming a root is
---   already the request, and making the caller pass both would only create
---   a combination (`repo_root` without `repo`) whose sole possible meaning
---   is "ignore what I just said". `scope` decides which side of the
---   own/third-party line the *live, undocumented commands* direction
---   reports; it does not touch the other axes, which only ever read the
---   corpus it reads. `"personal"` (the default) reports only
---   commands this config or one of its own plugins registers -- a
---   third-party command with no cheatsheet is not drift, it is a corpus
---   this config never claimed to cover; the documented-side axes read
---   `PersonelPlugins/BINDINGS`. `"extern"` is the mirror image --
---   third-party commands, checked against `ExternPlugins/Bindings`.
---   `"all"` reads both trees and reports both sides (the behaviour before
---   this option existed).
---   Browsing and searching are unaffected in every scope: `:Bindings
---   search`/`browse` read both trees, because looking for a key means
---   looking for it wherever it comes from.
--- @return Bindings.DriftFinding[]
--- @return string[] skipped_plugins plugin names excluded because they
---   aren't loaded in this session (module doc point 4) AND the repo axis
---   could not answer for them either, sorted, deduped
--- @return string|nil source_reason
--- @return Bindings.RepoInfo repo_info
--- @return Bindings.ScopeInfo scope_info what the `scope` option did, so a
---   report can say which commands it chose not to show rather than leaving
---   the reader to wonder why a number dropped.
--- @return Bindings.AutocmdInfo autocmd_info how much of the Autocmds corpus
---   the axis could not reach, and how many registrations it had to compare
---   against. The same reasoning as `scope_info`: a small finding count means
---   two very different things depending on how much was looked at.
function M.check(plugin, opts)
  opts = opts or {}
  local findings = {}
  local skipped = {}
  -- Counted where the row is dropped rather than reconstructed afterwards:
  -- the three sites below know exactly which rows they let go, and a second
  -- pass over the corpus to re-derive the same number would both cost a
  -- full re-read and be free to disagree with them.
  local skipped_rows = 0

  -- Scope of the live-undocumented direction. Resolved before the axes run
  -- so the filter and the report agree on one answer, and so an
  -- unresolvable personal list degrades to "show everything" rather than to
  -- "show nothing" -- see `own_plugins`.
  local scope = opts.scope or "personal"
  if scope ~= "personal" and scope ~= "extern" and scope ~= "all" then
    scope = "personal"
  end
  -- Which of the two BINDINGS trees the *documented -> live* axes read.
  -- `nil` is `records.list`'s "both". Without this, `scope = "extern"` was
  -- half an answer: it switched the live->documented direction over to
  -- third-party commands while the other axes kept checking the personal
  -- cheatsheets, so "only the external ones" still reported our keymaps.
  -- Explicit `if`, not `(scope == "all") and nil or scope`: that idiom
  -- collapses, because `and nil` makes the whole expression fall through to
  -- the `or` branch and hands back `"all"` -- a value matching neither root,
  -- so `records.list` returned nothing and the documented-side axes silently
  -- reported zero findings. Measured before the fix: 54 instead of 383.
  local corpus_scope = scope
  if scope == "all" then
    corpus_scope = nil
  end

  local own_set, own_reason = own_plugins()
  ---@type Bindings.ScopeInfo
  local scope_info = {
    scope = scope,
    applied = (scope == "all") or (own_set ~= nil),
    hidden = 0,
    reason = (scope ~= "all") and own_reason or nil,
  }

  -- Repo axis, resolved up front: the per-record loops below need to know
  -- whether an unloaded plugin has a checkout to fall back on before they
  -- decide to skip it.
  --
  -- Resolved on EVERY run, not only when `opts.repo` asked for the axis --
  -- the live axis' fallback (module doc, "The repo fallback") needs the same
  -- mapping in the default report. Resolving is cheap on its own: it reads a
  -- Lua spec, no file in any checkout is opened until `repo.mentions` is
  -- actually asked something, which happens per not-live key and not per
  -- plugin. What stays gated on `want_repo` is the *unloaded-plugin* axis
  -- further down -- that one would index every checkout in the list.
  ---@type table<string, string>|nil
  local repo_dirs = nil
  local repo_reason = nil
  local repo_resolved = {}
  local want_repo = opts.repo == true or type(opts.repo_root) == "string"
  repo.reset()
  reset_plugin_cache()
  do
    local dirs, reason
    if type(opts.repo_root) == "string" then
      dirs, reason = config.repo_dirs_under(opts.repo_root)
    else
      dirs, reason = config.repo_dirs()
    end
    repo_reason = reason
    if dirs then
      repo_dirs = {}
      for _, entry in ipairs(dirs) do
        repo_dirs[entry.name] = entry.dir
        repo_resolved[#repo_resolved + 1] = entry.name
      end
      -- The extern half, which `config.repo_dirs()` cannot know about: it
      -- resolves the plugins this config *owns*. Added after, never over --
      -- a stem that names a personal checkout keeps it, and a lazy install
      -- of the same name does not shadow the tree being worked in.
      for stem, dir in pairs(extern_plugin_dirs()) do
        if not repo_dirs[stem] then
          repo_dirs[stem] = dir
          repo_resolved[#repo_resolved + 1] = stem
        end
      end
    end
  end
  -- Written as an `if` rather than `repo_dirs and … or nil`: the `and/or`
  -- form keeps the guard's own type in the inferred union, so the local read
  -- as `string|table<string, string>|nil` at both search sites below.
  local config_lua ---@type string|nil
  if repo_dirs then
    config_lua = config.config_lua_root()
  end
  -- Candidate: had a checkout to look in. Answered: the look succeeded.
  -- A candidate that never got answered is still an unchecked plugin and
  -- has to land back in `skipped`, see the fold-in near the end.
  local repo_candidates, repo_answered = {}, {}

  -- Keymaps: documented (Personal) but not live.
  local checkable, needed_modes = {}, {}
  local repo_keymaps = {}
  for _, rec in ipairs(records.list("Keymaps", corpus_scope)) do
    -- `rec.meta`: a corpus-level file (`All.md`, `Collisions.md`,
    -- `Overview.md`) documents nothing of its own, so nothing in it can be
    -- missing. See `records.lua`'s `META_FILES`. This direction skips them;
    -- the live-but-undocumented one below still counts them as documentation.
    local ours = (not plugin or rec.plugin == plugin) and not rec.meta
    if ours and is_plugin_loaded(rec.plugin) then
      -- Both forms are kept, not just the normalized one: `lhs` is the raw
      -- byte string the live probe compares against, `token` the
      -- cheatsheet's own `<leader>iv` text the source fallback greps for.
      -- Deriving the second from the first is not possible in general --
      -- `normalize_lhs` is lossy about spelling (`<Leader>` vs `<leader>`).
      local token = extract_lhs_token(rec)
      local lhs = token and normalize_lhs(token)
      if lhs then
        local modes = extract_modes(rec)
        for _, m in ipairs(modes) do
          needed_modes[m] = true
        end
        checkable[#checkable + 1] =
          { rec = rec, lhs = lhs, token = token, modes = modes, desc = extract_desc(rec) }
      end
    elseif ours then
      -- Only when the axis was asked for: this branch indexes the checkout of
      -- every unloaded plugin, which is the cost the axis is opt-in for. The
      -- fallback below pays a per-key price instead, on the handful of
      -- plugins that actually have a not-live documented key.
      local dir = want_repo and repo_dirs and repo_dirs[rec.plugin] or nil
      if not dir then
        skipped[rec.plugin] = true
        skipped_rows = skipped_rows + 1
      else
        repo_candidates[rec.plugin] = true
        local token = extract_lhs_token(rec)
        local lhs = token and normalize_lhs(token)
        if lhs then
          -- The modes matter here too: the live suppressor below runs
          -- `is_live` over exactly the same mode set, so these have to be
          -- collected before `live_keymaps` is built.
          local modes = extract_modes(rec)
          for _, m in ipairs(modes) do
            needed_modes[m] = true
          end
          repo_keymaps[#repo_keymaps + 1] = {
            rec = rec,
            dir = dir,
            token = token,
            lhs = lhs,
            modes = modes,
            desc = extract_desc(rec),
          }
        end
      end
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

  -- The source fallback for a documented key the live probe did not find.
  -- See the module doc, "The repo fallback", for why this runs by default
  -- while the unloaded-plugin axis above stays opt-in.
  --
  -- Two trees, same pair and same order as the opt-in axis: the plugin's own
  -- checkout, then this config's `lua/` — a personal plugin's `<leader>`
  -- entry point is very often registered over here, in a lazy `keys` spec,
  -- and not in the plugin at all.
  ---@param entry { rec: Bindings.Record, token: string|nil }
  ---@return boolean found written as a string literal in either tree
  ---@return boolean answered at least one of the two trees was readable
  local function in_source(entry)
    if not repo_dirs or not entry.token then
      return false, false
    end
    local dir = repo_dirs[entry.rec.plugin]
    local in_plugin = repo.mentions(dir, entry.token, { ignore_case = true })
    if in_plugin == true then
      return true, true
    end
    local in_config = repo.mentions(config_lua, entry.token, { ignore_case = true })
    if in_config == true then
      return true, true
    end
    return false, (in_plugin ~= nil) or (in_config ~= nil)
  end

  -- Counted for the report, not for a verdict: without it a reader cannot
  -- reconcile this run's number with the last one, and "48 findings vanished"
  -- is exactly the kind of drop that has to be explained rather than enjoyed.
  local fallback_confirmed = 0

  for _, entry in ipairs(checkable) do
    local group = group_of(entry.rec)
    checked_count[group] = (checked_count[group] or 0) + 1
    if is_live(live_maps, entry.modes, entry.lhs, entry.desc) then
      found_count[group] = (found_count[group] or 0) + 1
    else
      local found, answered = in_source(entry)
      if found then
        -- Counted as found, not merely dropped. The per-table verdict below
        -- reads `found_count`, and leaving these out would flip a table into
        -- "not one of its keys is live" — the buffer-local scope verdict —
        -- on the strength of keys this axis just confirmed.
        found_count[group] = (found_count[group] or 0) + 1
        fallback_confirmed = fallback_confirmed + 1
      else
        keymap_findings[#keymap_findings + 1] = {
          kind = "keymap-not-live",
          plugin = entry.rec.plugin,
          heading = entry.rec.heading,
          group = group,
          notation = entry.lhs,
          file = entry.rec.file,
          line = entry.rec.line,
          -- Nothing when the fallback could not look: the claim is then the
          -- old, weaker one ("not registered right now"), and `M.describe`
          -- says which of the two a section holds.
          repo_absent = answered or nil,
        }
      end
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

  -- Repo axis, keymaps: an unloaded plugin's documented key, looked for in
  -- the one place that exists without a session — its checkout on disk.
  --
  -- Reported only when all three suppressors agree the key is written down
  -- nowhere (module doc, "The repo axis"): not in the plugin's own source,
  -- not in this config's own lua tree, and not registered right now. The
  -- per-table `unverifiable` verdict deliberately does not apply — that
  -- verdict is about a buffer-local scope not being open, which is a
  -- statement about the LIVE axis and says nothing about a source tree.
  for _, entry in ipairs(repo_keymaps) do
    local in_repo = repo.mentions(entry.dir, entry.token, { ignore_case = true })
    if in_repo ~= nil then
      repo_answered[entry.rec.plugin] = true
      if
        not in_repo
        and repo.mentions(config_lua, entry.token, { ignore_case = true }) ~= true
        and not is_live(live_maps, entry.modes, entry.lhs, entry.desc)
      then
        findings[#findings + 1] = {
          kind = "keymap-not-in-repo",
          plugin = entry.rec.plugin,
          heading = entry.rec.heading,
          notation = entry.token,
          file = entry.rec.file,
          line = entry.rec.line,
        }
      end
    end
  end

  -- The same source fallback the keymap axis has had since the start, on the
  -- usercmd axis. Same two trees, same order, same three-way answer -- one
  -- difference, and it is the whole reason this needed its own function:
  --
  -- **Case-SENSITIVE.** The keymap side folds case because the corpus writes
  -- `<Leader>` where the source writes `<leader>`; a command name has no such
  -- spelling variance, and folding it makes `:Images` match the word "images"
  -- in half of images.nvim's own source. Every command would then count as
  -- written down and the axis would confirm everything. The opt-in repo axis
  -- below already draws exactly this distinction, for exactly this reason.
  --
  -- What it cannot see, and this is structural rather than a gap to close:
  -- a Vimscript `com! -bang UnicodeDownload …` is unquoted, and
  -- `repo.mentions` only matches quoted literals. `:UnicodeDownload` and
  -- `:DigraphNew` therefore stay reported however loaded their plugin is.
  ---@param stem string  # the cheatsheet stem, i.e. `rec.plugin`
  ---@param name string  # the bare command name, no leading colon
  ---@return boolean found written as a quoted string literal in either tree
  ---@return boolean answered at least one of the two trees was readable
  local function cmd_in_source(stem, name)
    if not repo_dirs then
      return false, false
    end
    local in_plugin = repo.mentions(repo_dirs[stem], name)
    if in_plugin == true then
      return true, true
    end
    local in_config = repo.mentions(config_lua, name)
    if in_config == true then
      return true, true
    end
    return false, (in_plugin ~= nil) or (in_config ~= nil)
  end

  -- Usercmds: documented (Personal) but not live.
  local live_cmds = live_commands()
  local seen_personal = {}
  for _, rec in ipairs(records.list("Usercmds", corpus_scope)) do
    -- Same `rec.meta` skip as the keymap direction above.
    local ours = (not plugin or rec.plugin == plugin) and not rec.meta
    if ours and is_plugin_loaded(rec.plugin) then
      local name = extract_usercmd(rec)
      if name and not seen_personal[name] then
        seen_personal[name] = true
        if not live_cmds[name] then
          local found, answered = cmd_in_source(rec.plugin, name)
          if found then
            fallback_confirmed = fallback_confirmed + 1
          else
            findings[#findings + 1] = {
              kind = "usercmd-not-live",
              plugin = rec.plugin,
              notation = ":" .. name,
              file = rec.file,
              line = rec.line,
              -- Same meaning as on the keymap side: nothing when neither
              -- tree could be read, because the claim is then the weaker,
              -- live-only one.
              repo_absent = answered or nil,
            }
          end
        end
      end
    elseif ours then
      -- Same `want_repo` gate as the keymap side above, and for the same
      -- reason: this branch is the opt-in axis, not the default fallback.
      local dir = want_repo and repo_dirs and repo_dirs[rec.plugin] or nil
      if not dir then
        skipped[rec.plugin] = true
        skipped_rows = skipped_rows + 1
      else
        repo_candidates[rec.plugin] = true
        -- Repo axis, usercmds. Case-SENSITIVE here, unlike the keymap side:
        -- a command name is a capitalized identifier, and folding case makes
        -- `:Images` match the word "images" in half of images.nvim's own
        -- source — every command would count as found and the axis would
        -- never report anything. Key notation has the opposite problem
        -- (`<Leader>` vs `<leader>`), hence the difference.
        local name = extract_usercmd(rec)
        if name and not seen_personal[name] then
          seen_personal[name] = true
          local in_repo = repo.mentions(dir, name)
          if in_repo ~= nil then
            repo_answered[rec.plugin] = true
            if not in_repo and repo.mentions(config_lua, name) ~= true and not live_cmds[name] then
              findings[#findings + 1] = {
                kind = "usercmd-not-in-repo",
                plugin = rec.plugin,
                notation = ":" .. name,
                file = rec.file,
                line = rec.line,
              }
            end
          end
        end
      end
    end
  end

  -- A plugin the repo axis had a checkout for but never got an answer from
  -- (no readable source in it, or not one of its rows carried a usable lhs
  -- or command name) is an unchecked plugin like any other, and belongs in
  -- the skipped list rather than in the "checked against its checkout"
  -- count. `repo_answered` is what the report may claim.
  for name in pairs(repo_candidates) do
    if not repo_answered[name] then
      skipped[name] = true
    end
  end

  -- Hand the indexed trees back. Measured over the real checkouts, holding
  -- them costs 28 MiB for the rest of the session, which is not a price a
  -- report someone ran once should keep charging — and the next run must
  -- re-read anyway (`repo.reset()` at the top), so nothing is saved by
  -- keeping them.
  --
  -- Unconditional since the fallback exists: `if want_repo` used to be the
  -- whole truth about who indexed a tree, and is not any more — a default
  -- run that greps five checkouts would otherwise leave them resident for
  -- the session while claiming the axis never ran.
  repo.reset()

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
    -- Table rows first, then every command name the corpus mentions in prose
    -- (`records.mentions`). The scraper reads rows, so a command written as a
    -- bullet or in a sentence used to count as undocumented — 31 of them in
    -- the 2026-09-02 run, every one of them actually documented. For THIS
    -- direction the question is only whether the corpus mentions the command
    -- at all, which a prose mention answers as well as a row does.
    local documented_anywhere = records.mentions()
    for _, rec in ipairs(records.list("Usercmds")) do
      local name = extract_usercmd(rec)
      if name then
        documented_anywhere[name] = true
      end
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

    -- A documented FAMILY (`:*Files` in `pickers.nvim.md`'s table) covers its
    -- members. The 23 scope commands pickers.nvim generates from a collection
    -- list are the motivating case: listing them one by one would be the
    -- hand-kept mirror this repo calls a defect everywhere else, so the sheet
    -- documents the generator and this accepts what the generator makes.
    --
    -- The claim is checked against the command's OWNER, not just its name.
    -- Without that, `:*Files` also swallowed diffview.nvim's
    -- `:DiffviewFocusFiles` -- a third-party command marked documented by a
    -- sheet that never mentions it. This pairing is only possible since
    -- `command_owner` learned to answer at all; see there.
    local family_claims = records.family_claims()

    ---@param owner string  # `command_owner`'s answer
    ---@param plugin string # the claiming sheet's stem
    ---@return boolean
    local function owner_is(owner, plugin)
      return owner == plugin or owner:sub(1, #plugin + 1) == plugin .. " "
    end

    ---@param cmd string
    ---@param owner string
    ---@return boolean
    local function claimed_by_family(cmd, owner)
      for _, claim in ipairs(family_claims) do
        if cmd:match(claim.pattern) and owner_is(owner, claim.plugin) then
          return true
        end
      end
      return false
    end

    local lazy_owners = lazy_cmd_owners()
    local command_defs = vim.api.nvim_get_commands({})
    local lib_sites = lib_command_sites()
    local names = vim.tbl_keys(live_cmds)
    table.sort(names)
    for _, name in ipairs(names) do
      if not documented_anywhere[name] and not reported_by_source[name] then
        -- Resolved before the family check, which needs it, rather than
        -- inside the finding: the two questions share one answer.
        local owner = command_owner(name, lazy_owners, command_defs, lib_sites)
        if not claimed_by_family(name, owner) then
          -- `own_set == nil` means the personal list could not be resolved,
          -- and `in_scope` then stays true for every command: a scope that
          -- cannot tell the two apart must not quietly drop half the report.
          -- `scope_info.applied` carries that to the reader.
          local in_scope = true
          if own_set then
            local p = owner_plugin(owner)
            local ours = (p ~= nil) and own_set[p] == true
            if scope == "personal" then
              in_scope = ours
            elseif scope == "extern" then
              in_scope = not ours
            end
          end
          if in_scope then
            findings[#findings + 1] = {
              kind = "usercmd-undocumented",
              plugin = nil,
              notation = ":" .. name,
              owner = owner,
            }
          else
            scope_info.hidden = scope_info.hidden + 1
          end
        end
      end
    end
  end

  -- Autocmds, both directions. Added 2026-09-02; until then the third of the
  -- corpus under `Autocmds/` was read for command names and never checked
  -- against anything -- 241 documented rows, and a report saying "1 finding"
  -- while none of them had been looked at. What made it worth building was
  -- evidence that the surface drifts: lsp.nvim's `b260fc8` registered two
  -- autocmds on the raw API and falsified two explicit sentences of
  -- `Autocmds/lsp.nvim.md`, and a person found it, not a checker.
  local live_pairs, our_autocmds = live_autocmds()
  local documented_pairs = {}
  -- The reverse direction asks "does the corpus document this at all", so it
  -- reads BOTH trees whatever the scope is -- exactly like the usercmd
  -- direction's `documented_anywhere`. Built from the scoped set alone, the
  -- personal run reported 77 undocumented autocmds and the `all` run 70: the
  -- seven differences were ours, documented in the Extern tree, and the
  -- narrower question had made them look like gaps.
  local documented_anywhere_pairs = {}
  ---@type Bindings.FamilyClaim[]
  local autocmd_families = {}
  local autocmd_unanchored = 0

  for _, rec in ipairs(records.list("Autocmds", corpus_scope)) do
    local ours_row = (not plugin or rec.plugin == plugin) and not rec.meta
    if ours_row then
      local group = extract_augroup(rec)
      local events = extract_events(rec)
      -- A row whose augroup cell carries a placeholder documents a FAMILY:
      -- `ra_telemetry_<namespace>` is one augroup per telemetry instance,
      -- built in a loop. `extract_augroup` rejects the token (rightly -- the
      -- forward direction has no concrete name to look for), so the claim is
      -- read straight off the cell here, and only the reverse direction uses
      -- it. Same asymmetry, and the same reason, as the command families.
      local aug_idx = column_index(rec, AUGROUP_HEADERS)
      local aug_cell = aug_idx and rec.cells[aug_idx]
      if aug_cell and aug_cell ~= "" then
        local pattern = records.wildcard_pattern(first_token(aug_cell), "augroup")
        if pattern then
          autocmd_families[#autocmd_families + 1] = { plugin = rec.plugin, pattern = pattern }
        end
      end
      if not group or #events == 0 then
        -- Counted, not reported. A row with no augroup column (or no event
        -- Neovim knows) is not a defect in the plugin, it is a row this axis
        -- cannot reach -- and saying how many there are is the honest half of
        -- a check that skips them.
        autocmd_unanchored = autocmd_unanchored + 1
      else
        for _, event in ipairs(events) do
          documented_pairs[group .. "::" .. event] = true
        end
        if is_plugin_loaded(rec.plugin) then
          local missing = {}
          for _, event in ipairs(events) do
            if not live_pairs[group .. "::" .. event] then
              missing[#missing + 1] = event
            end
          end
          -- One finding per row, not per event: the row is the documented
          -- claim, and a handler that lost two of its four events is one
          -- thing to go and look at, not two.
          if #missing > 0 then
            findings[#findings + 1] = {
              kind = "autocmd-not-live",
              plugin = rec.plugin,
              heading = rec.heading,
              notation = group .. " (" .. table.concat(missing, ", ") .. ")",
              file = rec.file,
              line = rec.line,
            }
          end
        else
          skipped[rec.plugin] = true
          skipped_rows = skipped_rows + 1
        end
      end
    end
  end

  -- The reverse direction, and the only one that can be asked without
  -- flooding: lib.nvim's registry holds our own registrations, never
  -- Neovim's defaults or a third-party plugin's. Unscoped only, for the same
  -- reason the usercmd one is -- see the `plugin` param doc.
  if not plugin then
    for _, rec in ipairs(records.list("Autocmds")) do
      local g = extract_augroup(rec)
      if g then
        for _, event in ipairs(extract_events(rec)) do
          documented_anywhere_pairs[g .. "::" .. event] = true
        end
      end
    end

    -- Does this plugin's own sheet name the augroup in prose? Cached per
    -- plugin: `sheet_text` re-reads files, and one lookup per registration
    -- would read the same sheet a dozen times.
    local prose_cache = {}
    ---@param owner string|nil
    ---@param group string
    ---@return boolean
    local function named_in_prose(owner, group)
      if not owner then
        return false
      end
      local text = prose_cache[owner]
      if text == nil then
        text = records.sheet_text("Autocmds", owner)
        prose_cache[owner] = text
      end
      if text == "" then
        return false
      end
      local escaped = group:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
      return text:find("%f[%w_]" .. escaped .. "%f[^%w_]") ~= nil
    end

    -- Grouped by call site, not by event. `SessionsNvim` is one
    -- `autocmd.create` on six events; six findings for it would be the very
    -- "event registrations instead of call sites" confusion this axis was
    -- built to avoid, and on the side of the report a reader acts on.
    local groups, order = {}, {}
    for _, r in ipairs(our_autocmds) do
      local key = r.group .. "::" .. r.src
      if not documented_pairs[r.group .. "::" .. r.event] then
        if not groups[key] then
          groups[key] = { group = r.group, src = r.src, events = {}, seen = {} }
          order[#order + 1] = key
        end
        local g = groups[key]
        if not g.seen[r.event] then
          g.seen[r.event] = true
          g.events[#g.events + 1] = r.event
        end
      end
    end

    for _, key in ipairs(order) do
      local g = groups[key]
      local owner, rest = owner_of_path(g.src)
      local covered = named_in_prose(owner, g.group)
      if not covered and owner then
        for _, claim in ipairs(autocmd_families) do
          -- Bound to the claiming sheet's plugin, exactly like the command
          -- families: `ra_telemetry_<namespace>` from
          -- `runtime-analysis.nvim.md` may cover that plugin's augroups and
          -- nobody else's.
          if claim.plugin == owner and g.group:match(claim.pattern) then
            covered = true
            break
          end
        end
      end
      if not covered then
        for _, event in ipairs(g.events) do
          if documented_anywhere_pairs[g.group .. "::" .. event] then
            covered = true
            break
          end
        end
      end
      if not covered then
        local in_scope = true
        if scope ~= "all" and own_set then
          local is_ours = owner ~= nil and own_set[owner] == true
          in_scope = (scope == "personal") == is_ours
        end
        if in_scope then
          table.sort(g.events)
          findings[#findings + 1] = {
            kind = "autocmd-undocumented",
            plugin = owner,
            notation = g.group .. " (" .. table.concat(g.events, ", ") .. ")",
            owner = owner and (owner .. " (" .. rest .. ")") or g.src,
          }
        else
          scope_info.hidden = scope_info.hidden + 1
        end
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
  if source_findings then
    vim.list_extend(findings, source_findings)
  end

  local skipped_list = vim.tbl_keys(skipped)
  table.sort(skipped_list)

  local repo_checked = vim.tbl_keys(repo_answered)
  table.sort(repo_checked)
  table.sort(repo_resolved)

  -- Which resolved projects this corpus has no cheatsheet for. Only asked
  -- when a root was scanned: with the default per-plugin resolution the
  -- answer is trivially empty (that resolver starts from the plugin list),
  -- whereas a collection directory is whatever the user happens to keep
  -- there -- and "this checkout is documented nowhere" is precisely the
  -- part of a whole-path report that no other axis reports.
  local repo_undocumented = {}
  if type(opts.repo_root) == "string" and #repo_resolved > 0 then
    local documented = {}
    -- Both trees, deliberately: the question is whether this corpus
    -- documents the checkout at all, and a cheatsheet under
    -- `ExternPlugins/Bindings` answers it just as well as one under
    -- `PersonelPlugins`. Reading only the personal tree reported every
    -- externally-documented project as undocumented.
    for _, rec in ipairs(records.list(nil, nil)) do
      documented[rec.plugin] = true
    end
    for _, name in ipairs(repo_resolved) do
      if not documented[name] then
        repo_undocumented[#repo_undocumented + 1] = name
      end
    end
  end

  ---@type Bindings.RepoInfo
  local repo_info = {
    ran = want_repo,
    reason = repo_reason,
    checked = repo_checked,
    root = type(opts.repo_root) == "string" and opts.repo_root or nil,
    resolved = repo_resolved,
    undocumented = repo_undocumented,
    fallback = repo_dirs ~= nil,
    fallback_confirmed = fallback_confirmed,
    skipped_rows = skipped_rows,
  }

  return findings,
    skipped_list,
    source_reason,
    repo_info,
    scope_info,
    {
      registry = #our_autocmds,
      unanchored = autocmd_unanchored,
    }
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
    if lhs then
      documented_keys[lhs] = true
    end
  end
  for _, rec in ipairs(records.list("Usercmds")) do
    local name = extract_usercmd(rec)
    if name then
      documented_cmds[name] = true
    end
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
  if ok and type(out) == "string" and out ~= "" then
    return out
  end
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
  elseif f.kind == "keymap-not-in-repo" or f.kind == "usercmd-not-in-repo" then
    -- No `readable()` here, unlike the not-live kinds: a repo finding's
    -- notation is the cheatsheet's own `<leader>iv` text, never the raw
    -- byte form, because that is the form a source tree is searched for.
    return ("  %-22s %-20s %s:%d"):format(f.plugin, f.notation, f.file, f.line)
  elseif f.kind == "keymap-undocumented" then
    return ("  %-20s %s:%d"):format(readable(f.notation), f.file or "?", f.line or 0)
  elseif f.kind == "usercmd-undocumented-source" then
    return ("  %-20s %s:%d"):format(f.notation, f.file or "?", f.line or 0)
  elseif f.kind == "autocmd-not-live" then
    -- Wider notation column than the keymap kinds: an augroup name plus the
    -- events that are missing does not fit in 20, and truncating the events
    -- would remove the only part that says what to go and look at.
    return ("  %-22s %-38s %s:%d"):format(f.plugin, f.notation, f.file, f.line)
  end
  return ("  %-28s %s"):format(f.notation, f.owner or "unknown")
end

--- Startup phases of this config that never ran, by label.
---
--- The whole point: this config registers its own commands and keymaps in a
--- `startup.on("UIReady", ...)` phase, and "UIReady" is VimEnter plus a
--- `vim.schedule`. A `nvim --headless -c "luafile ..."` run executes its
--- script *before* that, so `bindings.usrcmds` and `bindings.mappings` are
--- never loaded -- and every binding they would have registered is reported
--- as documented-but-not-live. Measured 2026-09-02: 200 findings become 111
--- once the phase is loaded by hand, i.e. **89 of them were the measurement,
--- not the corpus**. Interactive `:Bindings check` never sees this, which is
--- exactly why it went unnoticed until a headless report was believed.
---
--- Soft dependency on purpose: `startup` is this config's module, and the
--- rest of `bindings_explorer` is written to survive a move into its own
--- repo. No module, no claim -- `nil` reads as "no information", never as
--- "nothing pending".
---@return string[]|nil labels nil when the startup module is unavailable
local function pending_phases()
  local ok, startup = pcall(require, "startup")
  if not ok or type(startup) ~= "table" or type(startup.pending) ~= "function" then
    return nil
  end
  local ok_call, marks = pcall(startup.pending)
  if not ok_call or type(marks) ~= "table" then
    return nil
  end
  local labels = {}
  for _, m in ipairs(marks) do
    labels[#labels + 1] = tostring(m.label or "?")
  end
  table.sort(labels)
  return labels
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
    -- A function, not a string, because the claim this section makes now
    -- depends on whether the source fallback could look (`repo_absent`).
    -- Written down nowhere at all is a strictly stronger statement than not
    -- registered in this session, and printing the strong one over findings
    -- the fallback never reached would be the report lying about its own
    -- evidence. Accurate for a scoped run too, where the per-table verdict
    -- does not run and this section holds every keymap finding.
    note = function(matched)
      local checked = 0
      for _, f in ipairs(matched) do
        if f.repo_absent then
          checked = checked + 1
        end
      end
      if checked == 0 then
        return "not found globally, nor in any buffer open right now"
      end
      -- "any source that could be read", not "the plugin's own source": in
      -- the `extern` scope the cheatsheet's stem is a third-party plugin
      -- with no local checkout, and the only tree that answers is this
      -- config's own `lua/` -- which is where those keys are bound anyway.
      -- Naming the plugin's source there would claim a look that never
      -- happened.
      if checked == #matched then
        return "not live anywhere, and not a string literal in any source that could be read"
      end
      return ("not found globally, nor in any buffer open right now; %d of %d also absent from every readable source tree"):format(
        checked,
        #matched
      )
    end,
  },
  {
    kinds = { ["keymap-not-in-repo"] = true, ["usercmd-not-in-repo"] = true },
    title = "Documented, and nowhere in the plugin's own checkout",
    note = "source grep, not an API query: an lhs the plugin computes at runtime is a false finding here",
  },
  {
    kinds = { ["keymap-undocumented"] = true, ["usercmd-undocumented-source"] = true },
    title = "Registered in this config's source, not documented",
    note = "from docs/map/module_map.json — only as fresh as the last :DocMap",
  },
  {
    kinds = { ["autocmd-not-live"] = true },
    title = "Autocmds — documented, not registered",
    -- The dominant class here is neither drift nor a tool defect: an autocmd
    -- whose feature is off (`LspFormatOnSave` exists only while format-on-save
    -- is on, and its own sheet says so) or whose plugin loads on a trigger
    -- this session never pulled. Naming it is what keeps the section readable.
    note = "one line per documented ROW, listing the events of it that are missing; a feature-gated or not-yet-triggered autocmd lands here without anything being wrong",
  },
  {
    kinds = { ["autocmd-undocumented"] = true },
    title = "Autocmds registered through lib.nvim with no cheatsheet row",
    note = "only registrations that went through the helpers -- Neovim's own and a third-party plugin's are invisible here by construction, which is what keeps this direction answerable",
  },
  {
    kinds = { ["usercmd-undocumented"] = true },
    title = "Live commands with no cheatsheet, by origin",
    -- The note used to read "mostly third-party infra this corpus never
    -- covered", which was an apology for a column that could not tell the
    -- difference. It can now (see `command_owner`), and the honest split in
    -- the run that changed it was 53 ours to 56 theirs -- so the note says
    -- how to read the column instead of guessing at its contents.
    note = "an origin with a file:line is ours and wants a cheatsheet row; a bare plugin name is third-party infra this corpus never covered",
    -- Sorted by owner, not by name: this section is read to find out
    -- whether anything in it is *yours*, and clustering a plugin's dozen
    -- commands onto adjacent lines answers that in one glance.
    sort = function(a, b)
      local oa, ob = a.owner or "", b.owner or ""
      if oa ~= ob then
        return oa < ob
      end
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
---@param repo_info Bindings.RepoInfo|nil `M.check`'s fourth return value.
---With a scanned root it additionally carries what that path holds, which
---is what turns the report from "these plugins" into "this path".
---Omitted (nil) reads as "the repo axis was never asked for", which is what
---a pre-existing three-argument caller means.
---@param scope_info Bindings.ScopeInfo|nil `M.check`'s fifth return value.
---Omitted reads as "the default scope, nothing to explain", which is what a
---pre-existing four-argument caller means.
---@param autocmd_info Bindings.AutocmdInfo|nil `M.check`'s sixth return
---value: how much of the Autocmds corpus the axis could not reach, and how
---many registrations it had to compare against. Omitted prints no limit
---line, which is right for a caller that predates the axis.
---@return string[]
function M.describe(findings, skipped, source_reason, repo_info, scope_info, autocmd_info)
  local lines = {}

  -- Above everything, including "no drift found": if the config's own
  -- startup phases have not run, the counts below are not a measurement of
  -- the corpus, they are a measurement of an incompletely started Neovim.
  -- Same reasoning as the section order -- only the first screen is read --
  -- but one step earlier, because this decides whether the rest means
  -- anything at all.
  local pending = pending_phases()
  if pending and #pending > 0 then
    lines[#lines + 1] = ("!! %d startup phase%s of this config never ran: %s"):format(
      #pending,
      #pending == 1 and "" or "s",
      table.concat(pending, ", ")
    )
    lines[#lines + 1] = "  -- Their commands and keymaps are therefore NOT live, and every one of"
    lines[#lines + 1] = "  -- them is counted below as documented-but-not-registered. The findings"
    lines[#lines + 1] = "  -- are inflated; do not quote these numbers."
    lines[#lines + 1] =
      '  -- Usual cause: `nvim --headless -c "luafile ..."` runs the script before'
    lines[#lines + 1] =
      "  -- VimEnter, so the UIReady phase never fires. Run :Bindings check from a"
    lines[#lines + 1] = "  -- real session, or load the phase first. :StartupCheck lists them too."
    lines[#lines + 1] = ""
  end

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
        if section.kinds[f.kind] then
          matched[#matched + 1] = f
        end
      end
      if section.sort then
        table.sort(matched, section.sort)
      end
      local hits = {}
      for _, f in ipairs(matched) do
        hits[#hits + 1] = render(f)
      end
      if #hits > 0 then
        if #lines > 0 then
          lines[#lines + 1] = ""
        end
        lines[#lines + 1] = ("%s (%d)"):format(section.title, #hits)
        local note = section.note
        if type(note) == "function" then
          note = note(matched)
        end
        lines[#lines + 1] = ("  -- %s"):format(note)
        vim.list_extend(lines, hits)
      end
    end

    table.sort(order)
    if #order > 0 then
      local total = 0
      for _, key in ipairs(order) do
        total = total + unverifiable[key].n
      end
      if #lines > 0 then
        lines[#lines + 1] = ""
      end
      lines[#lines + 1] = ("Keymaps — not verifiable from here (%d in %d tables)"):format(
        total,
        #order
      )
      lines[#lines + 1] =
        "  -- not one key of these tables is live, globally or in any open buffer:"
      lines[#lines + 1] = "  -- a buffer-local scope whose UI is not open right now, not drift."
      lines[#lines + 1] =
        "  -- Open it and re-run, or :Bindings check <plugin> to list them in full."
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
  -- Before the axis notes: a count the reader cannot reconcile with the
  -- last run is the first thing they will ask about, and the answer is
  -- usually "you asked for a narrower scope", not a defect.
  if scope_info then
    if not scope_info.applied then
      lines[#lines + 1] = ""
      lines[#lines + 1] = ("Scope %q requested but NOT applied: %s"):format(
        scope_info.scope,
        scope_info.reason or "own/third-party split unavailable"
      )
      lines[#lines + 1] = "  -- every live undocumented command is listed, ours and theirs alike."
    elseif scope_info.hidden > 0 then
      lines[#lines + 1] = ""
      if scope_info.scope == "personal" then
        lines[#lines + 1] = ("Scope: personal -- %d third-party command%s not shown"):format(
          scope_info.hidden,
          scope_info.hidden == 1 and "" or "s"
        )
        lines[#lines + 1] =
          "  -- live, undocumented, and owned by a plugin this corpus does not cover."
        lines[#lines + 1] =
          "  -- :Bindings check extern lists exactly those; :Bindings check all lists both."
      else
        lines[#lines + 1] = ("Scope: extern -- %d of our own command%s not shown"):format(
          scope_info.hidden,
          scope_info.hidden == 1 and "" or "s"
        )
        lines[#lines + 1] = "  -- :Bindings check (no scope) is the one that reports those."
      end
    end
  end
  if source_reason then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Source axis not consulted: " .. source_reason
  end
  -- The narrowed value, not just a boolean about it: `repo_ran` says
  -- `repo_info` is non-nil, but a boolean carries none of that to the ten
  -- reads below. `repo_ran` itself stays -- one branch further down asks
  -- only whether the axis ran.
  local repo = (repo_info ~= nil and repo_info.ran == true) and repo_info or nil
  local repo_ran = repo ~= nil
  -- Reported whether or not `opts.repo` was given: since the source fallback
  -- runs by default, a resolver that cannot answer weakens the keymap
  -- section of EVERY run, not only of an opt-in one.
  if repo_info and repo_info.reason then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "No plugin checkout could be resolved: " .. repo_info.reason
    if not repo_ran then
      lines[#lines + 1] =
        "  -- the source fallback could not run either, so the keymap findings above"
      lines[#lines + 1] = "  -- are the live-only claim: not registered now, source unread."
    end
  end
  -- The number that reconciles this run with one from before the fallback
  -- existed. Without it, 48 findings simply disappear between two runs of
  -- the same command, which is the shape of a bug and not of an improvement.
  if repo_info and (repo_info.fallback_confirmed or 0) > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Confirmed by source instead of by the session (%d)"):format(
      repo_info.fallback_confirmed
    )
    lines[#lines + 1] =
      "  -- documented keys not registered right now, but written as a string literal in"
    lines[#lines + 1] =
      "  -- the plugin's checkout or this config's own lua/: buffer-local keys of a UI"
    lines[#lines + 1] = "  -- nobody has open. Not reported."
  end
  if repo and repo.root then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Repo root: %s -- %d Lua project%s found"):format(
      repo.root,
      #repo.resolved,
      #repo.resolved == 1 and "" or "s"
    )
  end
  if repo and #repo.checked > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Checked against their local checkout, not live (%d): %s"):format(
      #repo.checked,
      table.concat(repo.checked, ", ")
    )
  end
  -- Only reachable with a scanned root, see `M.check`. A checkout nobody
  -- wrote a cheatsheet for is not a drift finding -- there is no documented
  -- claim to be wrong about -- but it is the one thing a report over a whole
  -- path can say that a per-plugin report structurally cannot.
  if repo and #repo.undocumented > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("No cheatsheet under BINDINGS (%d): %s"):format(
      #repo.undocumented,
      table.concat(repo.undocumented, ", ")
    )
    lines[#lines + 1] =
      "  -- a checkout in this path that nothing in the corpus documents; not drift, just uncovered."
  end
  -- What the Autocmds axis could not look at, stated rather than left to be
  -- inferred from a small number. A row with no augroup column, or none whose
  -- events Neovim recognizes, is not checkable -- and eight sheets document
  -- their autocmds without ever naming a group in a column of its own.
  if autocmd_info and autocmd_info.unanchored > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Autocmds axis: %d documented row%s not checkable, %d registration%s attributable"):format(
      autocmd_info.unanchored,
      autocmd_info.unanchored == 1 and "" or "s",
      autocmd_info.registry,
      autocmd_info.registry == 1 and "" or "s"
    )
    lines[#lines + 1] = "  -- not checkable = the row names no augroup, or no event Neovim knows"
  end
  if skipped and #skipped > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Not loaded this session, skipped (%d): %s"):format(
      #skipped,
      table.concat(skipped, ", ")
    )
    -- The row count, not just the plugin count. A skipped plugin sounds
    -- like one thing missing from the report; 17 of them are 541 rows this
    -- run never looked at, and without the second number a small finding
    -- count reads as a verdict about the corpus. Same reasoning as the
    -- Autocmds axis' "not checkable" line above.
    if repo_info and (repo_info.skipped_rows or 0) > 0 then
      lines[#lines + 1] = ("  -- %d documented row%s belong to them and were not checked"):format(
        repo_info.skipped_rows,
        repo_info.skipped_rows == 1 and "" or "s"
      )
    end
    if not repo_ran then
      lines[#lines + 1] =
        "  -- :Bindings check repo additionally greps these plugins' local checkouts."
    end
  end
  return lines
end

return M
