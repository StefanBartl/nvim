---@module 'custom.filecycle.core'
require("custom.filecycle.@types")

local fc = require("custom.filecycle")
local notify = require("lib.notify").create("[filecycle]")

local M  = {}

local api, fn, uv = vim.api, vim.fn, (vim.uv or vim.loop)
local cmd = vim.cmd
local fnamemodify = fn.fnamemodify
local DEFAULTS = fc.DEFAULTS


--- Resolve a canonical path for comparison/opening.
--- Uses fs_realpath when allowed, otherwise returns absolute path.
---@param p FilePath
---@param follow boolean
---@return FilePath
local function canon(p, follow)
  ---@diagnostic disable-next-line lib.uv
  if follow and uv and uv.fs_realpath then
    ---@diagnostic disable-next-line lib.uv
    local rp = uv.fs_realpath(p)
    if type(rp) == "string" and rp ~= "" then
      return rp
    end
  end
  return fnamemodify(p, ":p")
end

--- Return current directory to scan according to config.
---@param opts FileCycle.Config
---@return FilePath|nil, string|nil
function M.get_root_dir(opts)
  local target = opts.root
  if target == "cwd" then
    local cwd = fn.getcwd()
    if type(cwd) == "string" and cwd ~= "" then
      return cwd
    end
    return nil, "failed to getcwd()"
  end
  -- buffer_dir (default)
  local name = api.nvim_buf_get_name(0)
  if not name or name == "" then
    return nil, "current buffer has no file name"
  end
  local dir = fnamemodify(name, ":p:h")
  if not dir or dir == "" then
    return nil, "failed to resolve buffer directory"
  end
  return dir, nil
end

--- Predicate: keep this directory entry?
---@param name string  -- filename (not path)
---@param is_file boolean
---@param opts FileCycle.Config
---@return boolean
local function keep_entry(name, is_file, opts)
  if not is_file then
    return false
  end
  if not opts.include_hidden and name:sub(1, 1) == "." then
    return false
  end
  return true
end

--- List regular files in a directory (non-recursive), filtered & sorted.
---@param dir FilePath
---@param opts FileCycle.Config
---@return string[] files  -- absolute, canonicalized paths
local function list_files(dir, opts)
  ---@type string[]
  local acc = {}
  for name, t in vim.fs.dir(dir) do
    local is_file = (t == "file")
    if not is_file and t == nil then
      -- Older libuv may not give type; check via fs_stat
      local st = uv and uv.fs_stat and uv.fs_stat(fn.fnamemodify(dir .. "/" .. name, ":p")) or nil
      is_file = (st and st.type == "file") or false
    end
    if keep_entry(name, is_file, opts) then
      acc[#acc + 1] = canon(dir .. "/" .. name, opts.follow_symlinks)
    end
  end
  local ci = opts.case_insensitive
  table.sort(acc, function(a, b)
    if ci then
      return a:lower() < b:lower()
    else
      return a < b
    end
  end)
  return acc
end

--- Find index of current file within the list.
---@param files string[]
---@param current FilePath
---@param ci? boolean
---@return integer|nil
local function index_of(files, current, ci)
  if ci or DEFAULTS.case_insensitive then
    current = current:lower()
  end
  for i = 1, #files do
    local v = ci and files[i]:lower() or files[i]
    if v == current then
      return i
    end
  end
  return nil
end

--- Open a path according to `opts.open_target`
---@param path string
---@param opts FileCycle.Config
---@return boolean ok
local function open_path(path, opts)
  if type(path) ~= "string" or path == "" then
    return false
  end
  local win = api.nvim_get_current_win()
  if not (win and api.nvim_win_is_valid(win)) then
    return false
  end
  local bufnr = api.nvim_get_current_buf()
  if not (bufnr and api.nvim_buf_is_valid(bufnr)) then
    return false
  end

  local target = opts.open_target or "current"
  local esc = fn.fnameescape(path)

  if target == "current" then
    local _cmd
    if opts.confirm_on_modified and vim.bo[bufnr].modified then
      _cmd = "confirm edit " .. esc
    else
      _cmd = "edit " .. esc
    end
    local ok, err = pcall(function()
      cmd(_cmd)
    end)
    if not ok then
      notify.error(("[NextPrev] open failed: %s"):format(tostring(err)))
      return false
    end
    return true
  elseif target == "split" or target == "vsplit" then
    local splitcmd = (target == "split") and "split " or "vsplit "
    local curwin = win
    local ok, err = pcall(function()
      cmd(splitcmd .. esc)
    end)
    if not ok then
      notify(("[NextPrev] %s failed: %s"):format(target, tostring(err)))
      return false
    end
    if opts.keep_focus and api.nvim_win_is_valid(curwin) then
      vim.schedule(function()
        pcall(api.nvim_set_current_win, curwin)
      end)
    end
    return true
  elseif target == "tab" then
    local ok, err = pcall(function()
      cmd("tabedit " .. esc)
    end)
    if not ok then
      notify.error(("[NextPrev] tabedit failed: %s"):format(tostring(err)))
      return false
    end
    -- keep_focus is intentionally ignored for tabs
    return true
  elseif target == "background" then
    -- Add buffer silently without changing windows
    local ok_add, b = pcall(fn.bufadd, path)
    if not ok_add then
      return false
    end
    pcall(fn.bufload, b)
    pcall(function()
      vim.bo[b].buflisted = true
    end)
    return true
  else
    notify.warn(("[NextPrev] unknown open_target: %s"):format(tostring(target)))
    return false
  end
end

--- Compute next/previous path and open it.
---@param dir FilePath
---@param mode "next"|"prev"
---@param opts FileCycle.Config
---@return boolean ok
function M.navigate(dir, mode, opts)
  local files = list_files(dir, opts)
  if #files == 0 then
    notify.warn("[NextPrev] no files in directory")
    return false
  end

  local cur = api.nvim_buf_get_name(0)
  if not cur or cur == "" then
    notify.warn("[NextPrev] current buffer has no file name")
    return false
  end

  local key = canon(cur, opts.follow_symlinks)
  local ci = opts.case_insensitive or DEFAULTS.case_insensitive
  local idx = index_of(files, key, ci)
  if not idx then
    -- If current file is not in the filtered list, choose the closest by name and continue.
    table.insert(files, key)
    table.sort(files, function(a, b)
      return (ci and a:lower() or a) < (ci and b:lower() or b)
    end)
    for i = 1, #files do
      if (ci and files[i]:lower() == key:lower()) or files[i] == key then
        idx = i
        break
      end
    end
  end

  if not idx then
    notify.warn("[NextPrev] cannot place current file in ordering")
    return false
  end

  local target_idx
  if mode == "next" then
    if idx < #files then
      target_idx = idx + 1
    elseif opts.wrap then
      target_idx = 1
    end
  else
    if idx > 1 then
      target_idx = idx - 1
    elseif opts.wrap then
      target_idx = #files
    end
  end

  if not target_idx then
    notify.info("[NextPrev] boundary reached (wrap disabled)")
    return false
  end

  return open_path(files[target_idx], opts)
end

return M
