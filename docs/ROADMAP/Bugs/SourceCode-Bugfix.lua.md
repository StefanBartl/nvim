-- ============================================================================
-- BUG FIX 1: EPERM Error beim Trash (friert Neovim ein)
-- ============================================================================
-- Problem: File watchers bleiben aktiv und verursachen EPERM errors
-- Lösung: Watchers früher stoppen und besseres Error handling

-- File: lua/config/neotree/trash.lua
-- Ersetze die cleanup_neotree_watchers Funktion:

---@param path string
local function cleanup_neotree_watchers(path)
  -- Stop ALL filesystem watchers before deletion
  pcall(function()
    local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
    if watcher and watcher.stop_all then
      watcher.stop_all()
    elseif watcher and watcher.stop then
      watcher.stop(path)
      -- Stop parent watchers too
      local parent = vim.fn.fnamemodify(path, ":h")
      watcher.stop(parent)
    end
  end)

  -- Clear manager state BEFORE deletion
  pcall(function()
    local manager = require("neo-tree.sources.manager")
    if manager and manager.close_all_nodes then
      manager.close_all_nodes()
    end
    -- Force clear internal state
    if manager and manager._state then
      manager._state = {}
    end
  end)
end

-- Ersetze die safe_refresh Funktion mit besserem Error handling:

local function safe_refresh(state_name)
  -- Longer delay to ensure file operations complete
  vim.defer_fn(function()
    local manager_ok, manager = pcall(require, "neo-tree.sources.manager")
    if not manager_ok then
      return
    end

    -- Complete cleanup first
    pcall(function()
      if manager.close_all_nodes then
        manager.close_all_nodes()
      end
    end)

    -- Wait for filesystem to settle
    vim.defer_fn(function()
      local state_ok, state = pcall(manager.get_state, state_name)
      if state_ok and state then
        -- Suppress EPERM errors during refresh
        local old_notify = vim.notify
        vim.notify = function(msg, level)
          if not (type(msg) == "string" and msg:match("EPERM")) then
            old_notify(msg, level)
          end
        end

        local commands_ok, commands = pcall(require, "neo-tree.sources." .. state_name .. ".commands")
        if commands_ok and commands and type(commands.refresh) == "function" then
          pcall(commands.refresh, state)
        else
          pcall(manager.refresh, state_name)
        end

        -- Restore notify after 1 second
        vim.defer_fn(function()
          vim.notify = old_notify
        end, 1000)
      end
    end, 300)
  end, 100)
end


-- ============================================================================
-- BUG FIX 2: Error nach Folder Renaming (Invalid 'window')
-- ============================================================================
-- Problem: Window handle wird invalid während follow/navigate
-- Lösung: Window validation in cwd_sync.lua

-- File: lua/config/neotree/cwd_sync.lua
-- Ersetze die sync_now Funktion:

local function sync_now(cfg)
  local neo_win = find_neotree_win_in_current_tab()

  -- ADDED: Validate window before proceeding
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

  -- ADDED: Validate prev_win
  if not vim.api.nvim_win_is_valid(prev_win) then
    prev_win = nil
  end

  local pos = current_fs_position()
  if pos and cfg.force_position_left and pos ~= "left" then
    -- ADDED: Protected call with window validation
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
    end

    if cfg.keep_focus and prev_win and vim.api.nvim_win_is_valid(prev_win) then
      pcall(vim.api.nvim_set_current_win, prev_win)
    end
    return
  end

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


-- ============================================================================
-- BUG FIX 3: Preview Error (truth field nil) & Buffer-als-Tab Problem
-- ============================================================================
-- Problem: Preview system breaks when Neo-tree is shown as buffer
-- Lösung: Besseres Preview handling in keymaps

-- File: lua/config/neotree/keymaps/init.lua
-- Ersetze die <CR> mapping:

["<CR>"] = function(state)
  local node = state.tree:get_node()
  if not node then
    return
  end

  -- ADDED: Check if we're in a valid Neo-tree window
  local current_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(current_win)
  local is_neotree_win = vim.bo[buf].filetype == "neo-tree"

  if not is_neotree_win then
    vim.notify("Neo-tree: Not in a Neo-tree window", vim.log.levels.WARN)
    return
  end

  -- ADDED: Safe preview cleanup
  pcall(function()
    local preview = require("neo-tree.sources.common.preview")
    if preview and preview.hide then
      preview.hide()
    end
  end)

  -- 1) expand/collapse directories
  if node and (node.type == "directory" or (node:has_children() and not node:is_expanded())) then
    state.commands.toggle_node(state)
    return
  end

  -- 2) normal open (prefer window-picker if present)
  if pcall(require, "window-picker") then
    -- ADDED: Protect window-picker call
    local ok = pcall(state.commands.open_with_window_picker, state)
    if not ok then
      pcall(state.commands.open, state)
    end
  else
    pcall(state.commands.open, state)
  end
end,

-- Ersetze auch die <Tab> mapping für Preview:

