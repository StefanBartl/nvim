---@module 'config.telemetry'
--- Builds the `opts.telemetry` table `runtime-analysis.nvim`'s own plugin
--- spec (`plugins/personal/init.lua`) passes into `require("runtime-
--- analysis").setup(opts)`. The mechanism -- catch-up scan + `User
--- LazyLoad` autocmd, dispatch to `telemetry.auto()` / lib.nvim's
--- `lib.strategies.telemetry_wrap` -- lives in that plugin's own
--- `runtime-analysis.telemetry.lazy`; this file's only job is translating
--- *this config's* policy (which of Stefan's plugins, with what settings)
--- into the plain data shape that mechanism consumes.
---
--- The goal that policy is tuned for: switch it on once, forget about it,
--- and a week later read which functions actually ran and with which
--- arguments. That means two things beyond "it collects something":
---
---   * DEPTH. A plugin's `init.lua` is usually a thin façade over the modules
---     that hold the real code -- `require("markdown")` exposes 11 one-line
---     delegators while the 35 loaded `markdown.*` modules hold 125 functions,
---     and the ones its keymaps actually call live only in the latter. So
---     `deep = true` by default (wraps the whole loaded subtree, not just
---     the façade).
---   * ARGUMENTS. Counting alone answers "how often", not "with what". Argument
---     profiling is enabled per plugin by default, which is what turns the
---     report into "91 % of these calls pass the same path -> memoize".
---
--- COST. Argument profiling is ~40-60x counting alone but still well under a
--- microsecond per call (see `runtime-analysis.telemetry`'s own README for the
--- measured range -- reproducible via its `scripts/bench_overhead.lua`, not
--- restated here as single decimals). Nothing on a plugin's own surface
--- (keypresses/autocmds), but a real cost on `lib.tables.core`-style
--- primitives that run in loops -- why `profile_args` defaults on for
--- personal plugins but NOT for lib.nvim's aggregate (`lib_profile_args`,
--- default false).
---
--- KNOWN BLIND SPOT (verified). A keymap bound before the wrap ran closes over
--- the raw, uninstrumented function. This always costs the FIRST buffer of a
--- `ft`-gated plugin in a session (lazy.nvim's `FileType` handling runs before
--- its own `User LazyLoad`) -- mechanism + trigger:
--- wkdbook-Neovim/MyNotes/lazynvim-FileType-vor-User-LazyLoad-Timing.md.
---
--- Read with `:RATelemetry`, steer with `:RATelemetry disable <namespace>`.

local M = {}

--- Plugin lists accept either the short name (`"markdown.nvim"` — what the
--- namespace and `:RATelemetry` show) or the full repo
--- (`"StefanBartl/markdown.nvim"`). Both resolve to the same plugin, so a
--- reasonable guess cannot silently match nothing.
---@class Config.Telemetry.Opts
---@field deep? boolean|string[]          # wrap the whole loaded subtree (default true)
---@field profile_args? boolean|string[]  # record argument fingerprints (default true)
---@field timing? boolean|string[]        # record durations (default false)
---@field exclude? string[]               # plugins to skip entirely
---@field lib_profile_args? boolean       # arguments for lib.nvim's aggregate (default false)

---@type Config.Telemetry.Opts
local defaults = {
  deep = true,
  profile_args = true,
  timing = false,
  exclude = {},
  lib_profile_args = false,
}

---This config's own Lua tree, instrumented as an `opts.telemetry.extra`
---target -- runtime-analysis.nvim's own generic mechanism for a target no
---plugin manager can resolve (no repo, no spec, several unrelated root
---prefixes), not anything specific to this config. See that plugin's
---`docs/commands.md` §"Instrumenting your own Neovim config".
---
---Wrapped at VimEnter by the plugin itself (`wrap_at` default): when
---`runtime-analysis.setup()` runs it is still inside `lazy.setup()`, and
---`startup.now(...)`/`startup.on("UIReady", ...)` have not required most of
---these yet -- `wrap_loaded()` only ever sees what is already in
---`package.loaded`, so wrapping any earlier would measure almost nothing.
---
---`:RATelemetry setup nvim-config` / `:RATelemetry full nvim-config`
---re-wrap on demand, which is what picks up a submodule first required
---after that point (a `bindings/mappings/*` handler pulled in on first
---keypress).
local SELF_PREFIXES = {
  "config",
  "bindings",
  "plugins",
  "autocmds",
  "lsp",
  "startup",
  "themes",
  "machine",
  "nvchad",
  "wkdnvchad",
  "wkdoptions",
}

