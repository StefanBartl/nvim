---@module 'config.telemetry'
--- Activates lib.nvim.telemetry (counting only, no argument profiling) for:
---
---   1. lib.nvim itself      -- namespace "lib.nvim", via wrap_lib()
---   2. every personal plugin -- namespace = the plugin's lazy.nvim name,
---      wrapped generically right after lazy.nvim finishes that plugin's own
---      config(), whatever its load trigger (lazy=false / event / cmd / ft)
---
--- No per-plugin boilerplate and no hardcoded module-name guessing: this
--- reuses lazy.nvim's OWN module resolution (`lazy.core.loader.get_main`),
--- the same lookup lazy.nvim itself uses to call `require(main).setup(opts)`
--- for plugins that only declare `opts = {...}`. Guessing wrong here (e.g.
--- dap.nvim's Lua module is "wkddap", not "dap") would either wrap nothing
--- or, worse, `require()` a name that doesn't exist -- so borrowing lazy's
--- own answer instead of re-deriving it is the whole point.
---
--- MUST be called before `require("lazy").setup(...)`, not from the later
--- `startup.now(...)`/`startup.on(...)` phases in init.lua. `User LazyLoad`
--- fires once per plugin the moment ITS OWN config() finishes -- for every
--- `lazy=false` plugin (lib.nvim, sessions.nvim, insights.nvim, cmdlog.nvim,
--- learn-cli.nvim) that happens DURING the `lazy.setup()` call itself. An
--- autocmd registered after that call returns would simply never see those
--- events. lib.nvim is already on `package.path` before `lazy.setup()` runs
--- (see init.lua's bootstrap block), so requiring it here is safe.
---
--- Review with :LibTelemetry, stop with :LibTelemetry stop -- both work
--- across every namespace this activates, since telemetry.instances()
--- enumerates all of them regardless of who created each one.

local M = {}

---@param namespace string
---@param mod table
local function wrap_and_start(namespace, mod)
  local telemetry = require("lib.nvim.telemetry")
  local t = telemetry.new({ namespace = namespace })
  t.wrap(mod)
  t.start()
end

function M.setup()
  local ok_telemetry = pcall(require, "lib.nvim.telemetry")
  if not ok_telemetry then
    return
  end

  pcall(function()
    require("lib.nvim.telemetry.command").setup()
  end)

  -- Personal plugins whose main module gets wrapped generically. Read once,
  -- up front: `plugins.personal.list` only reads the already-built lazy spec
  -- table (a plain data read, no side effects -- see that module's own
  -- doc-comment), so calling it before `lazy.setup()` runs is safe.
  local ok_list, entries = pcall(function()
    return require("plugins.personal.list").read()
  end)
  if not ok_list or not entries then
    return
  end

  -- `lazy.core.util.normname` is what lazy.nvim itself uses to match a
  -- plugin's declared name against the module names it finds on disk (it
  -- strips "nvim-"/"vim-"/".nvim"/".lua" and non-letters) -- exactly the
  -- normalization needed to bridge cases like reposcope.nvim, whose spec
  -- sets `name = "reposcope"`: `data` on the LazyLoad autocmd is that
  -- override ("reposcope"), not the repo-derived "reposcope.nvim" this list
  -- reads. Both normalize to the same key, so the match still works without
  -- this file knowing about the override.
  local normname = require("lazy.core.util").normname

  ---@type table<string, string> normalized name -> namespace to use
  local wanted = {}
  for _, entry in ipairs(entries) do
    if entry.name ~= "lib.nvim" then
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
        started[plugin_name] = true
        pcall(function()
          local telemetry = require("lib.nvim.telemetry")
          local t = telemetry.new({ namespace = "lib.nvim" })
          t.wrap_lib()
          t.start()
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
        wrap_and_start(namespace, package.loaded[main])
      end)
    end,
  })
end

return M