["<Tab>"] = function(state)
  -- ADDED: Validate window context
  local current_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(current_win)

  if vim.bo[buf].filetype ~= "neo-tree" then
    vim.notify("Neo-tree: Preview only works in Neo-tree window", vim.log.levels.WARN)
    return
  end

  -- ADDED: Safe toggle with error handling
  local ok, err = pcall(function()
    state.commands.toggle_preview(state)
  end)

  if not ok then
    -- Fallback: try to hide preview
    pcall(function()
      local preview = require("neo-tree.sources.common.preview")
      if preview and preview.hide then
        preview.hide()
      end
    end)
  end
end,


-- ============================================================================
-- BUG FIX 4: Neotree fällt auf CWD root zurück
-- ============================================================================
-- Problem: reveal_file passiert zu oft und überschreibt updir navigation
-- Lösung: Bessere Logik in cwd_sync

-- File: lua/config/neotree/cwd_sync.lua
-- Füge State-Tracking hinzu (am Anfang der Datei nach local S):

local S = {
  timer = nil,
  pending = false,
  last_dir = nil,
  user_navigated = false,  -- ADDED: Track manual navigation
  last_user_action = 0,    -- ADDED: Timestamp of last user action
}

-- Ersetze schedule_sync mit smarter Logic:

local function schedule_sync(cfg)
  local timer = get_timer()
  timer:stop()

  -- ADDED: Don't sync if user just navigated manually
  local time_since_action = vim.loop.now() - S.last_user_action
  if S.user_navigated and time_since_action < 2000 then
    return
  end

  timer:start(cfg.debounce_ms, 0, function()
    vim.schedule(function()
      -- ADDED: Reset flag after delay
      if vim.loop.now() - S.last_user_action > 2000 then
        S.user_navigated = false
      end
      sync_now(cfg)
    end)
  end)
end

-- File: lua/config/neotree/updir.lua
-- Markiere updir als User-Navigation:

function M.up_one_level(state)
  -- ADDED: Mark as user navigation to prevent auto-sync
  local ok_sync, sync_state = pcall(require, "config.neotree.cwd_sync")
  if ok_sync and sync_state and sync_state.S then
    sync_state.S.user_navigated = true
    sync_state.S.last_user_action = vim.loop.now()
  end

  -- ... rest of existing code ...

  local current_root = state.path
  if not current_root or current_root == "" then
    local node = state.tree:get_node()
    local path = node and (node.path or node:get_id()) or ""
    if path == "" then
      vim.notify("no path under cursor", vim.log.levels.WARN)
      return
    end
    current_root = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
  end

  local parent = vim.fn.fnamemodify(current_root, ":h")
  if parent == current_root or parent == "" then
    vim.notify("already at top-level directory", vim.log.levels.WARN)
    return
  end

  local position = (state.window and state.window.position) or "left"
  local cd_cmd = (position == "current" or position == "float") and "lcd" or "cd"
  local esc = vim.fn.fnameescape(parent)

  local ok_cd, cd_err = pcall(function()
    vim.cmd(string.format("%s %s", cd_cmd, esc))
  end)
  if not ok_cd then
    vim.notify(("cwd change failed: %s"):format(tostring(cd_err)), vim.log.levels.ERROR)
    return
  end

  if state.commands and state.commands.navigate_up then
    state.commands.navigate_up(state)
  elseif state.commands and state.commands.set_root then
    state.commands.set_root(state, parent)
  else
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if ok_mgr then
      manager.navigate(state, parent)
    else
      vim.notify("neo-tree: no suitable command to change root", vim.log.levels.ERROR)
      return
    end
  end

  local ok_mod, refresher = pcall(require, "config.neotree.refresh_adapter")
  if ok_mod then
    refresher.refresh(state)
  else
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if ok_mgr and manager and type(manager.refresh) == "function" then
      local src = (type(state) == "table" and (state.name or state.source or state.source_name)) or "filesystem"
      manager.refresh(src)
    end
  end

  vim.notify(("cwd → %s"):format(parent), vim.log.levels.INFO)
end


-- ============================================================================
-- BUG FIX 5: Linker Neo-tree schließt sich und öffnet sich rechts
-- ============================================================================
-- Problem: force_position_left greift zu aggressiv
-- Lösung: Bessere Position-Locking Logic

-- File: lua/config/neotree/cwd_sync.lua
-- Ersetze die Position-Normalisierung:

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


-- ============================================================================
-- KONFIGURATION: Angepasste Setup-Parameter
-- ============================================================================

-- File: lua/plugins/neotree.lua
-- Passe die cwd_sync Konfiguration an:

require("config.neotree.cwd_sync").setup({
  debounce_ms = 150,              -- INCREASED: More time for manual navigation
  keep_focus = true,
  also_set_nvim_cwd = false,
  open_if_closed = false,
  use_project_root = true,
  project_root_fallback_to_bufdir = true,
  force_position_left = true,     -- Keep this, but now with smarter logic
})
