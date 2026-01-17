---@module 'custom.filecycle.core'
require("custom.filecycle.@types")

local fc = require("custom.filecycle")
local notify = require("lib.notify").create("[filecycle]")

local M = {}

local api, fn, uv = vim.api, vim.fn, (vim.uv or vim.loop)
local fnamemodify = fn.fnamemodify
local DEFAULTS = fc.DEFAULTS

--- Resolve a canonical path for comparison/opening.
--- Uses fs_realpath when allowed, otherwise returns absolute path.
---@param p FilePath
---@param follow boolean
---@return FilePath
local function canon(p, follow)
  ---@diagnostic disable-next-line: undefined-field
  if follow and uv and uv.fs_realpath then
    ---@diagnostic disable-next-line: undefined-field
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

---Open a path according to `opts.open_target`
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

  local target = opts.open_target or "replace"
  local esc = fn.fnameescape(path)

  -- Check for modified buffer if target is "replace" and confirm_on_modified is true
  if target == "replace" and opts.confirm_on_modified and vim.bo[bufnr].modified then
    local hover_select = require("lib.ui.hover_select")

    hover_select.open({
      title = "Buffer has unsaved changes",
      items = {
        "Save and open",
        "Discard changes and open",
        "Cancel",
      },
      on_select = function(selected, _)
        if selected == "Save and open" then
          local ok_save = pcall(vim.cmd, "write")
          if ok_save then
            -- Replace current buffer content
            pcall(vim.cmd, "edit " .. esc)
          else
            notify.error("[filecycle] Failed to save buffer")
          end
        elseif selected == "Discard changes and open" then
          pcall(vim.cmd, "edit! " .. esc)
        end
        -- Cancel: do nothing
      end,
    })
    return true
  end

  -- Normal flow: no modified buffer or confirm disabled
  if target == "replace" then
    -- TRUE REPLACE: Load new file and delete the old buffer
    -- This ensures the buffer number changes but window stays focused
    local old_bufnr = bufnr

    -- Load new file in current window
    local _cmd = "edit " .. esc
    local ok, err = pcall(vim.cmd, _cmd)
    if not ok then
      notify.error(("[filecycle] open failed: %s"):format(tostring(err)))
      return false
    end

    -- Delete the old buffer (if it's different from the new one)
    local new_bufnr = api.nvim_get_current_buf()
    if old_bufnr ~= new_bufnr and api.nvim_buf_is_valid(old_bufnr) then
      -- Use bdelete to remove the old buffer from the buffer list
      pcall(api.nvim_buf_delete, old_bufnr, { force = false })
    end

    return true

  elseif target == "current" then
    -- NEW: Open in new buffer, keep old buffer, focus new
    local ok, err = pcall(vim.cmd, "edit " .. esc)
    if not ok then
      notify.error(("[filecycle] open failed: %s"):format(tostring(err)))
      return false
    end
    -- Old buffer still exists in buffer list
    return true

  elseif target == "split" or target == "vsplit" then
    local splitcmd = (target == "split") and "split " or "vsplit "
    local curwin = win
    local ok, err = pcall(vim.cmd, splitcmd .. esc)
    if not ok then
      notify.error(("[filecycle] %s failed: %s"):format(target, tostring(err)))
      return false
    end
    if opts.keep_focus and api.nvim_win_is_valid(curwin) then
      vim.schedule(function()
        pcall(api.nvim_set_current_win, curwin)
      end)
    end
    return true

  elseif target == "tab" then
    local ok, err = pcall(vim.cmd, "tabedit " .. esc)
    if not ok then
      notify.error(("[filecycle] tabedit failed: %s"):format(tostring(err)))
      return false
    end
    return true

  elseif target == "background" then
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
    notify.warn(("[filecycle] unknown open_target: %s"):format(tostring(target)))
    return false
  end
end

--- Validate and clamp count to [1, #files]
---@param count integer? User-provided count (may be nil, 0, or negative)
---@return integer clamped_count Always >= 1
local function validate_count(count)
  if type(count) ~= "number" or count < 1 then
    return 1
  end
  return math.floor(count)
end

--- Compute next/previous path and open it.
---@param dir FilePath
---@param mode FileCycle.Direction
---@param opts FileCycle.Config
---@param count integer? Number of steps (default: 1)
---@return boolean ok
function M.navigate(dir, mode, opts, count)
  -- Validate count early
  count = validate_count(count)

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
    -- If current file is not in the filtered list, insert and find index
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

  -- Calculate target index with count
  local target_idx
  local n = #files

  if mode == "next" then
    target_idx = idx + count
    if opts.wrap then
      -- Wrap around: ((idx - 1 + count) % n) + 1
      target_idx = ((idx - 1 + count) % n) + 1
    elseif target_idx > n then
      target_idx = nil
    end
  else -- prev
    target_idx = idx - count
    if opts.wrap then
      -- Wrap around: ((idx - 1 - count) % n) + 1
      -- Lua modulo handles negatives correctly
      target_idx = ((idx - 1 - count) % n) + 1
    elseif target_idx < 1 then
      target_idx = nil
    end
  end

  if not target_idx then
    notify.info(("[NextPrev] boundary reached (wrap disabled, count=%d)"):format(count))
    return false
  end

  return open_path(files[target_idx], opts)
end

return M
