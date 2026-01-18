---@module 'config.neotree.open.window.custom_float'
---@brief Custom float window with full Neo-tree integration
---@description
--- Bypasses Neo-tree's buggy float window logic by creating our own
--- float window and manually mounting Neo-tree content into it.
--- Respects all state management (restore/reveal modes, tree state).

local M = {}

local state = require("config.neotree.state.windows")
local tree_state = require("config.neotree.state.tree")
local buffer_utils = require("config.neotree.utils.buffer")
local cfg = require("config.neotree").options

---@class CustomFloatState
---@field win integer|nil Current float window ID
---@field buf integer|nil Current Neo-tree buffer ID
---@field source string Current source name
---@field cleanup_timer uv.uv_timer_t|nil

---@type CustomFloatState
local float_state = {
  win = nil,
  buf = nil,
  source = "filesystem",
  cleanup_timer = nil,
}

-- ============================================================================
-- Window Configuration
-- ============================================================================

---Calculate centered float window dimensions
---@return table nvim_open_win config
local function get_float_config()
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return { row = 0, col = 0, width = 80, height = 20 }
  end

  local width = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * 0.8)

  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  return {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Neo-tree ",
    title_pos = "center",
    zindex = 50,
  }
end

-- ============================================================================
-- Buffer Management
-- ============================================================================

---Get or create Neo-tree buffer for source
---@param source string
---@return integer|nil bufnr
local function get_or_create_buffer(source)
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then
    if cfg.debug then
      vim.notify("[custom-float] Failed to load neo-tree manager", vim.log.levels.ERROR)
    end
    return nil
  end

  -- Get state for source
  local neo_state = manager.get_state(source)
  if not neo_state then
    if cfg.debug then
      vim.notify(
        string.format("[custom-float] Could not get state for source: %s", source),
        vim.log.levels.ERROR
      )
    end
    return nil
  end

  -- Check if state already has a valid buffer
  if neo_state.bufnr and vim.api.nvim_buf_is_valid(neo_state.bufnr) then
    local ft = vim.bo[neo_state.bufnr].filetype
    if ft == "neo-tree" then
      if cfg.debug then
        vim.notify(
          string.format("[custom-float] Reusing buffer %d", neo_state.bufnr),
          vim.log.levels.DEBUG
        )
      end
      return neo_state.bufnr
    end
  end

  -- Create new buffer via Neo-tree's own create function
  local ok_renderer, _ = pcall(require, "neo-tree.ui.renderer")
  if not ok_renderer then
    return nil
  end

  -- Call Neo-tree's setup_buffer to get properly configured buffer
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Set essential buffer options
  vim.bo[bufnr].filetype = "neo-tree"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buftype = "nofile"

  -- Associate buffer with state
  neo_state.bufnr = bufnr

  if cfg.debug then
    vim.notify(
      string.format("[custom-float] Created new buffer %d", bufnr),
      vim.log.levels.DEBUG
    )
  end

  return bufnr
end

-- ============================================================================
-- Window Creation
-- ============================================================================

---Create float window and mount Neo-tree
---@param source string
---@return integer|nil win_id
local function create_float_window(source)
  local bufnr = get_or_create_buffer(source)
  if not bufnr then
    return nil
  end

  local config = get_float_config()
  local win = vim.api.nvim_open_win(bufnr, true, config)

  if not win or not vim.api.nvim_win_is_valid(win) then
    if cfg.debug then
      vim.notify("[custom-float] Failed to create window", vim.log.levels.ERROR)
    end
    return nil
  end

  -- Set window options for Neo-tree compatibility
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = true
  vim.wo[win].signcolumn = "auto"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].foldenable = false
  vim.wo[win].wrap = false
  vim.wo[win].spell = false
  vim.wo[win].list = false

  -- Apply Neo-tree highlights if available
  pcall(function()
    vim.wo[win].winhighlight = "Normal:NeoTreeNormal,FloatBorder:NeoTreeFloatBorder"
  end)

  float_state.win = win
  float_state.buf = bufnr
  float_state.source = source

  if cfg.debug then
    vim.notify(
      string.format("[custom-float] Created window %d with buffer %d", win, bufnr),
      vim.log.levels.DEBUG
    )
  end

  return win
end

-- ============================================================================
-- Neo-tree Content Rendering
-- ============================================================================

