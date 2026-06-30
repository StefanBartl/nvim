---@module 'config.neotree.cwd_sync.sync_executor'
---@brief Core sync execution with window validation

local state = require("config.neotree.cwd_sync.state")
local buffer_utils = require("config.neotree.utils.buffer")
local resolver = require("config.neotree.cwd_sync.buffer_resolver")

local M = {}

---Find valid Neo-tree window in current tab
---@return integer|nil win
local function find_neotree_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        return win
      end
    end
  end
  return nil
end

---Execute sync with full window validation
---@param cfg Cfg.NeoTree.CwdSync.Config
function M.execute(cfg)
  if state.is_paused() then
    return
  end

  -- CRITICAL: Validate Neo-tree window BEFORE executing
  local neo_win = find_neotree_win()

  if not neo_win and not cfg.open_if_closed then
    return -- No window and shouldn't open
  end

  -- Validate window is still valid after debounce
  if neo_win and not vim.api.nvim_win_is_valid(neo_win) then
    neo_win = nil
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  if not buffer_utils.is_valid_file_buffer(cur_buf) then
    return
  end

  local dir, path = resolver.resolve(
    cur_buf,
    cfg.use_project_root,
    cfg.project_root_fallback_to_bufdir
  )

  if not dir or dir == "" or not path or path == "" then
    return
  end

  -- Skip if already synced
  if state.is_already_synced(dir, path) then
    return
  end

  if cfg.also_set_nvim_cwd then
    pcall(vim.api.nvim_set_current_dir, dir)
  end

  local ok_cmd, cmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    return
  end

  ---@type integer|nil
  local prev_win = vim.api.nvim_get_current_win()

  -- Validate previous window
  if prev_win and not vim.api.nvim_win_is_valid(prev_win) then
    prev_win = nil
  end

  -- Execute inside pcall with window validation
  local ok = pcall(function()
    -- Re-validate Neo-tree window inside execution context
    local exec_win = find_neotree_win()

    if not exec_win and cfg.open_if_closed then
      -- Open new Neo-tree window first
      cmd.execute({
        action = "show",
        source = "filesystem",
        position = require("config.neotree").get_default_position(),
      })

      -- Wait for window creation
      vim.wait(100, function()
        return find_neotree_win() ~= nil
      end)

      exec_win = find_neotree_win()
    end

    if not exec_win then
      error("No valid Neo-tree window for sync")
    end

    -- Execute with validated window context
    cmd.execute({
      action = "show",
      source = "filesystem",
      position = require("config.neotree").get_default_position(),
      dir = dir,
      reveal = true,
      reveal_file = path,
    })
  end)

  if ok then
    state.mark_synced(dir, path)
  end

  -- Restore focus with validation
  if cfg.keep_focus and prev_win and vim.api.nvim_win_is_valid(prev_win) then
    pcall(vim.api.nvim_set_current_win, prev_win)
  end
end

return M
