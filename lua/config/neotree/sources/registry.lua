-- lua/config/neotree/sources/registry.lua
---@module 'config.neotree.sources.registry'

local notify = require("lib.nvim.notify").create("[config.neotree.sources.registry]")

local M = {}

---@type table<string, Cfg.NeoTree.Sources.SourceDef>
local sources = {}

---Register a source for lazy loading
---@param name string
---@param loader fun(): table
---@param config table|nil
function M.register(name, loader, config)
  sources[name] = {
    name = name,
    loader = loader,
    loaded = false,
    config = config or {},
  }
end

---Load a source on-demand
---@param name string
---@return table|nil source
function M.load(name)
  local def = sources[name]
  if not def then
    notify.error(string.format("Unknown source: %s", name))
    return nil
  end

  if def.loaded then
    return def.source
  end

  local ok, source = pcall(def.loader)
  if not ok then
    notify.error(string.format("Failed to load source %s: %s", name, source))
    return nil
  end

  def.source = source
  def.loaded = true

  notify.info(string.format("Loaded source: %s", name))
  return source
end

---Check if source is loaded
---@param name string
---@return boolean
function M.is_loaded(name)
  return sources[name] and sources[name].loaded or false
end

---Get all registered sources
---@return string[]
function M.list()
  local names = {}
  for name, _ in pairs(sources) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

return M
