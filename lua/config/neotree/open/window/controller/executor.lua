---@module 'config.neotree.open.window.controller.executor'
---@brief Neo-tree command executor with FIXED float focus handling

local M = {}

local buffer_utils = require("config.neotree.utils.buffer")
local state = require("config.neotree.state.windows")
local tree_state = require("config.neotree.state.tree")
local cfg = require("config.neotree").options

---Get valid Neo-tree command module
---@return table|nil NeoCmd
---@return string|nil error
local function get_neo_cmd()
  local ok, NeoCmd = pcall(require, "neo-tree.command")
  if not ok then
    return nil, "neo-tree.command not loaded"
  end
  return NeoCmd, nil
end

---Find and validate Neo-tree window
---@return integer|nil win_id
local function find_neotree_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        return win
      end
    end
  end
  return nil
end

---Cleanup duplicate Neo-tree windows
---@return integer count
local function cleanup_duplicates()
  local windows = {}

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        table.insert(windows, win)
      end
    end
  end

  for _, win in ipairs(windows) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  if cfg.debug and #windows > 0 then
    vim.notify(
      string.format("[neo-tree] Cleaned up %d duplicate window(s)", #windows),
      vim.log.levels.INFO
    )
  end

  return #windows
end

---Focus Neo-tree window with validation and retries
---@param max_attempts? integer
---@return boolean success
local function focus_neotree_window(max_attempts)
  max_attempts = max_attempts or 3
  local attempt = 0

  while attempt < max_attempts do
    attempt = attempt + 1

    local win = find_neotree_window()
    if win and vim.api.nvim_win_is_valid(win) then
      local ok = pcall(vim.api.nvim_set_current_win, win)
      if ok then
        if cfg.debug then
          vim.notify(
            string.format("[neo-tree] Focused window on attempt %d", attempt),
            vim.log.levels.DEBUG
          )
        end
        return true
      end
    end

    if attempt < max_attempts then
      vim.wait(50)
    end
  end

  return false
end

---Open Neo-tree window
---@param position Cfg.NeoTree.Position
---@param source string
---@param callback fun(success: boolean)
---@return nil
function M.open_window(position, source, callback)
  local NeoCmd, err = get_neo_cmd()
  if not NeoCmd then
    vim.notify("[neo-tree] " .. err, vim.log.levels.ERROR)
    callback(false)
    return
  end

  -- Cleanup BEFORE state update
  cleanup_duplicates()

  if position == "float" then
    -- ========================================================================
    -- FLOAT DEBUG: Using incremental steps
    -- ========================================================================

    -- CHANGE THIS NUMBER TO TEST DIFFERENT STEPS (1-7)
    local ACTIVE_STEP = 7

    local float_steps = require("config.neotree.open.window.controller.float_debug_steps")
    local step_func = float_steps["float_step_" .. ACTIVE_STEP]

    if not step_func then
      vim.notify(
        string.format("[neo-tree] Invalid float step: %d", ACTIVE_STEP),
        vim.log.levels.ERROR
      )
      callback(false)
      return
    end

    -- Update state for step 6 only (full stack)
    if ACTIVE_STEP == 6 then
      state.set_open("float", source, cfg.restore_last_position and "restore" or "reveal")
    end

    if cfg.debug then
      vim.notify(
        string.format("[neo-tree] Using float_step_%d", ACTIVE_STEP),
        vim.log.levels.INFO
      )
    end

    step_func(callback)
    return
  end

  -- =========================================================================
  -- Standard positions (left/right/current)
  -- =========================================================================

  state.set_open(position, source, cfg.restore_last_position and "restore" or "reveal")

  local delay = (position == "current") and 100 or 50

  vim.defer_fn(function()
    local exec_opts = {
      source = source,
      action = "show",
      position = position,
      reveal = not cfg.restore_last_position,
    }

    if not cfg.restore_last_position then
      local ctx = buffer_utils.get_buffer_context()
      if ctx then
        exec_opts.reveal_file = ctx.file
        exec_opts.reveal_force_cwd = false
        exec_opts.dir = ctx.dir
      end
    end

    local ok_exec = pcall(NeoCmd.execute, exec_opts)

    if not ok_exec then
      state.set_closed("open_failed")
      callback(false)
      return
    end

    vim.defer_fn(function()
      if cfg.restore_last_position then
        local ok, manager = pcall(require, "neo-tree.sources.manager")
        if ok then
          local neo_state = manager.get_state(source)
          if neo_state and neo_state.tree then
            tree_state.restore_state(neo_state.tree)
          end
        end
      end
      focus_neotree_window()
      callback(true)
    end, 200)
  end, delay)
end

---Close Neo-tree window
---@param callback fun(success: boolean)
---@return nil
function M.close_window(callback)
  local NeoCmd, err = get_neo_cmd()
  if not NeoCmd then
    vim.notify("[neo-tree] " .. err, vim.log.levels.ERROR)
    callback(false)
    return
  end

  local current_pos = state.get_position()
  local current_src = state.get_source()

  if cfg.debug then
    vim.notify(
      string.format("[neo-tree] Closing position: %s", tostring(current_pos)),
      vim.log.levels.INFO
    )
  end

  -- Capture state BEFORE close
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if ok and current_src then
    local neo_state = manager.get_state(current_src)
    if neo_state and neo_state.tree then
      pcall(tree_state.capture_state, neo_state)
    end
  end

  state.set_closed("closing_" .. tostring(current_pos))

  local function verify_closed()
    local win = find_neotree_window()
    return win == nil
  end

  if current_pos == "current" then
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "neo-tree" then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end

    vim.defer_fn(function()
      callback(verify_closed())
    end, 50)
    return
  end

  if current_pos == "float" then
    local ok_close = pcall(NeoCmd.execute, {
      source = current_src or "filesystem",
      action = "close",
    })

    require("config.neotree.open.window.float").set_open_state(false)

    vim.defer_fn(function()
      callback(ok_close and verify_closed())
    end, 50)
    return
  end

  local ok_close = pcall(NeoCmd.execute, {
    source = current_src or "filesystem",
    action = "close",
  })

  vim.defer_fn(function()
    callback(ok_close and verify_closed())
  end, 50)
end

return M
