---@module 'config.telemetry'
--- Activates lib.nvim.telemetry for lib.nvim itself and every personal plugin.
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
---     via `wrap_loaded(<main module>)`, which registers the whole loaded
---     subtree without `require`-ing anything itself (no forced eager loads,
---     lazy-loading plugins stay lazy).
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
--- `wrap_lib()` covers `lib.tables.core`-style primitives that genuinely do
--- run in loops, where 0.6 us per call is a real cost for an answer nobody
--- asked. Timing is off by default for the same reason and because "how often"
--- was the question, not "how long".
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
--- Read with `:LibTelemetry`, steer with `:LibTelemetry disable <namespace>`.

local M = {}

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

---`true` / `false` / a list of plugin names -> does it apply to `name`?
---@param spec boolean|string[]|nil
---@param name string
---@return boolean
local function applies(spec, name)
  if spec == nil or spec == false then
    return false
  end
  if spec == true then
    return true
  end
  if type(spec) == "table" then
    return vim.tbl_contains(spec, name)
  end
  return false
end

---@param opts Config.Telemetry.Opts
---@param namespace string
---@param main string   # the plugin's root Lua module, per lazy.nvim
local function wrap_and_start(opts, namespace, main)
  local telemetry = require("lib.nvim.telemetry")
  local t = telemetry.new({ namespace = namespace })

  if applies(opts.deep, namespace) then
    t.wrap_loaded(main, {
      -- `@types` modules are pure LuaCATS annotation scaffolding; anything
      -- callable in them is a stub. Counting those is noise in every report.
      module_filter = function(name)
        return not name:find("@types", 1, true)
      end,
    })
  else
    t.wrap(package.loaded[main])
  end

  t.start({
    profile_args = applies(opts.profile_args, namespace) or nil,
    time = applies(opts.timing, namespace) or nil,
  })
end

---@param opts? Config.Telemetry.Opts
function M.setup(opts)
  opts = vim.tbl_extend("force", defaults, opts or {})

  local ok_telemetry = pcall(require, "lib.nvim.telemetry")
  if not ok_telemetry then
    return
  end

  pcall(function()
    require("lib.nvim.telemetry.command").setup()
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

  -- `lazy.core.util.normname` is what lazy.nvim itself uses to match a
  -- plugin's declared name against the module names it finds on disk (it
  -- strips "nvim-"/"vim-"/".nvim"/".lua" and non-letters) -- exactly the
  -- normalization needed to bridge cases like reposcope.nvim, whose spec sets
  -- `name = "reposcope"`: the LazyLoad event carries that override, not the
  -- repo-derived "reposcope.nvim" this list reads. Both normalize alike.
  local normname = require("lazy.core.util").normname

  ---@type table<string, string> normalized name -> namespace to use
  local wanted = {}
  for _, entry in ipairs(entries) do
    if entry.name ~= "lib.nvim" and not vim.tbl_contains(opts.exclude, entry.name) then
      wanted[normname(entry.name)] = entry.name
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
          local telemetry = require("lib.nvim.telemetry")
          local t = telemetry.new({ namespace = "lib.nvim" })
          -- The aggregate, not the loaded subtree: `wrap_loaded("lib")` would
          -- reach every internal helper in a ~250-file library, and the
          -- question worth asking of lib.nvim is which of its PUBLIC keys get
          -- used -- which is exactly what the aggregate is.
          t.wrap_lib()
          t.start({ profile_args = opts.lib_profile_args or nil })
        end)
        return
      end

      local namespace = wanted[normname(plugin_name)]
      if not namespace then
        return
      end
      started[plugin_name] = true

      pcall(function()
        local plugin = require("lazy.core.config").plugins[plugin_name]
        if not plugin then
          return
        end
        local main = require("lazy.core.loader").get_main(plugin)
        if not main or type(package.loaded[main]) ~= "table" then
          return
        end
        wrap_and_start(opts, namespace, main)
      end)
    end,
  })
end

return M
