---@module 'config.harpoon.hardening'
--- Debounced persistence + safe UI wrapping for harpoon (v2-friendly).
--- - Debounces save() to collapse bursty writes
--- - Wraps ui.toggle_quick_menu once to trigger saves after menu actions
--- - Installs autocmds and flushes on :qa
---
--- Usage:
---   require('config.harpoon.hardening').setup({
---     debounce_ms = 200,
---     autocmd_events = { "BufLeave", "FocusLost" },
---   })

local M = {}

---@type uv uv
local uv = vim.uv or vim.loop
local api = vim.api
local nvim_create_autocmd = api.nvim_create_autocmd

-- Internal state (local to avoid polluting globals)
local STATE = { ---@type HarpoonHardeningState
  wrapped_ui = false,
  timer = nil,
  pending = false,
  debounce_ms = 200,
  augroup = nil,
}

---@return any|nil harpoon
local function _try_require_harpoon()
  local ok, mod = pcall(require, "harpoon")
  return ok and mod or nil
end

---@return any|nil ui
local function _try_require_ui()
  local ok, ui = pcall(require, "harpoon.ui")
  return ok and ui or nil
end

--- Best-effort save across API (harpoon v2 or list.save fallbacks).
---@return boolean ok
local function _save_now()
  local harpoon = _try_require_harpoon()
  if not harpoon then
    return false
  end

  -- Shape A: top-level :save()
  if type(harpoon.save) == "function" then
    local ok = pcall(harpoon.save, harpoon)
    return ok
  end

  -- Shape B: list():save()
  local list = (type(harpoon.list) == "function") and harpoon:list() or nil
  if list and type(list.save) == "function" then
    local ok = pcall(list.save, list)
    return ok
  end

  return false
end

--- Create or reuse a single uv timer for debouncing
---@param ms integer
local function _ensure_timer(ms)
  if STATE.timer and not STATE.timer:is_closing() then
    STATE.debounce_ms = ms
    return
  end
  ---@diagnostic disable-next-line
  STATE.timer = uv.new_timer()
  STATE.debounce_ms = ms
end

--- Schedule a debounced save
local function _debounced_save()
  if not STATE.timer then
    _ensure_timer(STATE.debounce_ms)
  end
  STATE.pending = true
  STATE.timer:stop()
  STATE.timer:start(STATE.debounce_ms, 0, function()
    if not STATE.pending then
      return
    end
    STATE.pending = false
    vim.schedule(function()
      _save_now()
    end)
  end)
end

--- Flush pending debounced save immediately (used on VimLeavePre).
local function _flush_now()
  if STATE.timer and not STATE.timer:is_closing() then
    STATE.timer:stop()
  end
  if STATE.pending then
    STATE.pending = false
    _save_now()
  end
end

--- Wrap ui.toggle_quick_menu once, to trigger save around menu use.
local function _ensure_ui_wrap()
  if STATE.wrapped_ui then
    return
  end

  local ui = _try_require_ui()
  if not ui or type(ui.toggle_quick_menu) ~= "function" then
    return
  end

  local orig = ui.toggle_quick_menu
  ui.toggle_quick_menu = function(...)
    local ret = { pcall(orig, ...) }
    -- Trigger debounced save regardless of menu result.
    _debounced_save()
    local ok = ret[1]
    if not ok then
      vim.notify("[harpoon hardening] ui.toggle_quick_menu failed: " .. tostring(ret[2]), vim.log.levels.WARN)
      return
    end
    return select(2, unpack(ret))
  end

  STATE.wrapped_ui = true
end

--- Install idempotent autocmds for saving on user activity.
---@param events string[]
local function _install_autocmds(events)
  if STATE.augroup then
    pcall(api.nvim_del_augroup_by_id, STATE.augroup)
    STATE.augroup = nil
  end

  STATE.augroup = api.nvim_create_augroup("HarpoonHardening", { clear = true })

  -- Debounced save on common "user done something with buffer" cues
  nvim_create_autocmd(events, {
    group = STATE.augroup,
    callback = function()
      _debounced_save()
    end,
    desc = "Harpoon debounced save",
  })

  -- Flush on exit to avoid losing last pending write
  nvim_create_autocmd("VimLeavePre", {
    group = STATE.augroup,
    callback = function()
      _flush_now()
    end,
    desc = "Harpoon flush pending save",
  })
end

---@param opts HarpoonHardeningOpts|nil
---@return nil
function M.setup(opts)
  opts = opts or {}
  local debounce_ms = (type(opts.debounce_ms) == "number" and opts.debounce_ms > 0) and opts.debounce_ms or 200
  local events = (type(opts.autocmd_events) == "table" and #opts.autocmd_events > 0) and opts.autocmd_events
    or { "BufLeave", "FocusLost" }

  -- If harpoon is not installed, still register autocmds;
  -- no-ops until harpoon becomes available.
  _ensure_timer(debounce_ms)
  _ensure_ui_wrap()
  _install_autocmds(events)
end

return M
