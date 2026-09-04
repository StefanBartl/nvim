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
---  - "disabled" → Repo gar nicht laden (enabled = false)
---  - "dir"      → lokal aus dem repos-Verzeichnis (dir), Fallback remote falls Ordner fehlt
---  - "remote"   → von GitHub (StefanBartl/...)

-- ── MANUELLER SCHALTER ─────────────────────────────────────────────────────
-- Erzwingt EINE Quelle für ALLE personal-Plugins und übersteuert sowohl die
-- Maschinen-Erkennung als auch die MODE-Tabelle weiter unten - AUSSER für
-- Repos, die dort explizit auf "disabled" stehen: eine Deaktivierung gewinnt
-- immer, unabhängig von diesem Schalter (ein Repo, das man gar nicht braucht,
-- soll weder lokal noch remote geladen werden). Zum Debuggen / Umschalten
-- einfach auf "dir" oder "remote" setzen (oder `:MyPlugins mode <wert>` -
-- schreibt exakt diese Zeile, s. lua/bindings/usrcmds/plugin_repos/init.lua; Neustart
-- nötig, da require() diese Datei cached):
--   "auto"     → nichts erzwingen (Maschinenrolle + MODE entscheiden, s. u.)
--   "dir"      → ALLE lokal
--   "remote"   → ALLE von GitHub
--   "disabled" → ALLE aus
---@type "auto"|PersonalRepoMode
local OVERRIDE = "dir"

-- Auflösung der effektiven Quelle, wenn OVERRIDE == "auto":
--   * "workstation" (siehe machine.lua) hat nie lokale Checkouts
--     dieser Repos → alles "remote" (der dir-Fallback ginge zwar auch remote,
--     das hier macht es unbedingt und spart 25× isdirectory-Prüfungen).
--   * jede andere Maschine → "auto": pro Repo entscheidet die MODE-Tabelle.
-- Achtung: "remote" auf der workstation heißt, dass lazy alle Repos als echte
-- GitHub-Remotes verwaltet. Der lazy-Update-Checker ist deshalb auf der
-- workstation bewusst deaktiviert (siehe lua/config/lazy/init.lua), sonst
-- fetcht er bei jedem Start ~116 Repos und friert die UI 60-90s ein.
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

--- Personal-Resolver, in den generischen Kern (plugins.control.mode) injiziert.
--- Ein repo-eigenes "disabled" gewinnt immer über OVERRIDE/SOURCE: ein Repo,
--- das man gar nicht braucht, soll weder lokal noch remote laden.
---@param spec LazyPluginSpec
---@param configured string|nil  aus plugins.modes(...) für diesen Basenamen
---@param name string            Repo-Basename
local function resolve(spec, configured, name)
  -- Präzedenz: repo-eigenes "disabled" > globales OVERRIDE/SOURCE > repo-eigenes dir/remote > Default "dir".
  local mode = (configured == "disabled") and "disabled"
    or (SOURCE ~= "auto") and SOURCE
    or (configured or "dir")

  if not VALID_MODE[mode] then
    notify.warn(
      ("[PLUGINS PERSONAL] Ungültiger Modus '%s' für '%s' → 'remote'"):format(
        tostring(mode),
        name
      )
    )
    mode = "remote"
  end

  if mode == "disabled" then
    spec.enabled = false
  elseif mode == "dir" then
    spec.dir = personal_utils.local_dev(name) -- nil → remote, falls Ordner fehlt
  end
  -- "remote": dir bleibt nil → lazy nutzt repo[1]
end

local plugins = control.new({ resolve = resolve })

-- Pro Repo (Key = Ordner-/Repo-Basename). Nicht gelistet → "dir".
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
  ["replacer.nvim"] = "dir", -- Basename des Specs "StefanBartl/replacer.nvim"
  ["insights.nvim"] = "dir",
  ["filetree.nvim"] = "dir",
  ["reposcope.nvim"] = "dir",

  -- 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY
  ["debugging.nvim"] = "dir",
  ["dap.nvim"] = "dir",
  ["diff.nvim"] = "dir",
  ["language.nvim"] = "dir", -- Basename des Specs "StefanBartl/language.nvim"
  ["cmdlog.nvim"] = "dir",
  ["emojis.nvim"] = "dir",
  ["github_stats.nvim"] = "dir",
  ["casedesk.nvim"] = "dir",
  ["learn-cli.nvim"] = "disabled", -- gebraucht weder lokal noch remote

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
