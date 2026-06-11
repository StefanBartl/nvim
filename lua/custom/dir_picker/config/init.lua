---@module 'custom.dir_picker.config'
---@brief Module-local configuration with user-overridable defaults.

local depth_aliases = require("custom.dir_picker.config.aliases")

---@type DirPickerConfig
local defaults = {
  default_engine = "telescope",
  fallback_engine = "fzf",
  -- Named alias resolvers: each returns an absolute path string
  depth_aliases = depth_aliases,
}

-- Module-local active config — never exposed as global state
local M = {}
local _cfg = vim.deepcopy(defaults)

--- Returns the active configuration table.
---@return DirPickerConfig
function M.get()
  return _cfg
end

--- Merges a user-provided options table into the active configuration.
--- Only known top-level keys are accepted; unknown keys are silently ignored.
---@param opts DirPickerConfig|nil
---@return nil
function M.apply(opts)
  if type(opts) ~= "table" then return end

  if type(opts.default_engine) == "string" then
    _cfg.default_engine = opts.default_engine
  end
  if type(opts.fallback_engine) == "string" then
    _cfg.fallback_engine = opts.fallback_engine
  end
  if type(opts.depth_aliases) == "table" then
    for k, v in pairs(opts.depth_aliases) do
      if type(k) == "string" and type(v) == "function" then
        _cfg.depth_aliases[k] = v
      end
    end
  end
end

return M
