---@module 'autocmds.auto-center-fexplorer'
--- Auto-`zz` in file-explorer windows (neo-tree, NvimTree, netrw): keeps the
--- cursor vertically centered as it moves. Keyboard-only — mouse clicks and
--- scrolls are suppressed for `mouse_cooldown_ms` after the event.
---
--- Setup: require("autocmds.auto-center-fexplorer").setup(opts?)
---   opts.enabled           boolean   (default true)
---   opts.filetypes         string[]  (default { "neo-tree", "NvimTree", "netrw" })
---   opts.delay_ms          number    debounce before centering (default 0)
---   opts.mouse_cooldown_ms number    suppress after a mouse event (default 200)
--- Runtime: .enable() / .disable() / .toggle() on the returned module.

local notify = require("lib.nvim.notify").create("[autocmds.auto-center-fexplorer]")
local Autocmd = require("lib.nvim.bindings.autocmd")

local M = {}

---@class AutoCenterConfig
---@field enabled? boolean Whether auto-centering is globally enabled
---@field filetypes? string[] List of filetypes to enable auto-centering for
---@field delay_ms? number Debounce delay in milliseconds to prevent excessive centering
---@field mouse_cooldown_ms? number Suppress centering for this many ms after any mouse event
local default_config = {
  enabled = true,
  filetypes = { "neo-tree", "NvimTree", "netrw" },
  delay_ms = 0,
  mouse_cooldown_ms = 200,
}

---@type AutoCenterConfig
local config = vim.deepcopy(default_config)

---@type table<number, uv.uv_timer_t|nil> Timer storage per buffer
local timers = {}

---@type table<number, boolean> Track which buffers have auto-centering enabled
local enabled_buffers = {}

-- Monotonic timestamp (ms) of the last mouse event detected via vim.on_key.
-- 0 means "never". Compared with vim.uv.now() in the CursorMoved guard.
local mouse_last_ms = 0

--- Centers the cursor in the current window vertically.
--- This is equivalent to the `zz` command in normal mode.
---@param bufnr number Buffer number to center in
local function center_cursor(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then
    return
  end

  local win = wins[1]
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! zz")
    end)
  end
end

--- Schedules a debounced centering operation for the given buffer.
---@param bufnr number Buffer number to schedule centering for
local function schedule_center(bufnr)
  if timers[bufnr] then
    if not timers[bufnr]:is_closing() then
      timers[bufnr]:stop()
      timers[bufnr]:close()
    end
    timers[bufnr] = nil
  end

  local timer = vim.uv.new_timer()
  if not timer then
    notify.debug("[auto-close-fexplorer] timer is nil")
    return
  end
  timers[bufnr] = timer

  timer:start(
    config.delay_ms,
    0,
    vim.schedule_wrap(function()
      center_cursor(bufnr)
      if timer and not timer:is_closing() then
        timer:close()
      end
      timers[bufnr] = nil
    end)
  )
end

---@param ft string
---@return boolean
local function is_explorer_filetype(ft)
  for _, explorer_ft in ipairs(config.filetypes) do
    if ft == explorer_ft then
      return true
    end
  end
  return false
end

--- Returns true when a mouse event happened recently enough to suppress centering.
---@return boolean
local function mouse_was_recent()
  return (vim.uv.now() - mouse_last_ms) < (config.mouse_cooldown_ms or 200)
end

---@param bufnr number
local function setup_buffer(bufnr)
  if enabled_buffers[bufnr] then
    return
  end

  enabled_buffers[bufnr] = true

  local group = Autocmd.group("AutoCenterExplorer_" .. bufnr, true)

  -- Two guards before centering:
  --   1. Focus guard  – the explorer window must be the active window.
  --      Prevents centering when the user scrolls over neo-tree via the mouse
  --      while focus is in another window (editor, browser, etc.).
  --   2. Mouse guard  – no mouse event must have happened within the cooldown
  --      window. Catches clicks and scrolls while neo-tree IS focused.
  Autocmd.create({ "CursorMoved", "CursorMovedI" }, function()
    if not config.enabled then
      return
    end
    if mouse_was_recent() then
      return
    end
    local current_win = vim.api.nvim_get_current_win()
    local wins = vim.fn.win_findbuf(bufnr)
    for _, w in ipairs(wins) do
      if w == current_win then
        schedule_center(bufnr)
        return
      end
    end
  end, {
    group = group,
    buffer = bufnr,
    desc = "Auto-center cursor in file explorer (keyboard only)",
  })

  Autocmd.create("BufDelete", function()
    if timers[bufnr] then
      if not timers[bufnr]:is_closing() then
        timers[bufnr]:stop()
        timers[bufnr]:close()
      end
      timers[bufnr] = nil
    end
    enabled_buffers[bufnr] = nil
  end, {
    group = group,
    buffer = bufnr,
    desc = "Cleanup auto-center resources",
  })

  vim.schedule(function()
    center_cursor(bufnr)
  end)
end

--- Initializes the auto-center module with optional user configuration.
---@param user_config? AutoCenterConfig|table User configuration to merge with defaults
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config or {})

  -- Global mouse-event detector. `on_key` fires synchronously before every
  -- keypress, so keep this callback minimal (just stamp the time). keytrans()
  -- turns the raw bytes into a name like "<ScrollWheelUp>". Any mouse/scroll
  -- event anywhere suppresses centering for the cooldown, which is fine:
  -- centering only matters while the explorer has keyboard focus.
  local ns = vim.api.nvim_create_namespace("AutoCenterExplorerMouse")
  vim.on_key(function(_, typed)
    if not typed or typed == "" then
      return
    end
    local key = vim.fn.keytrans(typed)
    if key:find("Mouse", 1, true) or key:find("Scroll", 1, true) then
      mouse_last_ms = vim.uv.now()
    end
  end, ns)

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local ft = vim.bo[bufnr].filetype
      if is_explorer_filetype(ft) then
        setup_buffer(bufnr)
      end
    end
  end

  Autocmd.create("FileType", function(args)
    if is_explorer_filetype(args.match) then
      setup_buffer(args.buf)
    end
  end, {
    group = Autocmd.group("AutoCenterExplorerSetup", true),
    desc = "Setup auto-centering for file explorer buffers",
  })
end

function M.enable()
  config.enabled = true
end

function M.disable()
  config.enabled = false
end

function M.toggle()
  config.enabled = not config.enabled
  if config.enabled then
    notify.info("Auto-center enabled")
  else
    notify.info("Auto-center disabled")
  end
end

---@return AutoCenterConfig
function M.get_config()
  return vim.deepcopy(config)
end

return M
