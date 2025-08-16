---@module 'klingon_notify'
--- Klingon shouts for success, error, warn, info.
--- Two display modes:
---   1) "float": tiny floating window, closes on any key or timeout
---   2) "notify": use nvim-notify if present; fallback to vim.notify
---
--- Public API:
---   require('klingon_notify').setup({ ... })
---   require('klingon_notify').shout("success"|"error"|"warn"|"info", "optional extra message")
---
--- User commands are defined in plugin/klingon_notify.lua.

local Ui = require("klingon_notify.ui")
local PhrasePack = require("klingon_notify.phrases")

---@enum KlingonLevel
local Levels = {
  success = "success",
  error   = "error",
  warn    = "warn",
  info    = "info",
}

---@class KlingonNotifyConfig
---@field mode        "float"|"notify"        -- Which renderer to use
---@field use_icons   boolean                 -- Prefix messages with icons
---@field phrases     KlingonPhrases          -- Overridable phrase table
---@field icons       KlingonIcons            -- Overridable icon table
---@field float       KlingonFloatOpts        -- Options for floating window
---@field map_levels  table<string, integer>  -- Map logical levels to vim.log.levels
---@field title       string                  -- Notify title / float title text
---@field highlight_map table<string, string> -- Map level -> highlight group for float

---@class KlingonState
---@field cfg KlingonNotifyConfig

local M = {}

---@type KlingonState
local state = {
  cfg = nil,
}

local function ensure_highlights()
  -- Create/relink highlight groups once. Link to Diagnostic groups if available.
  local function link(from, to)
    vim.api.nvim_set_hl(0, from, { link = to, default = true })
  end

  -- Reasonable defaults across Neovim versions
  link("KlingonNotifySuccess", vim.fn.hlexists("DiagnosticOk") == 1 and "DiagnosticOk" or "DiffAdd")
  link("KlingonNotifyError", "DiagnosticError")
  link("KlingonNotifyWarn", "DiagnosticWarn")
  link("KlingonNotifyInfo", "DiagnosticInfo")
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
      pad_left = 1,
      pad_right = 1,
      pad_top = 0,
      pad_bottom = 0,
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
  }
end

--- Public setup.
---@param cfg KlingonNotifyConfig|nil
function M.setup(cfg)
  ensure_highlights()
  state.cfg = deep_merge(default_config(), cfg or {})
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
  -- Small PoC: single line; could be extended to multi-line wrapping.
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

  -- float mode
  local hl = c.highlight_map[level] or "Normal"
  local float_opts = deep_merge(c.float, {
    highlight = hl,
    title = c.title,
  })
  Ui.open_float(lines, hl, float_opts)
end

--- Convenience wrappers
function M.success(extra) M.shout(Levels.success, extra) end

function M.error(extra) M.shout(Levels.error, extra) end

function M.warn(extra) M.shout(Levels.warn, extra) end

function M.info(extra) M.shout(Levels.info, extra) end

return M
