---@module 'plugins.personal.source'
--- SOURCE CONTROL for the personal plugins: decides, per repo, whether it loads
--- locally ("dir"), from GitHub ("remote") or not at all ("disabled"), plus the
--- global OVERRIDE switch and machine-role handling.
---
--- Deliberately separate from plugins/personal/init.lua: this file is the
--- *policy* (which repo in which mode), init.lua is the *spec implementation*
--- (the actual lazy definitions). init.lua just does:
---   local plugins = require("plugins.personal.source")
---   plugins.add({ ...specs... })
---   return plugins.export()
---
--- Returns the configured plugins.control.mode instance (resolver + modes
--- already applied), ready for `add`/`export`.
---
--- NOTE: sibling of init.lua inside plugins/personal/. lazy's
--- `{ import = "plugins" }` only picks up personal/init.lua (one level deep),
--- never its siblings, so this file is not seen by the importer.

local personal_utils = require("plugins.personal.utils")
local machine = require("machine")
local notify = require("lib.nvim.notify").create("[plugins.personal]")
local control = require("plugins.control.mode")

---@alias PersonalRepoMode "disabled"|"dir"|"remote"
---  - "disabled" → don't load the repo at all (enabled = false)
---  - "dir"      → local, out of the repos directory (dir), falls back to remote if the folder is missing
---  - "remote"   → from GitHub (StefanBartl/...)

-- ── MANUAL SWITCH ──────────────────────────────────────────────────────────
-- Forces ONE source for ALL personal plugins, overriding both machine
-- detection and the MODE table further down -- EXCEPT for repos explicitly
-- set to "disabled" there: a disable always wins over this switch (a repo
-- you don't need at all should load neither locally nor remotely). For
-- debugging / switching, just set to "dir" or "remote" (or `:MyPlugins mode
-- <value>` -- writes exactly this line, see
-- lua/bindings/usrcmds/plugin_repos/init.lua; restart needed since require()
-- caches this file):
--   "auto"     → force nothing (machine role + MODE decide, see below)
--   "dir"      → ALL local
--   "remote"   → ALL from GitHub
--   "disabled" → ALL off
---@type "auto"|PersonalRepoMode
local OVERRIDE = "dir"

-- Resolves the effective source when OVERRIDE == "auto":
--   * "workstation" (see machine.lua) never has local checkouts of these
--     repos → everything "remote" (the dir fallback would also end up
--     remote, but this makes it unconditional and skips 25x isdirectory
--     checks).
--   * any other machine → "auto": the MODE table decides per repo.
-- Note: "remote" on the workstation means lazy manages every repo as a real
-- GitHub remote. The lazy update checker is therefore deliberately disabled
-- on the workstation (see lua/config/lazy/init.lua) -- otherwise it fetches
-- ~116 repos on every start and freezes the UI for 60-90s.
---@type "auto"|PersonalRepoMode
local SOURCE
if OVERRIDE ~= "auto" then
  SOURCE = OVERRIDE
elseif machine.is("workstation") then
  SOURCE = "remote"
else
  SOURCE = "auto"
end

local VALID_MODE = { disabled = true, dir = true, remote = true }

--- Personal resolver, injected into the generic core (plugins.control.mode).
--- A repo's own "disabled" always wins over OVERRIDE/SOURCE: a repo you
--- don't need at all should load neither locally nor remotely.
---@param spec LazyPluginSpec
---@param configured string|nil  from plugins.modes(...) for this basename
---@param name string            repo basename
local function resolve(spec, configured, name)
  -- Precedence: repo's own "disabled" > global OVERRIDE/SOURCE > repo's own dir/remote > default "dir".
  local mode = (configured == "disabled") and "disabled"
    or (SOURCE ~= "auto") and SOURCE
    or (configured or "dir")

  if not VALID_MODE[mode] then
    notify.warn(
      ("[PLUGINS PERSONAL] Invalid mode '%s' for '%s' → 'remote'"):format(tostring(mode), name)
    )
    mode = "remote"
  end

  if mode == "disabled" then
    spec.enabled = false
  elseif mode == "dir" then
    spec.dir = personal_utils.local_dev(name) -- nil → remote, if the folder is missing
  end
  -- "remote": dir stays nil → lazy uses repo[1]
end

local plugins = control.new({ resolve = resolve })

-- Per repo (key = folder/repo basename). Not listed → "dir".
plugins.modes({
  -- 1. CORE / INFRASTRUCTURE, UTILITIES & SYSTEM
  ["lib.nvim"] = "dir",
  ["lsp.nvim"] = "dir",
  ["sessions.nvim"] = "dir",
  ["pickers.nvim"] = "dir",
  ["buffer-ctx.nvim"] = "dir",
  ["open.nvim"] = "dir",
  ["sandbox.nvim"] = "dir",
  ["spotlight.nvim"] = "dir",
  ["documentation.nvim"] = "dir",
  ["runtime-analysis.nvim"] = "dir",

  -- 2. NAVIGATION, FILE SYSTEM, SEARCH & TREES
  ["fileops.nvim"] = "dir",
  ["gopath.nvim"] = "dir",
  ["replacer.nvim"] = "dir", -- basename of spec "StefanBartl/replacer.nvim"
  ["insights.nvim"] = "dir",
  ["filetree.nvim"] = "dir",
  ["reposcope.nvim"] = "dir",

  -- 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY
  ["debugging.nvim"] = "dir",
  ["dap.nvim"] = "dir",
  ["diff.nvim"] = "dir",
  ["language.nvim"] = "dir", -- basename of spec "StefanBartl/language.nvim"
  ["cmdlog.nvim"] = "dir",
  ["emojis.nvim"] = "dir",
  ["github_stats.nvim"] = "dir",
  ["casedesk.nvim"] = "dir",
  ["learn-cli.nvim"] = "disabled", -- needed neither locally nor remotely

  -- 4. FILE TYPES (MARKDOWN & DOCUMENTS)
  ["cascade.nvim"] = "dir",
  ["pdfport.nvim"] = "dir",
  ["markdown.nvim"] = "dir",
  ["color_my_ascii.nvim"] = "dir",
  ["recommender.nvim"] = "dir",
  ["mdview.nvim"] = "dir",
  ["images.nvim"] = "dir",
})

return plugins
