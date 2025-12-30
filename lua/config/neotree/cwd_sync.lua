---@module 'config.neotree.cwd_sync'
--- Keeps Neo-tree's filesystem root in sync with the active buffer's directory or project root.
--- Cross-platform (uses vim.uv or vim.loop); non-intrusive (keeps focus by default).
--- Debounced event handling for frequent window/buffer switches. Enforces a deterministic
--- left-positioned filesystem view when configured to avoid accidental right-pane openings.

local M = {}

---@type NeoTreeCwdSyncState
local S = {
  timer = nil,
  pending = false,
  last_dir = nil,
  user_navigated = false,  -- ADDED: Track manual navigation
  last_user_action = 0,    -- ADDED: Timestamp of last user action
}

--- Query the current filesystem source window position, if any.
---@nodiscard
---@return NeoTreePosition|nil
local function current_fs_position()
  local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
  if not ok_mgr then
    return nil
  end
  local st = manager.get_state and manager.get_state("filesystem") or nil
  return (st and st.window and st.window.position) or nil
end

--- Get or create a one-shot uv timer (module-local).
---@nodiscard
---@return uv.uv_timer_t
local function get_timer()
  -- Use vim.uv on Neovim >= 0.10, fall back to vim.loop for older setups
  local uv = vim.uv or vim.loop
  if not S.timer then
    ---@type any  -- lua_ls: uv types are not fully modeled
    S.timer = uv.new_timer()
  end
  return S.timer --[[@as uv.uv_timer_t]]
end

--- Determine if a buffer is a "real" file buffer we want to react to.
---@nodiscard
---@param buf integer
---@return boolean
local function is_real_file_buffer(buf)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  local bt = vim.bo[buf].buftype
  if bt ~= "" then
    return false
  end -- skip terminal/help/quickfix/etc.
  local name = vim.api.nvim_buf_get_name(buf)
  if not name or name == "" then
    return false
  end -- [No Name]
  -- Accept readable files and directory-like buffers (edge-cases such as netrw)
  return vim.fn.filereadable(name) == 1 or vim.fn.isdirectory(name) == 1
end

--- Find an open Neo-tree window within the current tabpage (if any).
---@nodiscard
---@return integer|nil
local function find_neotree_win_in_current_tab()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for i = 1, #wins do
    local win = wins[i]
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      return win
    end
  end
  return nil
end

--- Compute target directory (project or buffer dir) and the buffer path for reveal.
---@nodiscard
---@param buf integer
---@param use_project_root boolean
---@param fallback_to_bufdir boolean
---@return string|nil dir
---@return string|nil path
local function derive_dir_and_path(buf, use_project_root, fallback_to_bufdir)
  local path = vim.api.nvim_buf_get_name(buf)
  if not path or path == "" then
    return nil, nil
  end

  local dir ---@type string|nil

  if use_project_root then
    local ok, Root = pcall(require, "utils.lv_project_root")
    if ok and type(Root.get) == "function" then
      dir = Root.get(buf)
    end
  end

  if (not dir or dir == "") and fallback_to_bufdir then
    dir = vim.fn.fnamemodify(path, ":p:h")
  end

  return dir, path
end

