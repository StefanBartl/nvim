---@module 'wkdoptions.config'
--- Central, modular configuration with lazy loading and observer pattern.
--- Reload: :luafile % or :source %
--- Live updates: :MyHlSet {key} {value} or :MyOptSet {key} {value}

local M = {}

-- Lazy-loaded modules
local parser, setter, getter, observer
local highlight_data, options_data, skip_data

--- Get parser module (lazy)
---@nodiscard
---@return WKDOptions.Config.Parser
local function get_parser()
  if not parser then
    parser = require("wkdoptions.config.core.parser")
  end
  return parser
end

--- Get setter module (lazy)
---@nodiscard
---@return WKDOptions.Config.Setter
local function get_setter()
  if not setter then
    setter = require("wkdoptions.config.core.setter")
  end
  return setter
end

--- Get getter module (lazy)
---@nodiscard
---@return WKDOptions.Config.Getter
local function get_getter()
  if not getter then
    getter = require("wkdoptions.config.core.getter")
  end
  return getter
end

--- Get observer module (lazy)
---@nodiscard
---@return table
local function get_observer()
  if not observer then
    observer = require("wkdoptions.config.core.observer")
  end
  return observer
end

--- Get highlight data (lazy, cached)
---@nodiscard
---@return WKDOptions.HL_CFG
local function get_highlight_data()
  if not highlight_data then
    highlight_data = require("wkdoptions.config.data.highlight")
  end
  return highlight_data
end

--- Get options data (lazy, cached)
---@nodiscard
---@return OptionsCfg
local function get_options_data()
  if not options_data then
    options_data = require("wkdoptions.config.data.options")
  end
  return options_data
end

--- Get skip data (lazy, cached)
---@nodiscard
---@return WKDOptions.HL_CFG.Utils.SkipCfg
local function get_skip_data()
  if not skip_data then
    skip_data = require("wkdoptions.config.data.skip")
  end
  return skip_data
end

--- Configuration table (lazy-initialized)
---@type WKDOptions.Config.Data|nil
M.cfg = nil

--- Get configuration (ensures initialization)
---@nodiscard
---@return WKDOptions.Config.Data
function M.get_cfg()
  if not M.cfg then
    M.cfg = {
      highlight = get_highlight_data(),
      options = get_options_data(),
      skip = get_skip_data(),
    }
  end
  return M.cfg
end

--- Parse a string into a typed value.
---@nodiscard
---@param s string|nil
---@return boolean|number|string
function M.parse(s)
  return get_parser().parse(s)
end

--- Set a key in a namespace and trigger callbacks.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@param key string
---@param value any
---@param toggle_if_bool boolean
---@return boolean success
---@return string|nil error
function M.set(ns, key, value, toggle_if_bool)
  local cfg = M.get_cfg()
  local ok, err = get_setter().set_by_path(cfg[ns], key, value, toggle_if_bool)

  if ok then
    get_observer().trigger(ns, key)
  end

  return ok, err
end

--- List keys of a namespace for completion.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@return string[]
function M.keys(ns)
  local cfg = M.get_cfg()
  local out = {}
  get_getter().collect_keys(cfg[ns], "", out)
  table.sort(out)
  return out
end

--- Get value by path from a namespace.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@param key string
---@return any|nil
function M.get(ns, key)
  local cfg = M.get_cfg()
  return get_getter().get_by_path(cfg[ns], key)
end

--- Register after-set callback for a namespace.
---@param ns '"highlight"'|'"options"'
---@param fn fun(key:string):nil
---@return nil
function M.on_after_set(ns, fn)
  get_observer().on_after_set(ns, fn)
end

--- Clear all observers for a namespace (testing/debugging).
---@param ns '"highlight"'|'"options"'
---@return nil
function M.clear_observers(ns)
  get_observer().clear(ns)
end

--- Get observer count for a namespace (testing/debugging).
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@return integer
function M.observer_count(ns)
  return get_observer().count(ns)
end

return M
