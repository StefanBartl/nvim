---@module 'autocmds.open_neotree'
--- Utility library to manage detection and controlled opening/focusing of file-tree windows (neo-tree, NvimTree, netrw, ...).
--- This module aims to avoid repeatedly reopening the tree when the user explicitly closed it
--- and to behave safely when called from autocommands.

local M = {}

-- Internal state to avoid reopening Neotree immediately after user closed it and to track
-- whether the module opened the tree (so the module can decide responsibility).
---@type boolean
M._managed_opened = false
---@type boolean
M._user_closed_neotree = false
---@type string
M._augroup = "lib_buf_win_tab_neotree_manage"

-- Helper: detect whether a window looks like a file-tree window by filetype or name.
-- Returns true for commonly used tree filetypes/names.
---@param bufnr integer
---@return boolean
local function is_tree_buffer(bufnr)
  -- English comments:
  -- Use pcall for safety as some buffer queries can error on short-lived buffers.
  local ok_ft, ft = pcall(vim.api.nvim_buf_get_option_value, "filetype", { buf = bufnr })
  local ok_name, name = pcall(vim.api.nvim_buf_get_name, bufnr)
  ft = (ok_ft and (ft or "")) or ""
  name = (ok_name and (name or "")) or ""
  if ft:match("neo[_%-]?tree") or ft:match("NvimTree") or ft:match("fern") or ft:match("netrw") then
    return true
  end
  if name:match("neo%-tree") or name:match("NvimTree") or name:match("NERD_tree") then
    return true
  end
  return false
end

-- Find a tree window id by scanning all windows. Returns winid or nil.
---@return number|nil
function M.find_neotree_window()
  -- English comments:
  -- Iterate windows and test whether their buffer looks like a tree.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok_buf, bufnr = pcall(vim.api.nvim_win_get_buf, win)
    if ok_buf and bufnr and bufnr > 0 and is_tree_buffer(bufnr) then
      return win
    end
  end
  return nil
end

-- Determine whether the "only" listed buffers are non-file buffers (e.g. netrw, Neotree, undotree).
-- The function inspects listed buffers (vim.fn.getbufinfo({buflisted=1})) and heuristically
-- decides whether any of them look like a real file buffer.
---@return boolean
function M.only_nonfile_listed_buffers()
  -- English comments:
  -- Query listed buffers using Vim's getbufinfo to keep logic local and avoid cross-module API assumptions.
  local listed = vim.fn.getbufinfo({ buflisted = 1 })
  if #listed == 0 then
    return true
  end

  for i = 1, #listed do
    local b = listed[i]
    local bufnr = b.bufnr or -1
    -- English comments:
    -- Try to obtain buftype and filetype in a safe way.
    local ok_bt, buftype = pcall(vim.api.nvim_buf_get_option_value, "buftype", { buf = bufnr })
    local ok_ft, ft = pcall(vim.api.nvim_buf_get_option_value, "filetype", { buf = bufnr })
    buftype = (ok_bt and (buftype or "")) or ""
    ft = (ok_ft and (ft or "")) or ""
    local name = b.name or ""

    -- If the buffer has a real filename on disk, treat as real file buffer.
    if name ~= "" and vim.loop.fs_stat(name) then
      return false
    end

    -- If filetype exists, assume it's a file-like buffer (e.g., 'lua', 'python').
    if ft ~= "" then
      return false
    end

    -- If buftype is set to something other than common non-file types, conservatively treat as file-like.
    if buftype ~= "" and buftype ~= "nofile" and buftype ~= "prompt" and buftype ~= "help" then
      return false
    end
  end

  -- No buffer looked like a real file buffer.
  return true
end

-- Internal: create an augroup and watchers to detect user-closed tree buffers.
-- When the module opens the tree, we register an autocmd that will flip the
-- `_user_closed_neotree` flag when a tree buffer is wiped/closed by the user.
local function ensure_management_autocmds()
  -- English comments:
  -- Create or recreate the augroup so duplicate autocmds are avoided.
  pcall(vim.api.nvim_del_augroup_by_name, M._augroup)
  local ok = pcall(function()
    vim.api.nvim_create_augroup(M._augroup, { clear = true })
  end)
  if not ok then
    -- If augroup creation failed, continue without management hooks.
    return
  end

  -- When a tree buffer is deleted/wiped by the user, set the flag that user closed it.
  -- Use BufWipeout and BufDelete to capture different plugin behaviors.
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = M._augroup,
    pattern = "*",
    callback = function(tbl)
      -- English comments:
      -- tbl.buf contains the buffer number for these events in recent neovim versions.
      local bufnr = tbl.buf
      if bufnr and is_tree_buffer(bufnr) then
        M._managed_opened = false
        M._user_closed_neotree = true
      end
    end,
  })

  -- When any tree buffer appears/created, clear the "user closed" flag so future auto-open can run again.
  -- Use FileType and BufAdd as heuristics: many tree plugins set a dedicated filetype.
  vim.api.nvim_create_autocmd({ "BufAdd", "FileType" }, {
    group = M._augroup,
    pattern = "*",
    callback = function(tbl)
      local bufnr = tbl.buf
      if bufnr and is_tree_buffer(bufnr) then
        -- English comments:
        -- If a tree buffer is created by the user or plugin, we treat that as explicit open
        -- and clear the user-closed marker so auto-open is allowed later if necessary.
        M._user_closed_neotree = false
      end
    end,
  })
end

-- Try to open Neotree (or similar tree plugin) and focus it, but avoid repeatedly reopening
-- when the user explicitly closed the tree. Returns true if a command to open the tree was
-- successfully invoked.
---@return boolean opened
function M.open_neotree_if_last_buffer()
  -- English comments:
  -- If there are still real file buffers, do nothing.
  if not M.only_nonfile_listed_buffers() then
    return false
  end

  -- If a tree window already exists, ensure we don't consider it "user closed".
  local existing = M.find_neotree_window()
  if existing then
    M._user_closed_neotree = false
    return false
  end

  -- If user recently closed the tree, respect their action and do not reopen.
  if M._user_closed_neotree then
    return false
  end

  -- Ensure autocmds that manage the flags exist.
  ensure_management_autocmds()

  -- Try a sequence of commands commonly provided by different tree plugins.
  local opened = false
  -- English comments:
  -- Try "Neotree reveal" first (some setups expose this).
  local ok = pcall(function() vim.cmd("silent Neotree reveal") end)
  if ok then
    opened = true
  else
    -- Try generic "Neotree" command (some configs)
    ok = pcall(function() vim.cmd("silent Neotree") end)
    if ok then
      opened = true
    else
      -- Try known alternative commands (plugin-specific).
      ok = pcall(function() vim.cmd("silent NeotreeFocus") end)
      if ok then
        opened = true
      else
        -- Try NvimTree (older plugin) and netrw fallback.
        ok = pcall(function() vim.cmd("silent NvimTreeOpen") end)
        if ok then
          opened = true
        else
          ok = pcall(function() vim.cmd("silent Explore") end) -- netrw fallback
          if ok then
            opened = true
          end
        end
      end
    end
  end

  if opened then
    -- Mark that we opened it and schedule focusing of the tree window if it appears.
    M._managed_opened = true
    -- English comments:
    -- After issuing command, schedule a short scan for the tree window so that focus can be moved.
    vim.schedule(function()
      local win = M.find_neotree_window()
      if win then
        pcall(vim.api.nvim_set_current_win, win)
        -- Clear user-closed flag because tree is now open.
        M._user_closed_neotree = false
      end
    end)
  end

  return opened
end

return M