---Render Neo-tree content in float window
---@param source string
---@param reveal_file? string
---@param dir? string
local function render_neotree_content(source, reveal_file, dir)
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then
    if cfg.debug then
      vim.notify("[custom-float] Could not load manager", vim.log.levels.ERROR)
    end
    return
  end

  local neo_state = manager.get_state(source)
  if not neo_state then
    if cfg.debug then
      vim.notify(
        string.format("[custom-float] Could not get state for source: %s", source),
        vim.log.levels.ERROR
      )
    end
    return
  end

  -- CRITICAL: Neo-tree expects position to be a table, not a string
  -- See neo-tree/ui/renderer.lua:704 - it indexes state.position[...]
  if type(neo_state.position) ~= "table" then
    neo_state.position = {
      current = "float",
      default = "float",
    }
  end

  -- Set current position
  neo_state.current_position = "float"

  -- Ensure window is set in state
  neo_state.winid = float_state.win
  neo_state.bufnr = float_state.buf

  if cfg.debug then
    vim.notify(
      string.format(
        "[custom-float] Rendering source=%s reveal=%s dir=%s restore=%s",
        source,
        tostring(reveal_file or "nil"),
        tostring(dir or "nil"),
        tostring(cfg.restore_last_position)
      ),
      vim.log.levels.DEBUG
    )
  end

  vim.schedule(function()
    -- Use renderer directly instead of navigate
    local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
    if not ok_renderer then
      if cfg.debug then
        vim.notify("[custom-float] Could not load renderer", vim.log.levels.ERROR)
      end
      return
    end

    -- Restore tree state first if in restore mode
    if cfg.restore_last_position and neo_state.tree then
      tree_state.restore_state(neo_state.tree)

      if cfg.debug then
        vim.notify("[custom-float] Restored tree state", vim.log.levels.DEBUG)
      end
    end

    -- Determine the path to show
    local target_path
    if cfg.restore_last_position then
      -- Restore mode: use last known path or cwd
      target_path = neo_state.path or vim.loop.cwd() or vim.fn.getcwd()
    else
      -- Reveal mode: use provided paths
      target_path = reveal_file or dir or vim.loop.cwd() or vim.fn.getcwd()
    end

    -- Ensure valid string path
    if type(target_path) ~= "string" or target_path == "" then
      target_path = vim.fn.getcwd()
    end

    if cfg.debug then
      vim.notify(
        string.format("[custom-float] Target path: %s", target_path),
        vim.log.levels.DEBUG
      )
    end

    -- Show the source with target path
    local show_opts = {
      state = neo_state,
      source = source,
      path = target_path,
      reveal_file = reveal_file,
      dir = dir,
    }

    -- Call show on the source
    local ok_show = pcall(manager.show, source, show_opts)

    if not ok_show then
      if cfg.debug then
        vim.notify("[custom-float] Show failed, trying basic render", vim.log.levels.WARN)
      end

      -- Fallback: just render current state
      pcall(renderer.redraw, neo_state)
    elseif cfg.debug then
      vim.notify("[custom-flat] Content rendered successfully", vim.log.levels.DEBUG)
    end
  end)
end

-- ============================================================================
-- Keymap Setup
-- ============================================================================

---Setup close keymaps for float window
local function setup_close_keymaps()
  if not float_state.buf or not vim.api.nvim_buf_is_valid(float_state.buf) then
    return
  end

  local opts = { buffer = float_state.buf, nowait = true, silent = true }

  -- Standard close keys
  vim.keymap.set("n", "q", function()
    M.close(function() end)
  end, vim.tbl_extend("force", opts, { desc = "Close float window" }))

  vim.keymap.set("n", "<Esc>", function()
    M.close(function() end)
  end, vim.tbl_extend("force", opts, { desc = "Close float window" }))

  -- Also close on <C-c>
  vim.keymap.set("n", "<C-c>", function()
    M.close(function() end)
  end, vim.tbl_extend("force", opts, { desc = "Close float window" }))
end

-- ============================================================================
-- Auto-cleanup on Window Close
-- ============================================================================

---Setup autocmd to cleanup when window is closed manually
---@param win integer
local function setup_cleanup_autocmd(win)
  -- CRITICAL: Don't use WinClosed - it triggers too early!
  -- Instead, poll for window validity asynchronously
  local cleanup_group = vim.api.nvim_create_augroup("CustomFloatCleanup_" .. win, { clear = true })

  -- Stop any existing timer
  if float_state.cleanup_timer then
    float_state.cleanup_timer:stop()
    float_state.cleanup_timer:close()
    float_state.cleanup_timer = nil
  end

  -- Check periodically if window was closed externally (not by M.close)
  local check_timer = vim.uv.new_timer()
  if not check_timer then return end

  float_state.cleanup_timer = check_timer

  check_timer:start(500, 500, vim.schedule_wrap(function()
    -- If window is invalid AND we still think it's open → external close
    if float_state.win == win and not vim.api.nvim_win_is_valid(win) then
      -- Stop timer
      if check_timer and not check_timer:is_closing() then
        check_timer:stop()
        check_timer:close()
      end

      float_state.cleanup_timer = nil

      -- Capture state before cleanup
      if cfg.restore_last_position then
        local ok, manager = pcall(require, "neo-tree.sources.manager")
        if ok then
          local neo_state = manager.get_state(float_state.source)
          if neo_state and neo_state.tree then
            tree_state.capture_state(neo_state)
          end
        end
      end

      -- Clear state
      float_state.win = nil
      state.set_closed("custom_float_closed_external")
      require("config.neotree.open.window.float").set_open_state(false)

      -- Cleanup autocmd group
      pcall(vim.api.nvim_del_augroup_by_name, "CustomFloatCleanup_" .. win)

      if cfg.debug then
        vim.notify("[custom-float] Window closed externally", vim.log.levels.DEBUG)
      end
    end
  end))

  -- Fallback: Also listen to BufUnload as secondary signal
  vim.api.nvim_create_autocmd("BufUnload", {
    group = cleanup_group,
    buffer = float_state.buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if check_timer and not check_timer:is_closing() then
          check_timer:stop()
          check_timer:close()
        end
        float_state.cleanup_timer = nil
      end)
    end,
  })
