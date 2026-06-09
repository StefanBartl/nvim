---@module 'custom.dir_picker.config'
---@brief Module-local configuration with user-overridable defaults.

---@type DirPickerConfig
local defaults = {
  default_engine = "telescope",
  fallback_engine = "fzf",
  -- Named alias resolvers: each returns an absolute path string
  depth_aliases = {
    cwd  = function() return vim.uv.cwd() or vim.fn.getcwd() end,
    home = function() return vim.uv.os_homedir() or vim.fn.expand("~") end,
    root = function()
      -- Walk upward until the parent equals the current path (i.e. filesystem root)
      local path = vim.uv.cwd() or vim.fn.getcwd()
      while true do
        local parent = vim.fs.dirname(path)
        if parent == path then return path end
        path = parent
      end
    end,
    git = function()
      -- Walk upward to find the nearest .git directory; fall back to CWD
      local found = vim.fs.find(".git", {
        upward = true,
        type   = "directory",
        path   = vim.uv.cwd() or vim.fn.getcwd(),
      })
      if found and found[1] then
        return vim.fs.dirname(found[1])
      end
      return vim.uv.cwd() or vim.fn.getcwd()
    end,
  },
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
