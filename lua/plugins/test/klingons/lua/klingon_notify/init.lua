---@module 'klingon_notify'
--- Klingon shouts for success, error, warn, info.
--- Two display modes:
---   1) "float": tiny floating window, closes on any key or timeout
---   2) "notify": use nvim-notify if present; fallback to vim.notify
--- Optional hooks (enable via setup):
---   - hooks.diagnostics.enabled   : react to DiagnosticChanged/BufEnter
---   - hooks.notify_wrap.enabled   : wrap vim.notify to speak Klingon
---
--- Public API:
---   require('klingon_notify').setup({ ... })
---   require('klingon_notify').shout("success"|"error"|"warn"|"info", "optional message")
---   require('klingon_notify').success|error|warn|info("optional message")

local Ui = require("klingon_notify.ui")
local PhrasePack = require("klingon_notify.phrases")

---@enum KlingonLevel
local Levels = {
  success = "success",
  error   = "error",
  warn    = "warn",
  info    = "info",
}

---@class KlingonNotifyHookDiagnosticsConfig
---@field enabled boolean          -- Enable diagnostics hook
---@field debounce_ms integer      -- Debounce for DiagnosticChanged

---@class KlingonNotifyHookNotifyWrapConfig
---@field enabled boolean          -- Wrap vim.notify
---@field forward_original boolean -- Also call original vim.notify

---@class KlingonNotifyHooksConfig
---@field diagnostics KlingonNotifyHookDiagnosticsConfig
---@field notify_wrap KlingonNotifyHookNotifyWrapConfig

---@class KlingonNotifyConfig
---@field mode        "float"|"notify"
---@field use_icons   boolean
---@field phrases     KlingonPhrases
---@field icons       KlingonIcons
---@field float       KlingonFloatOpts
---@field map_levels  table<string, integer>
---@field title       string
---@field highlight_map table<string, string>
---@field hooks       KlingonNotifyHooksConfig  -- Optional hooks (diagnostics, notify wrapper)

---@class KlingonState
---@field cfg KlingonNotifyConfig
---@field hooks_enabled { diag: boolean, notify: boolean }

local M = {}

---@type KlingonState
local state = {
  cfg = nil,
  hooks_enabled = { diag = false, notify = false },
}

local function ensure_highlights()
  local function link(from, to)
    vim.api.nvim_set_hl(0, from, { link = to, default = true })
  end
  link("KlingonNotifySuccess", vim.fn.hlexists("DiagnosticOk") == 1 and "DiagnosticOk" or "DiffAdd")
  link("KlingonNotifyError",   "DiagnosticError")
  link("KlingonNotifyWarn",    "DiagnosticWarn")
  link("KlingonNotifyInfo",    "DiagnosticInfo")
end

--- Merge two (possibly nested) tables with precedence to right-hand side.
---@generic T
---@param a T
---@param b T
---@return T
local function deep_merge(a, b)
  if type(a) ~= "table" then return b end
  if type(b) ~= "table" then return a end
  local t = {}
  for k, v in pairs(a) do t[k] = v end
  for k, v in pairs(b) do
    if type(v) == "table" and type(a[k]) == "table" then
      t[k] = deep_merge(a[k], v)
    else
      t[k] = v
    end
  end
  return t
end