--- Perform the immediate synchronization. Keeps focus if configured.
---@param cfg NeoTreeCwdSyncConfig
local function sync_now(cfg)
  local neo_win = find_neotree_win_in_current_tab()

  if neo_win and not vim.api.nvim_win_is_valid(neo_win) then
    neo_win = nil
  end

  if not neo_win and not cfg.open_if_closed then
    return
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  if not is_real_file_buffer(cur_buf) then
    return
  end

  local dir, path = derive_dir_and_path(cur_buf, cfg.use_project_root, cfg.project_root_fallback_to_bufdir)
  if not dir or dir == "" then
    return
  end

  if S.last_dir == dir then
    return
  end

  if cfg.also_set_nvim_cwd then
    pcall(vim.api.nvim_set_current_dir, dir)
  end

  local ok_cmd, cmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    return
  end

  local prev_win = vim.api.nvim_get_current_win()

  if not vim.api.nvim_win_is_valid(prev_win) then
    prev_win = nil
  end

  local pos = current_fs_position()

  -- MODIFIED: Only normalize position if explicitly wrong AND we have a window
  if neo_win and pos and cfg.force_position_left and pos ~= "left" then
    -- ADDED: Check if there's actually a Neo-tree window on the right
    local has_right_neo = false
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if win ~= neo_win and vim.api.nvim_win_is_valid(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "neo-tree" then
          local win_pos = vim.api.nvim_win_get_position(win)
          local cur_win_pos = vim.api.nvim_win_get_position(neo_win)
          if win_pos[2] > cur_win_pos[2] then
            has_right_neo = true
            break
          end
        end
      end
    end

    -- ADDED: Only relocate if there's actually a problematic right window
    if has_right_neo then
      local ok = pcall(function()
        -- Close the right one first
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if win ~= neo_win and vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "neo-tree" then
              pcall(vim.api.nvim_win_close, win, true)
            end
          end
        end

        -- Then ensure left position
        cmd.execute({
          action = "show",
          source = "filesystem",
          position = "left",
          dir = dir,
          reveal = true,
          reveal_file = path,
        })
      end)

      if ok then
        S.last_dir = dir
      end

      if cfg.keep_focus and prev_win and vim.api.nvim_win_is_valid(prev_win) then
        pcall(vim.api.nvim_set_current_win, prev_win)
      end
      return
    end
  end

  -- Normal path: just reveal without repositioning
  local ok = pcall(function()
    cmd.execute({
      action = "show",
      source = "filesystem",
      dir = dir,
      reveal = true,
      reveal_file = path,
    })
  end)

  if ok then
    S.last_dir = dir
  end

  if cfg.keep_focus and prev_win and vim.api.nvim_win_is_valid(prev_win) then
    pcall(vim.api.nvim_set_current_win, prev_win)
  end
end

--- Debounced scheduling facade around sync_now().
---@param cfg NeoTreeCwdSyncConfig
local function schedule_sync(cfg)
  local timer = get_timer()
  timer:stop()

  -- Don't sync if user just navigated manually
  local time_since_action = vim.loop.now() - S.last_user_action
  if S.user_navigated and time_since_action < 2000 then
    return
  end

  timer:start(cfg.debounce_ms, 0, function()
    vim.schedule(function()
      -- Reset flag after delay
      if vim.loop.now() - S.last_user_action > 2000 then
        S.user_navigated = false
      end
      sync_now(cfg)
    end)
  end)
end

--- Public setup entry-point. Creates autocmds and manages lifecycle.
---@param user_cfg NeoTreeCwdSyncConfig|nil
---@return nil
function M.setup(user_cfg)
  ---@type NeoTreeCwdSyncConfig
  local cfg = vim.tbl_extend("force", {
    debounce_ms = 80,
    keep_focus = true,
    also_set_nvim_cwd = false,
    open_if_closed = false,
    use_project_root = true,
    project_root_fallback_to_bufdir = true,
    force_position_left = true, -- normalize existing filesystem view to "left" if different
  }, user_cfg or {})

  local aug = vim.api.nvim_create_augroup("NeoTreeCwdSync", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TabEnter" }, {
    group = aug,
    callback = function()
      schedule_sync(cfg)
    end,
    desc = "Sync Neo-tree filesystem root with the active buffer's directory/project",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      if S.timer then
        ---@diagnostic disable-next-line: undefined-field
        pcall(S.timer.stop, S.timer)
        ---@diagnostic disable-next-line: undefined-field
        pcall(S.timer.close, S.timer)
        S.timer = nil
      end
    end,
    desc = "Cleanup NeoTreeCwdSync timer",
  })
end

return M
