---@module 'config.neotree.cwd_sync'
--- Keeps Neo-tree's filesystem root in sync with the active buffer's directory or project root.
--- Cross-platform (uses vim.uv or vim.loop); non-intrusive (keeps focus by default).

local buffer_utils = require('config.neotree.utils.buffer')

local M = {}

---@type Cfg.NeoTree.CwdSyncState
local S = {
  timer = nil,
  pending = false,
  last_dir = nil,
  last_file = nil,
  user_navigated = false,
  last_user_action = 0,
  pause_until = 0,
  sync_scheduled = false,
}

---Pause sync for specified duration
---@param ms integer Milliseconds to pause
function M.pause_sync(ms)
  S.pause_until = vim.loop.now() + ms
  S.user_navigated = true
  S.last_user_action = vim.loop.now()
end

local function get_timer()
  local uv = vim.uv or vim.loop
  if not S.timer then
    ---@type userdata|uv.uv_timer_t|nil
    S.timer = uv.new_timer()
  end
  return S.timer
end


local function find_neotree_win_in_current_tab()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neo-tree" then
        return win
      end
    end
  end
  return nil
end

local function derive_dir_and_path(buf, use_project_root, _)
  local ctx = buffer_utils.get_buffer_context(buf)
  if not ctx then
    return nil, nil
  end

  local dir = ctx.dir

  if use_project_root then
    local ok, Root = pcall(require, "config.neotree.helper.lv_project_root")
    if ok and type(Root.get) == "function" then
      local root = Root.get(buf)
      if root and root ~= "" then
        dir = root
      end
    end
  end

  return dir, ctx.file
end

local function sync_now(cfg)
  if vim.loop.now() < S.pause_until then
    return
  end

  local neo_win = find_neotree_win_in_current_tab()

  if neo_win and not vim.api.nvim_win_is_valid(neo_win) then
    neo_win = nil
  end

  if not neo_win and not cfg.open_if_closed then
    return
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  if not buffer_utils.is_valid_file_buffer(cur_buf) then
    return
  end

  local dir, path = derive_dir_and_path(cur_buf, cfg.use_project_root, cfg.project_root_fallback_to_bufdir)
  if not dir or dir == "" or not path or path == "" then
    return
  end

  if S.last_dir == dir and S.last_file == path then
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

  local ok = pcall(function()
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
    S.last_file = path
  end

  if cfg.keep_focus and prev_win and vim.api.nvim_win_is_valid(prev_win) then
    pcall(vim.api.nvim_set_current_win, prev_win)
  end
end

local function schedule_sync(cfg)
  if S.sync_scheduled then
    return
  end
  S.sync_scheduled = true

  local timer = get_timer()
   if not timer then
     vim.notify("timer is nil")
     return nil
   end
  timer:stop()

  -- Check pause before scheduling
  if vim.loop.now() < S.pause_until then
    S.sync_scheduled = false
    return
  end

  timer:start(cfg.debounce_ms, 0, function()
    vim.schedule(function()
      S.sync_scheduled = false -- ✅ Reset

      -- Double-check pause
      if vim.loop.now() < S.pause_until then
        return
      end

      -- Reset user_navigated after cooldown
      local time_since_action = vim.loop.now() - S.last_user_action
      if S.user_navigated and time_since_action > 2000 then
        S.user_navigated = false
      end

      sync_now(cfg)
    end)
  end)
end

function M.setup(user_cfg)
  local cfg = vim.tbl_extend("force", {
    debounce_ms = 150,
    keep_focus = true,
    also_set_nvim_cwd = false,
    open_if_closed = false,
    use_project_root = true,
    project_root_fallback_to_bufdir = true,
  }, user_cfg or {})

  local aug = vim.api.nvim_create_augroup("NeoTreeCwdSync", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = aug,
    callback = function()
      schedule_sync(cfg)
    end,
    desc = "Sync Neo-tree with current buffer (reveal)",
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
