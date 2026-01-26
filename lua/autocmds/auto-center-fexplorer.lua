--AUDIT: Daurhaft implementieren in autocmds

---@module 'autocmds.auto-center-fexplorer'
-- Automatically centers the cursor in file explorer windows (neo-tree, nvim-tree, netrw).
-- This module provides automatic centering functionality that triggers on cursor movement
-- within file explorer buffers, similar to the `zz` command but automated.
--
--                         USAGE:
-- Default settings:
--   auto_center.setup()
--
-- Custom settings:
--   auto_center.setup({
--     enabled = true,
--     filetypes = { "neo-tree", "NvimTree", "netrw" },
--     delay_ms = 50, -- Debounce-Verzögerung in Millisekunden
--   })
--
--  Control module at runtime:
--   require('auto-center-explorer').enable()  -- Activate
--   require('auto-center-explorer').disable() -- Deactivate
--   require('auto-center-explorer').toggle()  -- Toggle
--
-- Keybinding possibles:
--   vim.keymap.set('n', '<leader>tc', function()
--     require('auto-center-explorer').toggle()
--   end, { desc = 'Toggle auto-center in file explorers' })


local notify = require("lib.notify").create("[autocmds.auto-center-fexplorer]")

local M = {}

---@class AutoCenterConfig
---@field enabled? boolean Whether auto-centering is globally enabled
---@field filetypes? string[] List of filetypes to enable auto-centering for
---@field delay_ms? number Debounce delay in milliseconds to prevent excessive centering
local default_config = {
  enabled = true,
  filetypes = { "neo-tree", "NvimTree", "netrw" },
  delay_ms = 0,
}

---@type AutoCenterConfig
local config = vim.deepcopy(default_config)

---@type table<number, uv.uv_timer_t|nil> Timer storage per buffer
local timers = {}

---@type table<number, boolean> Track which buffers have auto-centering enabled
local enabled_buffers = {}

--- Centers the cursor in the current window vertically.
--- This is equivalent to the `zz` command in normal mode.
---@param bufnr number Buffer number to center in
local function center_cursor(bufnr)
  -- Only center if buffer still exists and is valid
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Get window displaying this buffer
  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then
    return
  end

  -- Center in the first window (usually there's only one for file explorers)
  local win = wins[1]
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! zz")
    end)
  end
end

--- Schedules a debounced centering operation for the given buffer.
--- Uses a timer to prevent excessive centering on rapid cursor movements.
---@param bufnr number Buffer number to schedule centering for
local function schedule_center(bufnr)
  -- Cancel existing timer for this buffer if any
  if timers[bufnr] then
    if not timers[bufnr]:is_closing() then
      timers[bufnr]:stop()
      timers[bufnr]:close()
    end
    timers[bufnr] = nil
  end

  -- Create new timer with debounce delay
  local timer = vim.loop.new_timer()
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

--- Checks if the given filetype is a supported file explorer.
---@param ft string Filetype to check
---@return boolean is_explorer True if the filetype is in the configured list
local function is_explorer_filetype(ft)
  for _, explorer_ft in ipairs(config.filetypes) do
    if ft == explorer_ft then
      return true
    end
  end
  return false
end

--- Sets up auto-centering for a specific buffer.
--- Creates autocommands for cursor movement events.
---@param bufnr number Buffer number to set up auto-centering for
local function setup_buffer(bufnr)
  if enabled_buffers[bufnr] then
    return
  end

  enabled_buffers[bufnr] = true

  -- Create autocommand group for this specific buffer
  local group = vim.api.nvim_create_augroup("AutoCenterExplorer_" .. bufnr, { clear = true })

  -- Center on cursor movement
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      if config.enabled then
        schedule_center(bufnr)
      end
    end,
    desc = "Auto-center cursor in file explorer",
  })

  -- Cleanup when buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    buffer = bufnr,
    callback = function()
      if timers[bufnr] then
        if not timers[bufnr]:is_closing() then
          timers[bufnr]:stop()
          timers[bufnr]:close()
        end
        timers[bufnr] = nil
      end
      enabled_buffers[bufnr] = nil
    end,
    desc = "Cleanup auto-center resources",
  })

  -- Initial center when buffer becomes visible
  vim.schedule(function()
    center_cursor(bufnr)
  end)
end

--- Initializes the auto-center module with optional user configuration.
---@param user_config? AutoCenterConfig|table User configuration to merge with defaults
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config or {})

  -- Set up auto-centering for existing explorer buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local ft = vim.bo[bufnr].filetype
      if is_explorer_filetype(ft) then
        setup_buffer(bufnr)
      end
    end
  end

  -- Watch for new file explorer buffers
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("AutoCenterExplorerSetup", { clear = true }),
    callback = function(args)
      if is_explorer_filetype(args.match) then
        setup_buffer(args.buf)
      end
    end,
    desc = "Setup auto-centering for file explorer buffers",
  })
end

--- Enables auto-centering globally.
function M.enable()
  config.enabled = true
end

--- Disables auto-centering globally.
function M.disable()
  config.enabled = false
end

--- Toggles auto-centering on/off.
function M.toggle()
  config.enabled = not config.enabled
  if config.enabled then
    notify.info("Auto-center enabled")
  else
    notify.info("Auto-center disabled")
  end
end

--- Returns the current configuration.
---@return AutoCenterConfig current_config Current configuration table
function M.get_config()
  return vim.deepcopy(config)
end

return M
