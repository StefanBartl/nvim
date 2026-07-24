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
    add = function(list)
      for _, spec in ipairs(list) do
        specs[#specs + 1] = spec
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
