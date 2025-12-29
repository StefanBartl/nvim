---@module 'custom.lua_project_file_stats.utils'
---@brief Utility functions for file analysis and data processing

local M = {}

local str_fmt, fn = string.format, vim.fn

-- Constants
M.IGNORE_DIRS = { ".git", "debuglog", "docs", "node_modules", ".cache" }

-- Check if running in Neovim
M.is_nvim = vim ~= nil and vim.api ~= nil

---Safe number conversion
---@param n any
---@return number
function M.safe_number(n)
  return tonumber(n) or 0
end

---Calculate percentage
---@param part number
---@param total number
---@return number
function M.percent(part, total)
  if not total or total == 0 then
    return 0
  end
  return (part / total) * 100
end

---Count words in a string
---@param s string|nil
---@return integer
function M.count_words(s)
  if not s or type(s) ~= "string" then
    return 0
  end
  local count = 0
  for _ in s:gmatch("%S+") do
    count = count + 1
  end
  return count
end

---Check if path should be ignored
---@param path string
---@return boolean
function M.should_ignore(path)
  if type(path) ~= "string" then
    return true
  end
  local lower_path = path:lower()
  for _, dir in ipairs(M.IGNORE_DIRS) do
    if lower_path:find(dir:lower(), 1, true) then
      return true
    end
  end
  return false
end

---Check if table contains value
---@param tbl table
---@param val any
---@return boolean
function M.tbl_contains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

---Get current working directory
---@return string
function M.get_cwd()
  if M.is_nvim then
    return fn.getcwd()
  end

  local success, handle = pcall(io.popen, "cd")
  if not success or not handle then
    return ""
  end
  local result = handle:read("*l") or ""
  handle:close()
  return result:gsub("\\", "/")
end

