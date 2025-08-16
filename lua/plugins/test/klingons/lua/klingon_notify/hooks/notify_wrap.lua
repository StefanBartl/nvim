---@module 'klingon_notify.hooks.notify_wrap'
--- Wrap vim.notify so other plugins’ messages become Klingon shouts.

---@class KlingonNotifyWrapCfg
---@field forward_original boolean  -- Call original vim.notify in addition

local M = {}

---@type function|nil
local orig

---@type boolean
local enabled = false

-- Prefix/burst state
local last_prefixed_at ---@type integer|nil

local function get_phrase_for_level(level)
  local ok, KN = pcall(require, "klingon_notify")
  if not ok then return "Qapla'!" end
  local c = KN and KN._get_config and KN._get_config() or nil
  if not c or not c.phrases then return "Qapla'!" end
  if level and level >= vim.log.levels.ERROR then
    return c.phrases.error or "Qagh!"
  elseif level and level >= vim.log.levels.WARN then
    return c.phrases.warn or "yIqIm!"
  else
    return c.phrases.success or "Qapla'!"
  end
end

local function should_prefix(cfg)
  if not cfg or cfg.prefix_mode == "none" then return false end
  if cfg.prefix_mode == "always" then return true end
  if cfg.prefix_mode ~= "burst" then return false end
  local now = vim.loop.now()
  local win = (cfg.burst_window_ms or 1200)
  if not last_prefixed_at or (now - last_prefixed_at) > win then
    last_prefixed_at = now
    return true
  end
  return false
end


local function klingon_from_level(msg, level, cfg)
  local ok, KN = pcall(require, "klingon_notify")
  if not ok then return end
  local L = level or vim.log.levels.INFO

  if cfg and should_prefix(cfg) then
    local prefix = (cfg.prefix_from_level and get_phrase_for_level(L)) or (cfg.fixed_prefix or "Qapla'!")
    msg = string.format("%s: %s", prefix, tostring(msg or ""))
  end

  if L >= vim.log.levels.ERROR then
    KN.error(msg)
  elseif L >= vim.log.levels.WARN then
    KN.warn(msg)
  elseif L >= vim.log.levels.INFO then
    KN.info(msg)
  else
    KN.info(msg)
  end
end


--- Enable notify wrapper.
---@param cfg KlingonNotifyWrapCfg
---@return boolean
function M.enable(cfg)
  if enabled then return true end
  orig = vim.notify
  local forward = cfg and cfg.forward_original or false
  local cfg_copy = cfg or {}

  vim.notify = function(msg, level, opts)
    klingon_from_level(msg, level, cfg_copy)
    if forward and type(orig) == "function" then
      pcall(orig, msg, level, opts)
    end
  end

  enabled = true
  return true
end


--- Disable wrapper and restore original notify.
function M.disable()
  if enabled and type(orig) == "function" then
    vim.notify = orig
  end
  orig = nil
  enabled = false
end

return M

