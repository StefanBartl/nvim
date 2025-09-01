---@module 'config.neotree.cwd_sync'
--- Keeps Neo-tree's filesystem root in sync with the active buffer's directory or project root.
--- Cross-platform (uses vim.uv or vim.loop); non-intrusive (keeps focus by default).
--- Debounced event handling for frequent window/buffer switches.

---@class NeoTreeCwdSyncConfig
---@field debounce_ms integer        # Debounce for event storms (milliseconds)
---@field keep_focus boolean         # Restore previous window after syncing
---@field also_set_nvim_cwd boolean  # Also run :cd to the derived directory
---@field open_if_closed boolean     # Open Neo-tree if no window is open
---@field use_project_root boolean   # Try utils.lv_project_root first
---@field project_root_fallback_to_bufdir boolean # Fallback to buffer dir if project root is nil

---@class NeoTreeCwdSyncState
---@field timer uv.uv_timer_t|nil    # libuv timer handle or nil
---@field pending boolean|nil
---@field last_dir string|nil

local M = {}

---@type NeoTreeCwdSyncState
local S = { timer = nil, pending = false, last_dir = nil }

---@nodiscard
---@return uv.uv_timer_t
local function get_timer()
  -- Use vim.uv on Neovim >= 0.10, fall back to vim.loop for older setups
  local uv = vim.uv or vim.loop
  if not S.timer then
    ---@type any  -- sedative placebo for lua_ls
    S.timer = uv.new_timer()
  end
  return S.timer --[[@as uv.uv_timer_t]]
end

---@nodiscard
---@param buf integer
---@return boolean
local function is_real_file_buffer(buf)
  if buf == 0 then buf = vim.api.nvim_get_current_buf() end
  local bt = vim.bo[buf].buftype
  if bt ~= "" then return false end
  local name = vim.api.nvim_buf_get_name(buf)
  if not name or name == "" then return false end
  return vim.fn.filereadable(name) == 1 or vim.fn.isdirectory(name) == 1
end

---@nodiscard
---@return integer|nil
local function find_neotree_win_in_current_tab()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      return win
    end
  end
  return nil
end

---@nodiscard
---@param buf integer
---@param use_project_root boolean
---@param fallback_to_bufdir boolean
---@return string|nil dir, string|nil path
local function derive_dir_and_path(buf, use_project_root, fallback_to_bufdir)
  local path = vim.api.nvim_buf_get_name(buf)
  if not path or path == "" then return nil, nil end

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

---@param cfg NeoTreeCwdSyncConfig
local function sync_now(cfg)
  local neo_win = find_neotree_win_in_current_tab()
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

  -- Remember focus and apply update via action="show"
  local prev_win = vim.api.nvim_get_current_win()
  local params = {
    action = "show",
    source = "filesystem",
    dir = dir,
    reveal = true,
    reveal_file = path,
  }

  local ok = pcall(cmd.execute, params)
  if ok then
    S.last_dir = dir
  end

  if cfg.keep_focus and vim.api.nvim_win_is_valid(prev_win) then
    pcall(vim.api.nvim_set_current_win, prev_win)
  end
end

---@param cfg NeoTreeCwdSyncConfig
local function schedule_sync(cfg)
  ---@type uv.uv_timer_t
  local timer = get_timer()
  timer:stop()
  -- one-shot timer to debounce frequent events
  timer:start(cfg.debounce_ms, 0, function()
    -- Ensure we jump back into the main scheduler to avoid UI reentrancy
    vim.schedule(function()
      sync_now(cfg)
    end)
  end)
end

--- Public setup
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
        pcall(S.timer.stop, S.timer)
        pcall(S.timer.close, S.timer)
        S.timer = nil
      end
    end,
    desc = "Cleanup NeoTreeCwdSync timer",
  })
end

return M