end
-- ============================================================================
-- Public API
-- ============================================================================

---Open custom float window with Neo-tree content
---@param source string Source name (e.g., "filesystem", "buffers")
---@param callback fun(success: boolean)
function M.open(source, callback)
  -- Check if already open and valid
  if float_state.win and vim.api.nvim_win_is_valid(float_state.win) then
    -- Same source - just focus
    if float_state.source == source then
      pcall(vim.api.nvim_set_current_win, float_state.win)

      if cfg.debug then
        vim.notify("[custom-float] Reusing existing window", vim.log.levels.DEBUG)
      end

      callback(true)
      return
    end

    -- Different source - close and reopen
    M.close(function()
      vim.schedule(function()
        M.open(source, callback)
      end)
    end)
    return
  end

  -- Update global state
  state.set_open("float", source, cfg.restore_last_position and "restore" or "reveal")

  -- Get buffer context for reveal
  local ctx = buffer_utils.get_buffer_context()

  -- Create window
  local win = create_float_window(source)

  if not win then
    state.set_closed("custom_float_create_failed")
    callback(false)
    return
  end

  -- Setup keymaps
  setup_close_keymaps()

  -- Setup cleanup autocmd
  setup_cleanup_autocmd(win)

  -- Render Neo-tree content
  vim.schedule(function()
    local reveal_file = nil
    local dir = nil

    if not cfg.restore_last_position then
      -- Reveal mode: get context from buffer
      if ctx then
        reveal_file = ctx.file
        dir = ctx.dir
      end

      -- Fallback: use current buffer path
      if not reveal_file and not dir then
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(bufnr) then
          local bufpath = vim.api.nvim_buf_get_name(bufnr)
          if bufpath and bufpath ~= "" then
            reveal_file = bufpath
          end
        end
      end
    end

    if cfg.debug then
      vim.notify(
        string.format(
          "[custom-float] Render params: reveal_file=%s dir=%s restore=%s",
          tostring(reveal_file or "nil"),
          tostring(dir or "nil"),
          tostring(cfg.restore_last_position)
        ),
        vim.log.levels.DEBUG
      )
    end

    render_neotree_content(source, reveal_file, dir)

    -- Update float state module
    require("config.neotree.open.window.float").set_open_state(true)

    if cfg.debug then
      vim.notify("[custom-float] Opened successfully", vim.log.levels.INFO)
    end

    callback(true)
  end)
end

---Close custom float window
---@param callback fun(success: boolean)
function M.close(callback)
  if not float_state.win or not vim.api.nvim_win_is_valid(float_state.win) then
    if cfg.debug then
      vim.notify("[custom-float] Already closed", vim.log.levels.DEBUG)
    end
    callback(true)
    return
  end

  -- Capture tree state if in restore mode
  if cfg.restore_last_position then
    local ok, manager = pcall(require, "neo-tree.sources.manager")
    if ok then
      local neo_state = manager.get_state(float_state.source)
      if neo_state and neo_state.tree then
        tree_state.capture_state(neo_state)

        if cfg.debug then
          vim.notify("[custom-float] Captured tree state", vim.log.levels.DEBUG)
        end
      end
    end
  end

  -- Close window
  local win = float_state.win
  pcall(vim.api.nvim_win_close, win, true)

  -- Clear state
  float_state.win = nil
  state.set_closed("custom_float_close")
  require("config.neotree.open.window.float").set_open_state(false)

  if cfg.debug then
    vim.notify("[custom-float] Closed", vim.log.levels.INFO)
  end

  callback(true)
end

---Check if custom float is currently open
---@return boolean
function M.is_open()
  return float_state.win ~= nil and vim.api.nvim_win_is_valid(float_state.win)
end

---Get current float window ID
---@return integer|nil
function M.get_window()
  return float_state.win
end

---Get current buffer ID
---@return integer|nil
function M.get_buffer()
  return float_state.buf
end

---Force reset float state (recovery)
function M.reset()
  if float_state.win and vim.api.nvim_win_is_valid(float_state.win) then
    pcall(vim.api.nvim_win_close, float_state.win, true)
  end

  float_state.win = nil
  float_state.buf = nil
  float_state.source = "filesystem"

  state.set_closed("custom_float_reset")
  require("config.neotree.open.window.float").set_open_state(false)

  if cfg.debug then
    vim.notify("[custom-float] Force reset", vim.log.levels.INFO)
  end
end

return M
