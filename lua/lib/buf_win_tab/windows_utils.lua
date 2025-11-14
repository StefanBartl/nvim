---@module 'lib.buf_win_tab.windows_utils'
--- Utility library to inspect buffers, tabs and windows on Windows (also works on Linux/macOS).

---FIX: LSP

local M = {}

-- Local helpers and types -----------------------------------------------------

-- Detect platform to allow any small Windows-specific behavior if needed.
---@return boolean
local function is_windows()
  -- Return true when running on Windows (MSYS/Cygwin/Windows native)
  local ok, uname = pcall(vim.loop.os_uname)
  if not ok or not uname or not uname.sysname then
    return false
  end
  local sys = tostring(uname.sysname)
  return sys:match("Windows") ~= nil or sys:match("MSYS") ~= nil or sys:match("CYGWIN") ~= nil
end

-- Small helper to safely get buffer info from vim.fn.getbufinfo with optional fields.
---@param opts table|nil
---@return table[] list
local function getbufinfo(opts)
  -- opts is passed through to getbufinfo; ensure it is a table or nil
  if opts == nil then
    opts = {}
  end
  -- Use pcall to avoid throwing errors in unusual environments
  local ok, res = pcall(vim.fn.getbufinfo, opts)
  if not ok then
    return {}
  end
  return res
end

-- PUBLIC WINDOWS UTILS API -------------------------------------------------

