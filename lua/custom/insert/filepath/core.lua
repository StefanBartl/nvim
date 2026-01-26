---@module 'custom.insert.filepath.core'
---@brief Core implementation for filepath insertion
---@description
--- Provides functions to insert the current buffer's file path at the cursor
--- in various formats (cwd-relative, absolute, lua module path, etc.).

local notify = require("lib.notify").create("[custom.insert.filepath.core]")

local M = {}

local api = vim.api

---Normalize a token to a canonical mode
---@param token string|nil
---@return Custom.Insert.FilePath.Mode
local function normalize_mode(token)
  if not token then
    return "cwd"
  end
  local lower = string.lower(token)
  if lower == "abs" or lower == "absolute" then
    return "abs"
  end
  return "cwd"
end

---Normalize format token
---@param token string|nil
---@return Custom.Insert.FilePath.Format
local function normalize_format(token)
  if not token then
    return "lua"
  end
  local lower = string.lower(token)
  if lower == "system" then
    return "system"
  end
  if lower == "win" or lower == "windows" then
    return "win"
  end
  if lower == "unix" or lower == "linux" then
    return "unix"
  end
  if lower == "lua" then
    return "lua"
  end
  return "lua"
end

---Split string by pattern
---@param s string
---@param sep string
---@return string[]
local function split(s, sep)
  local parts = {}
  local pattern = "([^" .. sep .. "]+)"
  for part in string.gmatch(s, pattern) do
    parts[#parts + 1] = part
  end
  return parts
end

---Join array of strings using separator
---@param parts string[]
---@param sep string
---@return string
local function join(parts, sep)
  if not parts or #parts == 0 then
    return ""
  end
  return table.concat(parts, sep)
end

---Return system path separator as string
---@return string
local function system_path_sep()
  local sep = package.config:sub(1, 1)
  return sep
end

---Return a path relative to current working directory
---@param path string Absolute path
---@return string
local function relative_to_cwd(path)
  local rel = vim.fn.fnamemodify(path, ':.')
  if rel:sub(1, 2) == './' then
    rel = rel:sub(3)
  end
  return rel
end

---Pick last N segments from path
---@param path string Path with / separators
---@param levels_plus_one integer
---@return string[]
local function pick_tail_segments(path, levels_plus_one)
  local normalized = path:gsub("\\", "/")
  local parts = split(normalized, "/")
  local n = #parts
  if levels_plus_one <= 0 then
    levels_plus_one = 1
  end
  local start_idx = math.max(1, n - levels_plus_one + 1)
  local selected = {}
  for i = start_idx, n do
    table.insert(selected, parts[i])
  end
  return selected
end

---Format segments according to target format
---@param segments string[]
---@param format Custom.Insert.FilePath.Format
---@return string
local function format_segments(segments, format)
  if format == "lua" then
    -- Remove extension from last segment
    if #segments >= 1 then
      local last = segments[#segments]
      local name_no_ext = vim.fn.fnamemodify(last, ":r")
      segments[#segments] = name_no_ext
    end

    local out = join(segments, ".")

    -- Remove leading "lua." prefix
    if out:match("^lua%.") then
      out = out:gsub("^lua%.", "")
    end

    return out
  end

  -- Non-lua formats
  local sep = "/"
  if format == "system" then
    sep = system_path_sep()
  elseif format == "win" then
    sep = "\\"
  elseif format == "unix" then
    sep = "/"
  else
    sep = "/"
  end

  return join(segments, sep)
end

---Insert text at current cursor column
---@param text string
local function insert_text_at_cursor(text)
  local win = api.nvim_get_current_win()
  local cursor = api.nvim_win_get_cursor(win)
  local row = cursor[1]
  local col = cursor[2]

  local line = api.nvim_get_current_line()
  if col > #line then
    col = #line
  end

  local pre = line:sub(1, col)
  local post = line:sub(col + 1, #line)
  local new_line = pre .. text .. post

  api.nvim_set_current_line(new_line)
  api.nvim_win_set_cursor(win, { row, col + #text })
end

---Insert file path at cursor with given options
---@param opts Custom.Insert.FilePath.Options
---@return boolean success
function M.insert_path(opts)
  local bufname = api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    notify.warn("[custom.insert.filepath] Unnamed buffer")
    return false
  end

  local abs_path = vim.fn.fnamemodify(bufname, ":p")
  local rel_path = relative_to_cwd(abs_path)

  local use_path = opts.mode == "abs" and abs_path or rel_path

  local segments
  if opts.depth == nil then
    -- Full path
    local normalized = use_path:gsub("\\", "/")
    segments = split(normalized, "/")
  else
    -- Limited depth
    local levels_plus_one = opts.depth + 1
    segments = pick_tail_segments(use_path, levels_plus_one)
  end

  -- Fallback to filename if no segments
  if #segments == 0 then
    local filename = vim.fn.fnamemodify(abs_path, ":t")
    segments = { filename }
  end

  local result = format_segments(segments, opts.format)
  insert_text_at_cursor(result)

  return true
end

---Parse command arguments into options
---@param args string[]
---@param count integer
---@return Custom.Insert.FilePath.Options
function M.parse_args(args, count)
  local opts = {
    mode = "cwd",
    format = "lua",
    depth = nil,
  }

  -- Parse numeric arg or count
  local numeric_arg = nil
  if #args >= 1 and tonumber(args[1]) ~= nil then
    numeric_arg = tonumber(args[1])
  elseif count and count > 0 then
    numeric_arg = count
  end

  if numeric_arg ~= nil then
    opts.depth = numeric_arg
  end

  -- Parse mode token
  if #args >= 1 and tonumber(args[1]) == nil then
    opts.mode = normalize_mode(args[1])
  end

  -- Parse format token
  if #args >= 2 then
    if tonumber(args[1]) ~= nil then
      opts.format = normalize_format(args[2])
    else
      opts.format = normalize_format(args[2])
    end
  end

  return opts
end

---@type Custom.Insert.FilePath.API
return M
