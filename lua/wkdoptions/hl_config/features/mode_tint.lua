---@module 'wkdoptions.hl_config.features.mode_tint'
--- Per-mode CursorLine tinting with cached mode tracking to avoid redundant updates.

local lazy = require("lib.lua.lazy")
local State = lazy.require("wkdoptions.hl_config.core.state")
local CursorLine = lazy.require("wkdoptions.hl_config.features.cursorline")
local is_ui = lazy.require("wkdoptions.hl_config.utils.skip").std_skip
local Autocmd = lazy.require("lib.nvim.bindings.autocmd")

local M = {}

--- Resolve mode from ModeChanged event (with fallbacks)
---@nodiscard
---@param ev table|nil -- ModeChanged event
---@return string -- normalized mode char
local function resolve_mode(ev)
  -- Try vim.v.event.new_mode (safe access)
  local ok, event_tbl = pcall(function()
    return vim.v.event
  end)

  if ok and type(event_tbl) == "table" then
    local nm = rawget(event_tbl, "new_mode")
    if type(nm) == "string" and #nm > 0 then
      return nm:sub(1, 1)
    end
  end

  -- Parse from ev.match ("old:new")
  if ev and type(ev.match) == "string" then
    local nm = ev.match:match(":(.+)$")
    if nm then
      return nm:sub(1, 1)
    end
  end

  -- Fallback to current mode
  local m = vim.fn.mode(1)
  return (m or "n"):sub(1, 1)
end

--- Update tint for active window (cached to avoid ping-pong)
---@param cfg WKDOptions.HL_CFG
---@param ev table|nil -- ModeChanged event
---@return nil
function M.update(cfg, ev)
  if not State.is_enabled("mode_colors") then
    return
  end

  if is_ui(0) then
    return
  end

  local win = vim.api.nvim_get_current_win()
  local mode = resolve_mode(ev)

  -- Skip if mode unchanged (per-window cache)
  if State.get_win_mode(win) == mode then
    return
  end

  State.set_win_mode(win, mode)

  -- Delegate to cursorline module with mode
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      CursorLine.activate(cfg, mode)
    end
  end)
end

--- Clear cache for closed window
---@param win integer
---@return nil
function M.clear_cache(win)
  State.clear_win_mode(win)
end

--- Install autocmds
---@param cfg WKDOptions.HL_CFG
---@return nil
function M.enable(cfg)
  local aug = State.get_augroup("ModeTint", true)

  Autocmd.create("ModeChanged", function(ev)
    M.update(cfg, ev)
  end, {
    group = aug,
    desc = "Tint CursorLine per mode",
  })

  Autocmd.create("BufWinEnter", function()
    M.update(cfg, nil)
  end, {
    group = aug,
    desc = "Reapply mode tint on window enter",
  })

  Autocmd.create("WinClosed", function(ev)
    local id = tonumber(ev.match)
    if id then
      M.clear_cache(id)
    end
  end, {
    group = aug,
    desc = "Purge mode-tint cache",
  })

  -- Initial apply
  M.update(cfg, nil)
end

return M