-- Get info for all listed buffers and return their count.
---@return integer
function M.count_listed_buffers()
  ---@type table[]
  local listed = getbufinfo({ buflisted = 1 })
  -- Debug notify; caller can remove or replace with logging.
  vim.notify("Listed buffer: " .. tostring(#listed), vim.log.levels.DEBUG)
  return #listed
end

-- Return a table of basic buffer metadata for all buffers (listed and unlisted).
---@return table[] buffers
function M.list_all_buffers_info()
  ---@type table[]
  local bufs = getbufinfo({ bufnr = 0 }) -- getbufinfo() with no args returns all buffers; some neovim builds require arg
  if #bufs == 0 then
    -- Fallback: call without args
    bufs = getbufinfo(nil)
  end

  local out = {}
  for i = 1, #bufs do
    local b = bufs[i]
    -- Normalize fields that might be nil
    local entry = {
      bufnr = b.bufnr or b.bufnr or -1,
      name = b.name ~= "" and b.name or ("[No Name:" .. tostring(b.bufnr or -1) .. "]"),
      listed = (b.listed == 1 or b.buflisted == 1) and true or false,
      loaded = b.loaded == 1 or false,
      changed = b.changed == 1 or false,
      filetype = (b.variables and b.variables.ft) or vim.api.nvim_get_option_value("filetype", { buf = b.bufnr or -1 }) or "",
      buftype = b.buftype or vim.api.nvim_get_option_value("buftype", { buf = b.bufnr or -1 }) or "",
      modified = vim.api.nvim_get_option_value("modified", { buf = b.bufnr or -1 }),
      size = b.size or 0,
    }
    out[#out + 1] = entry
  end
  return out
end

-- Return a list of buffer ids for all listed buffers.
---@return integer[] buf_ids
function M.get_listed_buffer_ids()
  ---@type table[]
  local listed = getbufinfo({ buflisted = 1 })
  ---@type integer[]
  local ids = {}
  for i = 1, #listed do
    ids[i] = listed[i].bufnr
  end
  return ids
end

-- Return buffer ids grouped by filetype. Table keys are filetype strings.
---@return table<string, integer[]> grouped
function M.get_buffers_grouped_by_filetype()
  local infos = M.list_all_buffers_info()
  ---@type table<string, integer[]>
  local grouped = {}
  for i = 1, #infos do
    local info = infos[i]
    local ft = info.filetype ~= "" and info.filetype or "[no_ft]"
    if grouped[ft] == nil then
      grouped[ft] = { [1] = info.bufnr } -- initialize with known small size pattern
    else
      grouped[ft][#grouped[ft] + 1] = info.bufnr
    end
  end
  return grouped
end

-- Get info for the current buffer (id, name, filetype, listed, modified, buftype).
---@return table info
function M.get_current_buffer_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, name = pcall(vim.api.nvim_buf_get_name, bufnr)
  if not ok then
    name = ""
  end
  local info = {
    bufnr = bufnr,
    name = name ~= "" and name or ("[No Name:" .. tostring(bufnr) .. "]"),
    listed = vim.fn.buflisted(bufnr) == 1,
    filetype = vim.api.nvim_get_option_value( "filetype", { buf = bufnr }),
    buftype = vim.api.nvim_get_option_value( "buftype", { buf = bufnr }),
    modified = vim.api.nvim_get_option_value( "modified", { buf = bufnr }),
  }
  return info
end

-- Return buffers visible in a given tabpage (or current tabpage if nil).
---@param tabnr? integer
---@return integer[] buf_ids
function M.get_tabpage_buffers(tabnr)
  tabnr = tabnr or vim.api.nvim_get_current_tabpage()
  ---@type integer[]
  local out = {}
  -- Iterate windows in tabpage
  local wins = vim.api.nvim_tabpage_list_wins(tabnr)
  for i = 1, #wins do
    local w = wins[i]
    local b = vim.api.nvim_win_get_buf(w)
    -- push if not already present
    local found = false
    for j = 1, #out do
      if out[j] == b then
        found = true
        break
      end
    end
    if not found then
      out[#out + 1] = b
    end
  end
  return out
end

-- Format a compact, human-readable report of buffers, grouped by filetype.
---@return string
function M.format_buffers_report()
  local infos = M.list_all_buffers_info()
  local lines = { [1] = "Buffers report:" }
  for i = 1, #infos do
    local info = infos[i]
    local line = string.format(
      "  #%d  listed=%s  mod=%s  ft=%s  bt=%s  size=%d  name=%s",
      info.bufnr,
      tostring(info.listed),
      tostring(info.modified),
      info.filetype ~= "" and info.filetype or "-",
      info.buftype ~= "" and info.buftype or "-",
      info.size or 0,
      info.name
    )
    lines[#lines + 1] = line
  end
  return table.concat(lines, "\n")
end

-- Aggregate function: collect many pieces of state and return a table.
---@return table
function M.collect_all_state()
  local state = {
    platform = is_windows() and "windows" or "unix",
    listed_count = M.count_listed_buffers(),
    listed_ids = M.get_listed_buffer_ids(),
    buffers_by_filetype = M.get_buffers_grouped_by_filetype(),
    current = M.get_current_buffer_info(),
    tabpage_buffers = M.get_tabpage_buffers(),
    only_nonfile_listed = M.only_nonfile_listed_buffers(),
  }
  return state
end

-- Convenience function: print aggregated state nicely to :messages (or return string if silent=true).
---@param silent boolean|nil if true, return the string instead of notifying
---@return string|nil
function M.show_aggregated_state(silent)
  local st = M.collect_all_state()
  local lines = { [1] = string.format("Platform: %s", st.platform) }
  lines[#lines + 1] = string.format("Listed buffers: %d", st.listed_count)
  lines[#lines + 1] = "Listed IDs: " .. table.concat(st.listed_ids or {}, ", ")
  lines[#lines + 1] = "Tabpage visible buffers: " .. table.concat(st.tabpage_buffers or {}, ", ")
  lines[#lines + 1] = "Only non-file listed buffers: " .. tostring(st.only_nonfile_listed)
  lines[#lines + 1] = "Current buffer: #" .. tostring(st.current.bufnr) .. " (" .. st.current.filetype .. ")"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Detailed buffer list:"
  local buflines = vim.split(M.format_buffers_report(), "\n")
  for i = 1, #buflines do
    lines[#lines + 1] = buflines[i]
  end
  local out = table.concat(lines, "\n")
  if silent then
    return out
  else
    -- Use vim.schedule to avoid calling notify during an API-critical moment.
    vim.schedule(function()
      vim.notify(out, vim.log.levels.INFO)
    end)
    return nil
  end
end

return M
