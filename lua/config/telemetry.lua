---@module 'config.telemetry'
--- Activates runtime-analysis.telemetry (moved there from lib.nvim) for
--- lib.nvim itself and every personal plugin.
---
--- The goal this is tuned for: switch it on once, forget about it, and a week
--- later read which functions actually ran and with which arguments. That
--- means two things beyond "it collects something":
---
---   * DEPTH. A plugin's `init.lua` is usually a thin façade over the modules
---     that hold the real code -- `require("markdown")` exposes 11 one-line
---     delegators while the 35 loaded `markdown.*` modules hold 125 functions,
---     and the ones its keymaps actually call live only in the latter.
---     Wrapping the façade would measure the façade. So each plugin is wrapped
---     via `telemetry.auto({ deep = true, ... })`, which registers the whole
---     loaded subtree without `require`-ing anything itself (no forced eager
---     loads, lazy-loading plugins stay lazy).
---   * ARGUMENTS. Counting alone answers "how often", not "with what". Argument
---     profiling is enabled per plugin, which is what turns the report into
---     "91 % of these calls pass the same path -> memoize".
---
--- COST (measured, 200k calls, this machine)
---   counting only          0.014 us/call
---   counting + arguments   0.619 us/call   (~44x)
---   counting + timing      0.394 us/call
---
--- 0.6 us on a plugin's own surface is nothing -- those functions run on
--- keypresses and autocmds, not in inner loops. That is why `profile_args`
--- defaults to on for personal plugins but NOT for lib.nvim's aggregate:
--- `lib.strategies.telemetry_wrap` (lib.nvim's own thin caller onto this
--- module, instrumenting `require("lib")` specifically) covers
--- `lib.tables.core`-style primitives that genuinely do run in loops, where
--- 0.6 us per call is a real cost for an answer nobody asked. Timing is off
--- by default for the same reason and because "how often" was the question,
--- not "how long".
---
--- MECHANISM
--- No per-plugin boilerplate and no hardcoded module-name guessing: this reuses
--- lazy.nvim's OWN module resolution (`lazy.core.loader.get_main`), the same
--- lookup lazy.nvim uses to call `require(main).setup(opts)` for plugins that
--- only declare `opts = {...}`. Guessing wrong (e.g. dap.nvim's Lua module is
--- "wkddap", not "dap") would wrap nothing, or `require()` a name that does not
--- exist -- so borrowing lazy's answer beats re-deriving it.
---
--- MUST be called before `require("lazy").setup(...)`, not from init.lua's
--- later `startup.now(...)`/`startup.on(...)` phases. `User LazyLoad` fires
--- once per plugin the moment ITS OWN config() finishes -- for every
--- `lazy=false` plugin (lib.nvim, sessions.nvim, insights.nvim, cmdlog.nvim)
--- that happens DURING the `lazy.setup()` call itself, so an autocmd
--- registered after that call returns would never see those events. lib.nvim
--- is already on `package.path` by then (init.lua's bootstrap block).
---
--- KNOWN BLIND SPOT (verified, not theoretical)
--- A keymap that captured a function reference before the wrap holds the raw
--- function and is invisible. For `ft`-triggered plugins this permanently
--- affects the FIRST buffer of a session: lazy.nvim runs the plugin's FileType
--- handlers -- which bind the keymaps -- BEFORE `User LazyLoad` fires, so even
--- the earliest possible hook is too late for that one buffer. Every buffer
--- after it is instrumented normally. Irrelevant for week-long counting;
--- confusing if you press a key once and expect the counter to move.
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

---Resolve this plugin's settings against `opts`, then hand off to
---`runtime-analysis.telemetry.auto()` for the actual new()+wrap()+start().
---That helper owns the "is anything of `main` loaded yet" check (returns
---nil if not, so no empty namespace is left cluttering `:RATelemetry`) and
---the deep/shallow wrap mechanics; this function's whole job is translating
---*our* per-plugin policy into its generic opts shape.
---@param opts Config.Telemetry.Opts
---@param namespace string
---@param repo string
---@param main string   # the plugin's root Lua module, per lazy.nvim
---@return RA.Telemetry.Instance|nil
local function wrap_and_start(opts, namespace, repo, main)
  return require("runtime-analysis.telemetry").auto({
    namespace = namespace,
    main = main,
    deep = applies(opts.deep, namespace, repo),
    profile_args = applies(opts.profile_args, namespace, repo),
    timing = applies(opts.timing, namespace, repo),
  })
end

---@param opts? Config.Telemetry.Opts
function M.setup(opts)
  opts = vim.tbl_extend("force", defaults, opts or {})

  local ok_telemetry = pcall(require, "runtime-analysis.telemetry")
  if not ok_telemetry then
    return
  end

  pcall(function()
    require("runtime-analysis.telemetry.command").setup()
  end)

  -- `plugins.personal.list` only reads the already-built lazy spec table (a
  -- plain data read, no side effects -- see its own doc-comment), so calling
  -- it before `lazy.setup()` runs is safe.
  local ok_list, entries = pcall(function()
    return require("plugins.personal.list").read()
  end)
  if not ok_list or not entries then
    return
  end

  -- Keyed by the FULL repo ("StefanBartl/dap.nvim"), not by a normalized name.
  --
  -- The obvious-looking alternative -- `lazy.core.util.normname`, which strips
  -- "nvim-"/"vim-"/".nvim" and non-letters -- is actively wrong here, and
  -- silently so. It maps the *external* `mfussenegger/nvim-dap` and the
  -- *personal* `StefanBartl/dap.nvim` to the same key "dap", so nvim-dap's
  -- modules would be wrapped and reported under the "dap.nvim" namespace.
  -- With both loaded that is two instances writing one cache file: merged,
  -- wrong numbers, and nothing on screen saying so. (Verified, not
  -- hypothetical -- firing a synthetic `LazyLoad` for "nvim-dap" produced
  -- exactly that instance.)
  --
  -- The repo string is unique by construction, carries the owner, and is
  -- present on every personal spec. It also removes the need to special-case
  -- reposcope.nvim, whose spec sets `name = "reposcope"`: the LazyLoad event
  -- carries that override, but `plugin[1]` is still the repo.
  ---@type table<string, { name: string, repo: string }>
  local wanted = {}
  for _, entry in ipairs(entries) do
    local excluded = vim.tbl_contains(opts.exclude, entry.name)
      or vim.tbl_contains(opts.exclude, entry.repo)
    if entry.name ~= "lib.nvim" and not excluded then
      wanted[entry.repo] = { name = entry.name, repo = entry.repo }
    end
  end

  ---@type table<string, boolean>
  local started = {}

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyLoad",
    group = vim.api.nvim_create_augroup("config_telemetry_lazyload", { clear = true }),
    desc = "config.telemetry: wrap+start a telemetry instance for each personal plugin as it loads",
    callback = function(args)
      local plugin_name = args.data
      if type(plugin_name) ~= "string" or started[plugin_name] then
        return
      end

      if plugin_name == "lib.nvim" then
        if vim.tbl_contains(opts.exclude, "lib.nvim") then
          return
        end
        started[plugin_name] = true
        pcall(function()
          local telemetry = require("runtime-analysis.telemetry")
          local t = telemetry.new({ namespace = "lib.nvim" })
          -- The aggregate, not the loaded subtree: `wrap_loaded("lib")` would
          -- reach every internal helper in a ~250-file library, and the
          -- question worth asking of lib.nvim is which of its PUBLIC keys get
          -- used -- which is exactly what the aggregate is. lib.nvim's own
          -- thin caller knows how to reach it (metatable-hidden until
          -- touched; see lib.strategies.telemetry_wrap's doc-comment).
          require("lib.strategies.telemetry_wrap").wrap(t)
          t.start({ profile_args = opts.lib_profile_args or nil })
        end)
        return
      end

      pcall(function()
        local plugin = require("lazy.core.config").plugins[plugin_name]
        if not plugin then
          return
        end

        -- `plugin[1]` is the repo as declared in the spec. Anything without
        -- one (a bare `dir = ...` entry) is not a personal plugin of ours.
        local target = type(plugin[1]) == "string" and wanted[plugin[1]] or nil
        if not target then
          return
        end
        local main = require("lazy.core.loader").get_main(plugin)
        if not main then
          return
        end
        -- Only mark as started once something was actually wrapped -- auto()
        -- returns nil if nothing of `main` is loaded yet, and a LazyLoad that
        -- fires again later for the same plugin (uncommon, but not
        -- impossible) should get another chance rather than being silently
        -- skipped forever.
        if wrap_and_start(opts, target.name, target.repo, main) then
          started[plugin_name] = true
        end
      end)
    end,
  })
end

return M