---`true` / `false` / a list of plugin names -> does it apply?
---
---A list entry matches either the short name (`"markdown.nvim"`) or the full
---repo (`"StefanBartl/markdown.nvim"`). The short name is what the namespace
---and every `:RATelemetry` report show, so it is the natural thing to write;
---accepting the repo too means copying a line out of the plugin spec also
---works instead of silently matching nothing.
---@param spec boolean|string[]|nil
---@param name string   # short name, e.g. "markdown.nvim"
---@param repo string   # full repo, e.g. "StefanBartl/markdown.nvim"
---@return boolean
local function applies(spec, name, repo)
  if spec == nil or spec == false then
    return false
  end
  if spec == true then
    return true
  end
  if type(spec) ~= "table" then
    return false
  end
  for _, want in ipairs(spec) do
    if want == name or want == repo then
      return true
    end
  end
  return false
end

---Build the `opts.telemetry` table for `runtime-analysis.nvim`'s own spec.
---
---Keyed by the FULL repo ("StefanBartl/dap.nvim"), not by a normalized name.
---The obvious-looking alternative -- `lazy.core.util.normname`, which strips
---"nvim-"/"vim-"/".nvim" and non-letters -- is actively wrong here, and
---silently so. It maps the *external* `mfussenegger/nvim-dap` and the
---*personal* `StefanBartl/dap.nvim` to the same key "dap", so nvim-dap's
---modules would be wrapped and reported under the "dap.nvim" namespace. With
---both loaded that is two instances writing one cache file: merged, wrong
---numbers, and nothing on screen saying so. (Verified, not hypothetical --
---firing a synthetic `LazyLoad` for "nvim-dap" produced exactly that
---instance.) The repo string is unique by construction and present on every
---personal spec; it also removes the need to special-case reposcope.nvim,
---whose spec sets `name = "reposcope"` -- `plugin[1]` is still the repo.
---@param opts? Config.Telemetry.Opts
---@return RA.Telemetry.LazyOpts
function M.build(opts)
  opts = vim.tbl_extend("force", defaults, opts or {})

  -- A plain data read of the already-built lazy spec table, no side
  -- effects (see that module's own doc-comment) -- safe from anywhere.
  local ok_list, entries = pcall(function()
    return require("plugins.personal.list").read()
  end)

  ---@type table<string, RA.Telemetry.LazyPluginOpts>
  local plugins = {}
  if ok_list and entries then
    for _, entry in ipairs(entries) do
      local excluded = vim.tbl_contains(opts.exclude, entry.name)
        or vim.tbl_contains(opts.exclude, entry.repo)
      if entry.name ~= "lib.nvim" and not excluded then
        plugins[entry.repo] = {
          namespace = entry.name,
          deep = applies(opts.deep, entry.name, entry.repo),
          profile_args = applies(opts.profile_args, entry.name, entry.repo),
          timing = applies(opts.timing, entry.name, entry.repo),
        }
      end
    end
  end

  ---@type table|false
  local lib_nvim = false
  if not vim.tbl_contains(opts.exclude, "lib.nvim") then
    lib_nvim = { profile_args = opts.lib_profile_args or nil }
  end

  return {
    plugins = plugins,
    lib_nvim = lib_nvim,
    extra = {
      {
        namespace = "nvim-config",
        mains = SELF_PREFIXES,
        profile_args = true,
        timing = false,
      },
    },
  }
end

return M
