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

-- ---@alias NeoTest.Consumers fun(client: NeoTest.Client): table
---@toc_entry Neotest Client
---@text
--- The neotest client is the core of neotest, it communicates with adapters,
--- running tests and collecting results.
--- Most of the client methods are async and so need to be run in an async
--- context (i.e. `require("nio").run(function() ... end))
--- The client starts lazily, meaning that no parsing of tests will be performed
--- until it is required. Care should be taken to not use the client methods on
--- start because it can slow down startup.
-- ---@class NeoTest.Client
-- ---@field private _started boolean
-- ---@field private _state NeoTest.ClientState
-- ---@field private _events NeoTest.EventProcessor
-- ---@field private _adapters table<string, NeoTest.Adapter>
-- ---@field private _adapter_group NeoTest.AdapterGroup
-- ---@field private _runner NeoTest.TestRunner
-- ---@field listeners NeoTest.ConsumerListeners

--- Erstellt optionale Neotest-Consumer.
---@return table<string, function>
function M.build_consumers()
  local consumers = {}

  local ok, neotree_consumer_m = pcall(require, "neotest.consumers.neotree")
  if ok and type(neotree_consumer_m) == "function" then
    consumers.neotree = neotree_consumer_m
  end

  return consumers
end

return M
