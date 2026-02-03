---@module 'config.neotest.init.utils'

local M = {}

----------------------------------------------------------------------
-- Adapter-Handling
----------------------------------------------------------------------

--- Lädt die sprachspezifische Neotest-Konfiguration, falls vorhanden.
---@param lang string
---@return table|nil
local function load_language_config(lang)
  local ok, cfg = pcall(require, "config.neotest.adapters." .. lang)
  if not ok then
    return nil
  end
  return cfg
end

--- Erstellt die finale Adapter-Liste basierend auf verfügbaren Modulen.
---@return table[] adapters
function M.build_adapters()
  ---@type string[]
  local languages = {
    "lua",
    "typescript",
    "javascript",
    "go",
    "bash",
    "rust",
    "c_cpp",
    "zig",
    "assembly",
    "python",
    "wasm",
  }

  ---@type table[]
  local adapters = {}

  for i = 1, #languages do
    local cfg = load_language_config(languages[i])
    if cfg and cfg.adapter then
      adapters[#adapters + 1] = cfg.adapter
    end
  end

  return adapters
end

----------------------------------------------------------------------
-- Consumer-Handling (Neo-tree)
----------------------------------------------------------------------

--- Erstellt optionale Neotest-Consumer.
---@return table<string, function>
function M.build_consumers()
  local consumers = {}

  -- KORREKTUR: Direkter Import ohne .setup()
  local ok, neotree_consumer = pcall(require, "neotest.consumers.neotree")
  if ok and type(neotree_consumer) == "function" then
    consumers.neotree = neotree_consumer
  end

  return consumers
end

return M
