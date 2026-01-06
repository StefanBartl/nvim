---@module 'custom.insert.filepath'
---User command to insert the current buffer's file path in various formats.
---
---Usage examples:
---  :InsertFilePath              -- insert path relative to cwd (default, and when no args)
---  :InsertFilePath cwd          -- explicit cwd-relative path
---  :InsertFilePath abs          -- absolute path
---  :InsertFilePath absolute     -- absolute path (alias)
---  :InsertFilePath 0            -- only filename
---  :InsertFilePath 1            -- parent/filename
---  :InsertFilePath 2 unix       -- two levels (dir/dir/file) with unix separator
---  :InsertFilePath lua          -- lua-style module path (dots, no extension) (default output format)
---  :InsertFilePath 2 lua        -- combine level selection with output format
---
---Notes:
---  - The command inserts the resulting path at the current cursor column in the current line.
---  - If the buffer has no name (unnamed buffer), the command is a no-op and returns false.
---  - The command supports both passing a numeric first argument or using the first argument as a mode token.
---  - The command supports count passed as explicit numeric argument (":InsertFilePath 2") or via cmdline count
---    by using the command count (e.g. "2:InsertFilePath"); both will be considered.
---
---All runtime behaviour is implemented with plain neovim Lua API and standard libs only.

local M = {}

---@type string[] -- valid first-argument tokens (modes)
local mode_tokens = { "cwd", "abs", "absolute" }

---@type string[] -- valid path format tokens
local format_tokens = { "system", "win", "windows", "unix", "linux", "lua" }

---Normalize a token to a canonical mode.
---@param token string|nil
---@return string 'cwd'|'abs'
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

---Normalize format token.
---@param token string|nil
---@return string one of "system","win","unix","lua"
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
  -- fallback default
  return "lua"
end

