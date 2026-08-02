---@module 'plugins.control.mode'
--- Per-file plugin mode control for lua/plugins/**. Each spec file creates one
--- instance, declares a small `modes` table at the top (repo basename -> mode)
--- instead of setting `enabled = false` / `dir = ...` inside each individual
--- spec, registers its specs, and exports the resulting list for lazy.
---
--- The core only knows the *shape* (basename -> mode string). What a mode
--- *does* is decided by a resolver:
---   * default resolver → only "disabled" has an effect (turns the spec off).
---   * plugins.personal injects its own resolver that additionally handles
---     "dir"/"remote" and the SOURCE/OVERRIDE switch (see plugins.personal.init).
--- So there is a single mode list per file; "disabled" is just one value in it,
--- never a separate on/off table.
---
--- NOTE ON PLACEMENT: this file is deliberately NOT `init.lua`. lazy's
--- `{ import = "plugins" }` (see init.lua) imports every `plugins/<dir>/init.lua`
--- one level deep and normalizes the return value as a plugin spec. A folder
--- WITHOUT an init.lua is skipped entirely, which is exactly what we want for a
--- helper module - keep plugins/control/ free of init.lua.

local M = {}

---@alias PluginMode "disabled"|"dir"|"remote"

---@class Plugins.Control.ModeApi
---@field modes fun(t: table<string, string>): Plugins.Control.ModeApi
---@field add fun(list: LazyPluginSpec[]): Plugins.Control.ModeApi
---@field export fun(): LazyPluginSpec[]

--- Default resolver used by every non-personal spec file: only "disabled"
--- has an effect, everything else is left untouched (third-party plugins are
--- always remote-managed by lazy anyway - no dir/remote handling needed here).
---@param spec LazyPluginSpec
---@param mode string|nil
local function default_resolve(spec, mode)
  if mode == "disabled" then
    spec.enabled = false
  end
end

--- Create a new per-file mode-control instance.
---@param opts? { resolve?: fun(spec: LazyPluginSpec, mode: string|nil, name: string) }
---@return Plugins.Control.ModeApi
function M.new(opts)
  local modes = {} ---@type table<string, string>
  local specs = {} ---@type LazyPluginSpec[]
  local index_by_repo = {} ---@type table<string, integer>
  local resolve = (opts and opts.resolve) or default_resolve

  ---@type Plugins.Control.ModeApi
  local api
  api = {
    --- Declare per-repo modes (Key = Ordner-/Repo-Basename). Merges into the
    --- existing table, so it may be called more than once. Chainable.
    modes = function(t)
      for name, mode in pairs(t) do
        modes[name] = mode
      end
      return api
    end,

    --- Register this file's plugin specs. Chainable.
    ---
    --- IDEMPOTENT PER REPO, and that is load-bearing rather than tidiness.
    --- This instance lives in a module-level closure of the *calling* spec
    --- file's helper (e.g. plugins.personal.source), which `require` caches --
    --- but the spec file itself is evaluated more than once per session:
    --- lazy's `{ import = "plugins" }` loads it through lazy's own importer,
    --- while a later `require("plugins.personal")` from ordinary Lua code is a
    --- separate cache key and re-runs the file. Each evaluation called `add()`
    --- again on the SAME accumulated list, so `specs` grew by one full set
    --- every time -- measured at 84 entries for 28 plugins (3x).
    ---
    --- That was visible in three places: the statusline's own/external badge
    --- counted 81 personal plugins instead of 27, `:MyPluginsClone` iterated
    --- (and progress-reported) every repo three times, and
    --- `:MyPluginsRemove` listed each candidate three times in its
    --- confirmation. lazy itself was unaffected -- it merges same-name specs
    --- into one plugin -- but it was doing three times the merging.
    ---
    --- Re-registering replaces in place rather than being ignored, so a
    --- genuine second registration with changed content still wins while a
    --- re-evaluation of identical content is a true no-op. A spec with no
    --- `[1]` repo string (a bare `dir = ...` entry) has no identity to dedupe
    --- on and is always appended.
    add = function(list)
      for _, spec in ipairs(list) do
        local repo = spec[1]
        local at = type(repo) == "string" and index_by_repo[repo] or nil
        if at then
          specs[at] = spec
        else
          specs[#specs + 1] = spec
          if type(repo) == "string" then
            index_by_repo[repo] = #specs
          end
        end
      end
      return api
    end,

    --- Apply the declared modes to every registered spec and return the list
    --- for lazy. Call this as the file's `return`.
    export = function()
      for _, spec in ipairs(specs) do
        local repo = spec[1]
        if type(repo) == "string" then
          local name = vim.fn.fnamemodify(repo, ":t")
          resolve(spec, modes[name], name)
        end
      end
      return specs
    end,
  }
  return api
end

return M
