---@module 'plugins.personal.core.source'
--- SOURCE CONTROL for the personal plugins: decides, per repo, whether it loads
--- locally ("dir"), from GitHub ("remote") or not at all ("disabled"), plus the
--- global OVERRIDE switch and machine-role handling.
---
--- Deliberately separate from the specs (plugins/personal/specs/*.lua, one file
--- per category): this file is the *policy* (which repo in which mode), the
--- specs are the actual lazy definitions. plugins/personal/init.lua just does:
---   local plugins = require("plugins.personal.core.source")
---   plugins.add({ ...specs... })
---   return plugins.export()
---
--- Returns the configured plugins.control.mode instance (resolver + modes
--- already applied), ready for `add`/`export`.
---
--- NOTE: lives in plugins/personal/core/, below init.lua. lazy's
--- `{ import = "plugins" }` only picks up personal/init.lua (one level deep),
--- never anything below it, so this file is not seen by the importer.

local personal_utils = require("plugins.personal.core.utils")
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
--     remote, but this makes it unconditional and skips one isdirectory
--     check per repo).
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

-- Per repo (key = folder/repo basename). Not listed → "dir". Grouped by the
-- same categories as the spec files in plugins/personal/specs/ and the plugin
-- website's registry.
plugins.modes({
  -- foundation
  ["lib.nvim"] = "dir",
  -- The one PRIVATE repo in this list: "remote" would have lazy clone
  -- https://github.com/StefanBartl/my.nvim, which fails without credentials.
  -- Gated on the *effective* SOURCE, not the raw machine role, so a local
  -- checkout is still used whenever OVERRIDE forces anything but "remote".
  ["my.nvim"] = (SOURCE == "remote") and "disabled" or "dir",

  -- ai
  ["ai.nvim"] = "dir",
  ["buffer-ctx.nvim"] = "dir",

  -- edit
  ["cascade.nvim"] = "dir",
  ["replacer.nvim"] = "dir",
  ["emojis.nvim"] = "dir",
  ["language.nvim"] = "dir",
  ["markdown.nvim"] = "dir",
  ["data.nvim"] = "dir",

  -- navigate
  ["gopath.nvim"] = "dir",
  ["hover.nvim"] = "dir",
  ["open.nvim"] = "dir",
  ["pickers.nvim"] = "dir",
  ["filetree.nvim"] = "dir",
  ["fileops.nvim"] = "dir",
  ["sessions.nvim"] = "dir",

  -- inspect
  ["dap.nvim"] = "dir",
  ["debugging.nvim"] = "dir",
  ["diff.nvim"] = "dir",
  ["lsp.nvim"] = "dir",
  ["insights.nvim"] = "dir",
  ["runtime-analysis.nvim"] = "dir",
  ["recommender.nvim"] = "dir",
  ["spotlight.nvim"] = "dir",
  ["cmdlog.nvim"] = "dir",
  ["rules.nvim"] = "dir",

  -- project
  ["sandbox.nvim"] = "dir",
  ["github_stats.nvim"] = "dir",
  ["reposcope.nvim"] = "dir",
  ["documentation.nvim"] = "dir",
  ["gitsuite.nvim"] = "dir",
  ["casedesk.nvim"] = "dir",
  ["learn-cli.nvim"] = "disabled", -- needed neither locally nor remotely

  -- view
  ["ui.nvim"] = "dir",
  ["color_my_ascii.nvim"] = "dir",
  ["images.nvim"] = "dir",
  ["mdview.nvim"] = "dir",
  ["media.nvim"] = "dir",
  ["pdfport.nvim"] = "dir",
})

return plugins
