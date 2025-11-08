---@module 'lib.buf_win_tab.neotree'
--- Utility library for inspecting and neotree

local buflib = require("lib.buf_win_tab.buffer_utils")

local M = {}

-- Heuristic to find Neotree window by scanning all windows for buffer filetype/name hints.
---@return number|nil winid window id if found, otherwise nil
function M.find_neotree_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok_buf, bufnr = pcall(vim.api.nvim_win_get_buf, win)
    if ok_buf then
      local _, ft = pcall(vim.api.nvim_buf_get_option_value, "filetype", { buf = bufnr })
      local _, name = pcall(vim.api.nvim_buf_get_name, bufnr)
      ft = ft or ""
      name = name or ""
      -- common neo-tree filetype (neo-tree.nvim) is "neo-tree"
      if ft == "neo-tree" or ft == "NvimTree" or name:match("neo%-tree") or name:lower():match("neotree") then
        return win
      end
      -- also check for buffers with "Neotree" in their buffer name or special buftype/nofile
      local _, buftype = pcall(vim.api.nvim_buf_get_option_value, "buftype", { buf = bufnr })
      buftype = buftype or ""
      if buftype == "nofile" and (name:match("NeoTree") or name:match("Neotree") or name:match("NvimTree")) then
        return win
      end
    end
  end
  return nil
end

-- Try to open :Neotree (call the command) and then focus the Neotree window if it appears.
---@param neotree_cmd string|nil optional Neotree command to run (defaults to "Neotree reveal")
---@return boolean success true if a neotree window was focused
function M.open_neotree_and_focus(neotree_cmd)
  neotree_cmd = neotree_cmd or "Neotree reveal"
  -- Execute the command; wrap in pcall in case command does not exist.
  local ok, _ = pcall(function() vim.cmd("neotree_cmd") end)
  if not ok then
    -- fallback: try plain Neotree toggle
    pcall(function() vim.cmd("Neotree") end)
  end

  -- small delay may be needed in some setups to let the tree create its window.
  -- We'll do a tiny sleep-like loop but non-blocking in large durations. This is synchronous,
  -- but limited to a few short attempts to keep behavior deterministic.
  for _ = 1, 6 do
    local win = M.find_neotree_window()
    if win then
      vim.api.nvim_set_current_win(win)
      return true
    end
    -- short yield using vim.wait to allow UI to update if available
    if vim.wait then
      vim.wait(30, function() return false end, 1) -- 30ms-ish attempts
    else
      -- as a fallback, try a small loop (not ideal, but kept minimal)
      local _ = 0
    end
  end

  return false
end

-- Create an autocommand that triggers when buffers are deleted/wiped and opens Neotree
-- if there are no "real" listed buffers left.
---@param opts table|nil
--- opts.exclude_filetypes string[]|nil filetypes to exclude when deciding "real" buffers
--- opts.group_name string|nil augroup name override
--- opts.neotree_cmd string|nil command to call for opening neotree
function M.setup_autotree_on_last_close(opts)
  opts = opts or {}
  local exclude_filetypes = opts.exclude_filetypes or buflib.DEFAULT_EXCLUDE_FILETYPES
  local group_name = opts.group_name or "BufferUtilsAutoTree"
  local neotree_cmd = opts.neotree_cmd or "Neotree reveal"

  -- create augroup
  local augroup = vim.api.nvim_create_augroup(group_name, { clear = true })

  -- callback for BufDelete / BufWipeout
  local function cb()
    local remaining = buflib.count_real_listed_buffers(exclude_filetypes)
    -- Debugging line; can be commented out or left as low-level debug.
    vim.notify("Remaining real listed buffers: " .. tostring(remaining), vim.log.levels.DEBUG)
    if remaining == 0 then
      -- open and focus neotree
      local focused = M.open_neotree_and_focus(neotree_cmd)
      if not focused then
        vim.notify("Could not find Neotree window after opening command.", vim.log.levels.WARN)
      end
    end
  end

  -- Use events that run when buffers are closed in various ways.
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout", "BufHidden" }, {
    group = augroup,
    pattern = "*",
    callback = cb,
  })
end


-- Determine whether the "only" listed buffers are non-file buffers (e.g. netrw, Neotree, undotree).
---@return boolean
function M.only_nonfile_listed_buffers()
  local listed_info = buflib.get_buffer_info({ buflisted = 1 })
  if #listed_info == 0 then
    return true
  end
  for i = 1, #listed_info do
    local b = listed_info[i]
    local bufnr = b.bufnr
    local buftype = (b.buftype and b.buftype ~= "") and b.buftype or vim.api.nvim_buf_get_option_value("buftype", { buf = bufnr})
    local ft = (b.variables and b.variables.ft) or vim.api.nvim_buf_get_option_value("filetype", { buf = bufnr })
    -- treat empty name or non-file buftype as non-file
    if buftype == "" and ft == "" and (b.name and b.name ~= "") then
      -- try to detect filesystem file by checking if buffer has a real file path
      local name = b.name or ""
      if name ~= "" and vim.loop.fs_stat(name) then
        -- this is a real file -> there is at least one file buffer
        return false
      end
    end
    if buftype == "" and ft ~= "" then
      -- has a filetype -> assume file-like
      return false
    end
    if buftype ~= "" and buftype ~= "nofile" and buftype ~= "prompt" then
      -- some other buftype that might be filelike; be conservative and treat as file
      return false
    end
  end
  return true
end

-- Expose a small helper that attempts to open Neotree and focus it when the last file buffer was closed.
-- This function intentionally does not create autocommands itself; it is a helper to be used in an autocommand.
---@return boolean opened True if the command to open Neotree was invoked.
function M.open_neotree_if_last_buffer()
  -- If there are listed buffers and at least one real file buffer, do nothing.
  if not M.only_nonfile_listed_buffers() then
    return false
  end

  -- Try to require 'neo-tree' or call :Neotree, but prefer to call the command so that both neo-tree and neotree plugins work.
  -- The command name varies: some installs expose "Neotree" (neo-tree.nvim) others "Neotree reveal". Use the generic :Neotree if available.
  -- Use pcall to avoid errors when command/plugin not present.
  local opened = false
  local ok = pcall(function() vim.cmd("silent Neotree reveal") end)
  if ok then
    opened = true
  else
    -- Try fallback command name
    ok = pcall(function() vim.cmd("silent Neotree")end)
    if ok then
      opened = true
    else
      -- Try neo-tree.nvim command names
      ok = pcall(function() vim.cmd("silent NeotreeFocus") end)
      if ok then
        opened = true
      end
    end
  end

  if opened then
    -- Try to move focus to the tree window. Search for a window that likely contains the tree by bufname or filetype.
    vim.schedule(function()
      local wins = vim.api.nvim_list_wins()
      for i = 1, #wins do
        local w = wins[i]
        local b = vim.api.nvim_win_get_buf(w)
        local ft = pcall(vim.api.nvim_buf_get_option_value, "filetype", { buf = b }) and vim.api.nvim_buf_get_option_value("filetype", { buf = b }) or ""
        local name = pcall(vim.api.nvim_buf_get_name, b) and vim.api.nvim_buf_get_name(b) or ""
        -- common tree filetypes: "neo-tree", "neo_tree", "NvimTree", "fern", "netrw"
        if ft:match("neo[_%-]?tree") or ft:match("NvimTree") or ft:match("fern") or name:match("neo%-tree") or name:match("NvimTree") then
          pcall(vim.api.nvim_set_current_win, w)
          break
        end
      end
    end)
  end

  return opened
end

return M