--- Build default configuration.
---@return KlingonNotifyConfig
local function default_config()
  local pack = PhrasePack.get_defaults()
  return {
    mode = "float",
    use_icons = true,
    phrases = pack.phrases,
    icons = pack.icons,
    float = {
      border = "rounded",
      pad_left = 1, pad_right = 1,
      pad_top = 0, pad_bottom = 0,
      zindex = 150,
      timeout_ms = 1500,
      winblend = 10,
      highlight = "Normal",
      title = "tlhIngan",
      title_pos = "left",
    },
    map_levels = {
      success = vim.log.levels.INFO,
      info    = vim.log.levels.INFO,
      warn    = vim.log.levels.WARN,
      error   = vim.log.levels.ERROR,
    },
    title = "Klingon",
    highlight_map = {
      success = "KlingonNotifySuccess",
      info    = "KlingonNotifyInfo",
      warn    = "KlingonNotifyWarn",
      error   = "KlingonNotifyError",
    },
    hooks = {
      diagnostics = { enabled = false, debounce_ms = 100 },
    notify_wrap = {
      enabled = false,
      forward_original = false,

      -- NEW:
      prefix_mode = "none",     -- "none" | "always" | "burst"
      burst_window_ms = 1200,   -- quiet window for "burst" mode
      prefix_from_level = true, -- true: phrase depends on level; false: fixed text
      fixed_prefix = "Qapla'!", -- used if prefix_from_level=false
    },
    },
  }
end

--- Enable/disable hooks according to config.
local function apply_hooks()
  local c = state.cfg.hooks or {}
  -- Diagnostics hook
  do
    local ok, mod = pcall(require, "klingon_notify.hooks.diagnostics")
    if ok and c.diagnostics and c.diagnostics.enabled then
      if not state.hooks_enabled.diag then
        state.hooks_enabled.diag = mod.enable({
          debounce_ms = c.diagnostics.debounce_ms or 100,
        }) and true or false
      end
    else
      if state.hooks_enabled.diag and ok and mod and type(mod.disable) == "function" then
        mod.disable()
      end
      state.hooks_enabled.diag = false
    end
  end
  -- Notify wrapper
  do
    local ok, mod = pcall(require, "klingon_notify.hooks.notify_wrap")
    if ok and c.notify_wrap and c.notify_wrap.enabled then
      if not state.hooks_enabled.notify then
        state.hooks_enabled.notify = mod.enable({
          forward_original = c.notify_wrap.forward_original or false,
        }) and true or false
      end
    else
      if state.hooks_enabled.notify and ok and mod and type(mod.disable) == "function" then
        mod.disable()
      end
      state.hooks_enabled.notify = false
    end
  end
end

--- Public setup.
---@param cfg KlingonNotifyConfig|nil
function M.setup(cfg)
  ensure_highlights()
  state.cfg = deep_merge(default_config(), cfg or {})
  apply_hooks()
end

--- Internal: format final text for a given level and optional extra message.
---@param level "success"|"error"|"warn"|"info"
---@param extra string|nil
---@return string[] lines @as string[]
local function format_lines(level, extra)
  local c      = state.cfg
  local phrase = c.phrases[level]
  local icon   = c.use_icons and (c.icons[level] or "") or ""
  local text   = icon ~= "" and (icon .. "  " .. phrase) or phrase
  if extra and extra ~= "" then
    text = text .. "  " .. extra
  end
  ---@type string[]  -- known length list, avoids reallocation & LuaLS issues
  local lines = { [1] = text }
  return lines
end

--- Show a shout using the configured mode.
---@param level "success"|"error"|"warn"|"info"
---@param extra string|nil
function M.shout(level, extra)
  if not state.cfg then M.setup({}) end
  local c = state.cfg
  local lines = format_lines(level, extra)

  if c.mode == "notify" then
    Ui.notify({
      title = c.title,
      level = c.map_levels[level] or vim.log.levels.INFO,
      message = lines[1],
    })
    return
  end

  local hl = c.highlight_map[level] or "Normal"
  local float_opts = deep_merge(c.float, {
    highlight = hl,
    title = c.title,
  })
  Ui.open_float(lines, hl, float_opts)
end

function M.success(extra) M.shout(Levels.success, extra) end
function M.error(extra)   M.shout(Levels.error,   extra) end
function M.warn(extra)    M.shout(Levels.warn,    extra) end
function M.info(extra)    M.shout(Levels.info,    extra) end

function M._get_config()
  return state.cfg
end

return M
