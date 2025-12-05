---@module 'config.neotree.open_replace'

-- FIX: Ohne auto_close funktionert es nicht korrekt, weil neotree sich nach dem ausfphren des Mappings ungewollt rechts öffnet
-- FIX: öffnet anscheinen ein vertikal split statt im current window
local api = vim.api
local fn = vim.fn

local function prompt_save(buf)
  if not api.nvim_get_option_value("modified", { buf = buf }) then return true end
  local name = api.nvim_buf_get_name(buf)
  local short = name ~= "" and fn.fnamemodify(name, ":t") or "[No name]"
  local prompt = string.format("Buffer %s has unsaved changes. Save before replacing?", short)
  local res = fn.confirm(prompt, "&Save\n&Don't save\n&Cancel", 1)
  if res == 1 then
    return pcall(function() vim.cmd("write") end)
  elseif res == 2 then
    return true
  else
    return false
  end
end

local function find_last_normal_buffer(exclude_win)
  local wins = api.nvim_tabpage_list_wins(0)
  for i = #wins, 1, -1 do
    local w = wins[i]
    if w ~= exclude_win and api.nvim_win_is_valid(w) then
      local buf = api.nvim_win_get_buf(w)
      if vim.bo[buf].buflisted and vim.bo[buf].filetype ~= "neo-tree" then
        return buf, w
      end
    end
  end
  return nil, nil
end

local function find_any_non_neo_window(exclude_win)
  local wins = api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    if w ~= exclude_win and api.nvim_win_is_valid(w) then
      local buf = api.nvim_win_get_buf(w)
      if vim.bo[buf].filetype ~= "neo-tree" then
        return w
      end
    end
  end
  return nil
end

--- Open a node file after deleting last normal buffer.
--- opts:
---   focus boolean|nil   -> if true, move cursor into the opened file window; default true
---   auto_close boolean|nil -> if true, close the Neo-tree window after open; default false
---   logger table|nil    -> optional logger
--- Behavior:
---  - delete the last normal buffer (if any) and open the node file in that place
---  - if no suitable window exists, create a split and open there
---  - if auto_close == true, close the Neo-tree window (best-effort)
---  - always attempt to restore Neo-tree focus when focus == false
---@param state table
---@param opts? table { focus = boolean|nil, auto_close = boolean|nil, logger = table|nil }
---@return boolean
return function (state, opts)
  opts = opts or {}
  local logger = opts.logger
  local focus = opts.focus == nil and true or opts.focus
  local auto_close = opts.auto_close == true

  if not state or not state.tree then
    if logger and logger.warn then logger.warn("open_replace: invalid state") end
    return false
  end

  local node = state.tree:get_node()
  if not node then
    if logger and logger.debug then logger.debug("open_replace: no node under cursor") end
    return false
  end

  if node.type == "directory" or node:has_children() then
    if logger and logger.debug then logger.debug("open_replace: node is directory") end
    return false
  end

  local path = node.path or (type(node.get_id) == "function" and node:get_id())
  if not path or path == "" then
    if logger and logger.debug then logger.debug("open_replace: node has no path") end
    return false
  end

  -- Neo-tree window id at the moment of invocation (likely the focused Neo-tree)
  local neo_win = state.winid or api.nvim_get_current_win()
  -- Remember original focused window to restore if needed
  local orig_win = api.nvim_get_current_win()

  -- Try to find last normal buffer (and its window)
  local buf_to_close, win_of_buf = find_last_normal_buffer(neo_win)
  local target_win = win_of_buf

  if buf_to_close and target_win then
    local ok = prompt_save(buf_to_close)
    if not ok then
      if logger and logger.debug then logger.debug("open_replace: user cancelled save prompt") end
      return false
    end
    -- Delete the buffer but keep the window layout
    pcall(function() api.nvim_buf_delete(buf_to_close, { force = true }) end)
  else
    -- pick any non-neo window if available
    target_win = find_any_non_neo_window(neo_win)
  end

  local created_new_win = false
  if not target_win or not api.nvim_win_is_valid(target_win) then
    -- create a new split and use it
    pcall(function() vim.cmd("vsplit") end)
    target_win = api.nvim_get_current_win()
    created_new_win = true
  end

  -- Ensure we open in the target window
  pcall(function() api.nvim_set_current_win(target_win) end)

  local resolved = fn.expand(path)
  if resolved == "" then resolved = path end

  local ok, err = pcall(function()
    vim.cmd("edit " .. fn.fnameescape(resolved))
  end)

  if not ok then
    -- if failed and we created a new window, close it to avoid layout mess
    if created_new_win and api.nvim_win_is_valid(target_win) then
      pcall(function() api.nvim_win_close(target_win, true) end)
    end
    -- restore original focus
    pcall(function()
      if api.nvim_win_is_valid(orig_win) then api.nvim_set_current_win(orig_win) end
    end)
    if logger and logger.warn then
      logger.warn("open_replace: failed to open node file", { err = err, path = resolved })
    end
    return false
  end

  -- After successful open: decide how to restore/close Neo-tree
  if auto_close then
    -- Best-effort: close the Neo-tree window if still valid and distinct from target
    if api.nvim_win_is_valid(neo_win) and neo_win ~= target_win then
      pcall(function() api.nvim_win_close(neo_win, true) end)
      if logger and logger.info then logger.info("open_replace: auto-closed Neo-tree window") end
    end
    -- If closing Neo-tree moved focus, ensure desired focus
    if focus then
      if api.nvim_win_is_valid(target_win) then pcall(function() api.nvim_set_current_win(target_win) end) end
    else
      if api.nvim_win_is_valid(orig_win) then pcall(function() api.nvim_set_current_win(orig_win) end) end
    end
    return true
  end

  -- If not auto_close: either focus the target window or restore original neo-tree focus.
  if focus then
    if api.nvim_win_is_valid(target_win) then
      pcall(function() api.nvim_set_current_win(target_win) end)
    end
  else
    -- Restore Neo-tree focus if it still exists; otherwise restore original window
    if api.nvim_win_is_valid(neo_win) then
      pcall(function() api.nvim_set_current_win(neo_win) end)
    else
      if api.nvim_win_is_valid(orig_win) then pcall(function() api.nvim_set_current_win(orig_win) end) end
    end
  end

  return true
end