---Compute relative path from cwd
---@param full_path string
---@param cwd string
---@return string
function M.relative_path(full_path, cwd)
  if type(full_path) ~= "string" then
    return ""
  end
  local p = full_path:gsub("\\", "/")
  if cwd ~= "" and p:sub(1, #cwd) == cwd then
    return p:sub(#cwd + 2)
  end
  return p
end

---Format displayed value based on mode
---@param number number
---@param perc number
---@param mode LuaProjectFileStats.PercentMode
---@return string
function M.format_value(number, perc, mode)
  local n = M.safe_number(number)
  local p = M.safe_number(perc)

  if mode == "both" then
    return str_fmt("%d (%.1f%%)", n, p)
  elseif mode == "percent" then
    return str_fmt("%.1f%%", p)
  else
    return str_fmt("%d", n)
  end
end

---Compute percentages for stats
---@param stats LuaProjectFileStats.Stats
---@return number, number, number, number, number, number, number, number, number, number
function M.compute_percentages(stats)
  local total_lines = stats.total_lines or 0
  local total_words = stats.total_words or 0

  return M.percent(stats.lines_without_comments or 0, total_lines),
         M.percent(stats.comment_lines or 0, total_lines),
         M.percent(stats.lines_without_annotations or 0, total_lines),
         M.percent(stats.annotation_lines or 0, total_lines),
         M.percent(stats.blank_lines or 0, total_lines),
         M.percent(stats.words_without_comments or 0, total_words),
         M.percent(stats.words_without_annotations or 0, total_words),
         M.percent(stats.words_in_comments or 0, total_words),
         M.percent(stats.words_in_annotations or 0, total_words),
         M.percent(stats.words_in_blank or 0, total_words)
end

---Compute ratios for stats
---@param stats LuaProjectFileStats.FolderStats|LuaProjectFileStats.Stats
---@return LuaProjectFileStats.Ratios
function M.compute_ratios(stats)
  local total = stats.total_lines or 0
  local comments = stats.comment_lines or 0
  local annotations = stats.annotation_lines or 0
  local code = stats.lines_without_comments or 0
  local files = stats.file_count or 1

  return {
    comment_ratio = total > 0 and comments / total or 0,
    annotation_ratio = total > 0 and annotations / total or 0,
    doc_ratio = total > 0 and (comments + annotations) / total or 0,
    code_ratio = total > 0 and code / total or 0,
    avg_lines_per_file = files > 0 and total / files or 0,
    annotation_to_comment_ratio = comments > 0 and annotations / comments or 0,
  }
end

---Format deviation from average (UTF-8 safe)
---@param value number
---@param average number
---@return string
function M.format_deviation(value, average)
  local delta = value - average
  local sign = delta >= 0 and "+" or ""
  return str_fmt("%s%.1f%%", sign, delta * 100)
end

---Analyze a single Lua file
---@param filepath string
---@return LuaProjectFileStats.Stats|nil
function M.analyze_file(filepath)
  if type(filepath) ~= "string" then
    return nil
  end

  local stats = {
    total_lines = 0,
    lines_without_comments = 0,
    comment_lines = 0,
    lines_without_annotations = 0,
    annotation_lines = 0,
    blank_lines = 0,
    total_words = 0,
    words_in_comments = 0,
    words_in_annotations = 0,
    words_without_comments = 0,
    words_without_annotations = 0,
    words_in_blank = 0,
  }

  local success, fh = pcall(io.open, filepath, "r")
  if not success or not fh then
    return stats
  end

  local in_block_comment = false

  for line in fh:lines() do
    stats.total_lines = stats.total_lines + 1
    local trimmed = line:match("^%s*(.-)%s*$") or ""

    if trimmed == "" then
      stats.blank_lines = stats.blank_lines + 1
    else
      local code_part, comment_part = trimmed, ""

      -- Handle block comments
      if in_block_comment then
        comment_part = code_part
        code_part = ""
        if trimmed:find("%]%]") then
          in_block_comment = false
        end
      elseif trimmed:match("^%-%-%[%[") then
        in_block_comment = true
        comment_part = code_part
        code_part = ""
      else
        -- Handle inline comments
        local inline_pos = code_part:find("%-%-")
        if inline_pos then
          comment_part = code_part:sub(inline_pos)
          code_part = code_part:sub(1, inline_pos - 1)
        elseif trimmed:match("^%-%-") then
          comment_part = code_part
          code_part = ""
        end
      end

      local is_annotation = comment_part:match("^%-%-%-%@") ~= nil

      if is_annotation then
        stats.annotation_lines = stats.annotation_lines + 1
        stats.words_in_annotations = stats.words_in_annotations + M.count_words(comment_part)
      end

      if #comment_part > 0 then
        stats.comment_lines = stats.comment_lines + 1
        stats.words_in_comments = stats.words_in_comments + M.count_words(comment_part)
      end

      if #code_part > 0 then
        stats.lines_without_comments = stats.lines_without_comments + 1
        stats.words_without_comments = stats.words_without_comments + M.count_words(code_part)
      end

      if not is_annotation then
        stats.lines_without_annotations = stats.lines_without_annotations + 1
        stats.words_without_annotations = stats.words_without_annotations + M.count_words(code_part)
      end

      stats.total_words = stats.total_words + M.count_words(code_part) + M.count_words(comment_part)
    end
  end

  fh:close()
  return stats
end

---Get all Lua files under directory
---@param dir string
---@return string[]|nil
function M.get_lua_files(dir)
  if type(dir) ~= "string" then
    return nil
  end

  local files = {}

  if M.is_nvim then
    -- Use Neovim's fn.glob for better cross-platform support
    local pattern = dir .. "/**/*.lua"
    local found = fn.glob(pattern, false, true)

    for _, file in ipairs(found) do
      if not M.should_ignore(file) then
        table.insert(files, file)
      end
    end
  else
    -- CLI mode: use system commands
    local cmd = 'dir "' .. dir .. '" /S /B /A:-D 2>nul'
    local success, p = pcall(io.popen, cmd)

    if not success or not p then
      return nil
    end

    for file in p:lines() do
      if file:match("%.lua$") and not M.should_ignore(file) then
        table.insert(files, file)
      end
    end

    p:close()
  end

  return files
end

---Create empty stats object
---@return LuaProjectFileStats.Stats
function M.create_empty_stats()
  return {
    total_lines = 0,
    lines_without_comments = 0,
    comment_lines = 0,
    lines_without_annotations = 0,
    annotation_lines = 0,
    blank_lines = 0,
    total_words = 0,
    words_in_comments = 0,
    words_in_annotations = 0,
    words_without_comments = 0,
    words_without_annotations = 0,
    words_in_blank = 0,
  }
end

---Deep copy a table
---@param tbl table
---@return table
function M.deep_copy(tbl)
  local copy = {}
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      copy[k] = M.deep_copy(v)
    else
      copy[k] = v
    end
  end
  return copy
end

return M
