---@module 'config.neotree.cwd_sync'
--- Keeps Neo-tree's filesystem root in sync with the active buffer's directory or project root.
--- Cross-platform (uses vim.uv or vim.loop); non-intrusive (keeps focus by default).
--- Debounced event handling for frequent window/buffer switches. Enforces a deterministic
--- left-positioned filesystem view when configured to avoid accidental right-pane openings.

local M = {}

---@type NeoTreeCwdSyncState
local S = { timer = nil, pending = false, last_dir = nil }

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
  if not neo_win and not cfg.open_if_closed then
    -- No filesystem view in this tab and opening is disabled → nothing to do.
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

  -- Avoid redundant updates if the directory hasn't changed.
  if S.last_dir == dir then
    return
  end

  -- Optionally keep Neovim's CWD in sync as well (best-effort).
  if cfg.also_set_nvim_cwd then
    pcall(vim.api.nvim_set_current_dir, dir)
  end

  local ok_cmd, cmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    return
  end

  -- Remember current window to restore focus afterwards (non-intrusive UX).
  local prev_win = vim.api.nvim_get_current_win()

  -- If there is already a filesystem view and it's not on the left, normalize it to "left".
  -- This prevents accidental "right" panes from lingering (e.g., due to mappings or layout toggles).
  local pos = current_fs_position()
  if pos and cfg.force_position_left and pos ~= "left" then
    -- Use action="show" with explicit position="left" to relocate without stealing focus permanently.
    pcall(cmd.execute, {
      action = "show",
      source = "filesystem",
      position = "left", -- enforce left position
      dir = dir,
      reveal = true,
      reveal_file = path,
    })
    S.last_dir = dir
    if cfg.keep_focus and vim.api.nvim_win_is_valid(prev_win) then
      pcall(vim.api.nvim_set_current_win, prev_win)
    end
    return
  end

  -- Default path: show/update filesystem view in place (do not specify position so existing layout remains).
  local ok = pcall(cmd.execute, {
    action = "show",
    source = "filesystem",
    dir = dir,
    reveal = true,
    reveal_file = path,
  })
  if ok then
    S.last_dir = dir
  end

  if cfg.keep_focus and vim.api.nvim_win_is_valid(prev_win) then
    pcall(vim.api.nvim_set_current_win, prev_win)
  end
end

--- Debounced scheduling facade around sync_now().
---@param cfg NeoTreeCwdSyncConfig
local function schedule_sync(cfg)
  ---@type uv.uv_timer_t
  local timer = get_timer()
  ---@diagnostic disable-next-line: undefined-field  -- provided by libuv
  timer:stop()
  -- One-shot timer to debounce frequent events (BufEnter/WinEnter/TabEnter).
  ---@diagnostic disable-next-line: undefined-field
  timer:start(cfg.debounce_ms, 0, function()
    -- Hop back into the main loop to avoid UI reentrancy pitfalls.
    vim.schedule(function()
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