---Split string by pattern (plain separator).
---@param s string
---@param sep string
---@return string[] parts
local function split(s, sep)
  local parts = {}
  local pattern = "([^" .. sep .. "]+)"
  for part in string.gmatch(s, pattern) do
    parts[#parts + 1] = part
  end
  return parts
end

---Join array of strings using separator.
---@param parts string[]
---@param sep string
---@return string
local function join(parts, sep)
  if not parts or #parts == 0 then
    return ""
  end
  return table.concat(parts, sep)
end

---Return system path separator as string (single character).
---@return string
local function system_path_sep()
  -- package.config:sub(1,1) yields directory separator (e.g. '\' on Windows, '/' on *nix)
  local sep = package.config:sub(1, 1)
  return sep
end

---Return a path relative to current working directory if possible.
---@param path string -- absolute path
---@return string -- path relative to cwd or the original absolute path fallback
local function relative_to_cwd(path)
  -- Use vim.fn.fnamemodify with ':.' which returns path relative to cwd when possible
  local rel = vim.fn.fnamemodify(path, ':.')
  -- Remove leading './' if present
  if rel:sub(1, 2) == './' then
    rel = rel:sub(3)
  end
  return rel
end

---Take a path (absolute or relative) and pick the last `levels_plus_one` path segments.
---levels_plus_one: count + 1 (0 => filename only)
---@param path string -- relative path using '/' separators (function expects unix-style split)
---@param levels_plus_one integer
---@return string[] selected_segments
local function pick_tail_segments(path, levels_plus_one)
  -- normalize separators to '/'
  local normalized = path:gsub("\\", "/")
  local parts = split(normalized, "/")
  local n = #parts
  if levels_plus_one <= 0 then
    -- safety: at least return filename
    levels_plus_one = 1
  end
  local start_idx = math.max(1, n - levels_plus_one + 1)
  local selected = {}
  local j = 1
  for i = start_idx, n do
    selected[j] = parts[i]
    j = j + 1
  end
  return selected
end

---Format selected segments according to target format.
---@param segments string[]   -- list of path segments
---@param format string       -- one of "system","win","unix","lua"
---@param _original_path string -- absolute original path (used for extension removal)
---@return string formatted_path
---@diagnostic disable-next-line: unused-local
local function format_segments(segments, format, _original_path)
  -- handle lua-module formatting
  if format == "lua" then
    -- remove extension from last segment
    if #segments >= 1 then
      -- get last element
      local last = segments[#segments]

      -- remove extension (:r removes the extension from a filename)
      local name_no_ext = vim.fn.fnamemodify(last, ":r")
      segments[#segments] = name_no_ext
    end

    -- join using dot notation
    local out = join(segments, ".")

    -- remove leading "lua." prefix if present
    -- this ensures module paths do not start with "lua."
    -- example: lua.my.module -> my.module
    if out:match("^lua%.") then
      out = out:gsub("^lua%.", "")
    end

    return out
  end

  -- non-lua formats
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


---Insert text at current cursor column (in the current line).
---@param text string
local function insert_text_at_cursor(text)
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win) -- {row, col}, 1-based row, 0-based col
  local row = cursor[1]
  local col = cursor[2]
  -- fetch current line
  local line = vim.api.nvim_get_current_line()
  -- col can be larger than line length; clamp
  if col > #line then
    col = #line
  end
  -- build new line with inserted text at column (col is 0-based)
  local pre = line:sub(1, col)
  local post = line:sub(col + 1, #line)
  local new_line = pre .. text .. post
  vim.api.nvim_set_current_line(new_line)
  -- restore cursor to after inserted text
  local new_col = col + #text
  vim.api.nvim_win_set_cursor(win, { row, new_col })
end

---Main command handler.
---@param opts table
---  opts.fargs: string[] arguments passed to the command
---  opts.count: number command line count (0 when none provided)
local function handle_command(opts)
  local fargs = opts.fargs or {}
  local cmd_count = opts.count or 0

  -- Determine numeric level (priority: explicit numeric arg > cmd_count)
  local numeric_arg = nil
  if #fargs >= 1 and tonumber(fargs[1]) ~= nil then
    numeric_arg = tonumber(fargs[1])
  elseif cmd_count and cmd_count > 0 then
    numeric_arg = cmd_count
  end

  -- Determine mode token (cwd/abs)
  local mode_token = nil
  -- If first arg is token and not numeric, treat it as mode (e.g. "cwd" or "abs")
  if #fargs >= 1 and tonumber(fargs[1]) == nil then
    -- It might be a mode token or a numeric string that wasn't parsed; normalize
    mode_token = fargs[1]
  end

  local mode = normalize_mode(mode_token)

  -- Determine format token (second arg if present and not numeric)
  local format_token = nil
  if #fargs >= 2 then
    -- if first arg was numeric, second can be format; if first was token, second may be format as well
    if tonumber(fargs[1]) ~= nil then
      format_token = fargs[2]
    else
      format_token = fargs[2]
    end
  elseif #fargs == 1 and tonumber(fargs[1]) ~= nil and cmd_count == 0 then
    -- only numeric arg provided
    format_token = nil
  end

  local format = normalize_format(format_token)

  -- If no args provided at all, defaults are cwd and lua
  if #fargs == 0 and cmd_count == 0 then
    mode = "cwd"
    format = "lua"
    numeric_arg = nil
  end

  -- Obtain current buffer name
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    -- unnamed buffer; nothing to insert
    return false
  end

  local abs_path = vim.fn.fnamemodify(bufname, ":p") -- absolute path
  local rel_path = relative_to_cwd(abs_path) -- relative to cwd (unix-style separators)

  local use_path_for_splitting = rel_path
  if mode == "abs" then
    -- for absolute mode, split on absolute path
    use_path_for_splitting = abs_path
  else
    use_path_for_splitting = rel_path
  end

  -- Determine how many segments to include: default if numeric_arg == nil => include full relative path
  local segments = nil
  if numeric_arg == nil then
    -- include full relative path as segments
    -- normalize to '/' for splitting
    local normalized = use_path_for_splitting:gsub("\\", "/")
    segments = split(normalized, "/")
  else
    -- numeric_arg is like count: 0 => filename only, 1 => parent/filename, etc.
    local levels_plus_one = tonumber(numeric_arg) + 1
    segments = pick_tail_segments(use_path_for_splitting, levels_plus_one)
  end

  -- Edge: if relative path is '.' (file in cwd with no path), ensure filename is used
  if #segments == 0 then
    -- fallback to filename from absolute path
    local filename = vim.fn.fnamemodify(abs_path, ":t")
    segments = { filename }
  end

  local out = format_segments(segments, format, abs_path)

  -- Insert result at cursor
  insert_text_at_cursor(out)
  return true
end

---Register the user command InsertFilePath.
---@param opts table|nil optional table with registration options (currently unused)
function M.enable(opts)
  opts = opts or {}

  -- create user command with flexible args: allow 0..2 args and use count
  vim.api.nvim_create_user_command("InsertFilePath", function(cmd_opts)
    -- cmd_opts is a table with fields: args, fargs, bang, range, mods, count
    local ok, _ = pcall(handle_command, cmd_opts)
    if not ok then
      -- swallow errors silently to avoid noisy command failures; user can inspect logs if necessary
      -- (no runtime effect other than not inserting)
      return
    end
  end, {
    nargs = "*",
    complete = function(arg_lead, _,  _)
      -- provide simple completion of tokens
      local candidates = {}
      for _, t in ipairs(mode_tokens) do
        if t:match("^" .. vim.pesc(arg_lead)) then
          candidates[#candidates + 1] = t
        end
      end
      for _, t in ipairs(format_tokens) do
        if t:match("^" .. vim.pesc(arg_lead)) then
          candidates[#candidates + 1] = t
        end
      end
      return candidates
    end,
    desc = "[custom.insert.filepath] Insert current buffer file path. Modes: cwd|abs. Formats: system|win|unix|lua. Numeric arg selects folder depth (0 = filename).",
    bang = false,
    count = true,
  })
end

return M
