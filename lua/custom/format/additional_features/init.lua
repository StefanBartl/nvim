---@module 'custom.format.additional_features'
---@brief Additional formatting subcommands
---@description
--- This module provides lightweight additional formatting operations:
--- • trim: Remove trailing whitespace
--- • sort: Sort lines (with optional flags)
--- • unique: Remove duplicate lines
--- • indent: Fix indentation
--- • case: Change case (upper/lower/title)

local notify = require("lib.notify").create("[custom.format.additional_features]")

local M = {}

local api = vim.api

---Remove trailing whitespace from buffer or range
---@param start_line integer|nil Start line (1-based, nil = whole buffer)
---@param end_line integer|nil End line (1-based, nil = whole buffer)
---@return integer count Number of lines modified
local function trim_whitespace(start_line, end_line)
  local buf = api.nvim_get_current_buf()
  start_line = start_line or 1
  end_line = end_line or api.nvim_buf_line_count(buf)

  local lines = api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
  local new_lines = {}
  local modified = 0

  for _, line in ipairs(lines) do
    local trimmed = line:gsub("%s+$", "")
    table.insert(new_lines, trimmed)
    if trimmed ~= line then
      modified = modified + 1
    end
  end

  api.nvim_buf_set_lines(buf, start_line - 1, end_line, false, new_lines)
  return modified
end

---Sort lines with optional flags
---@param lines string[] Lines to sort
---@param reverse boolean Reverse sort order
---@param ignore_case boolean Case-insensitive sort
---@param numeric boolean Numeric sort
---@return string[] sorted Sorted lines
local function sort_lines(lines, reverse, ignore_case, numeric)
  local sorted = vim.deepcopy(lines)

  table.sort(sorted, function(a, b)
    local val_a = a
    local val_b = b

    if ignore_case then
      val_a = a:lower()
      val_b = b:lower()
    end

    if numeric then
      local num_a = tonumber(val_a:match("^%s*(%d+)"))
      local num_b = tonumber(val_b:match("^%s*(%d+)"))
      if num_a and num_b then
        return reverse and num_a > num_b or num_a < num_b
      end
    end

    return reverse and val_a > val_b or val_a < val_b
  end)

  return sorted
end

---Remove duplicate lines (preserves first occurrence)
---@param lines string[] Lines to deduplicate
---@param ignore_case boolean Case-insensitive comparison
---@return string[] unique, integer removed_count
local function unique_lines(lines, ignore_case)
  local seen = {}
  local unique = {}
  local removed = 0

  for _, line in ipairs(lines) do
    local key = ignore_case and line:lower() or line
    if not seen[key] then
      seen[key] = true
      table.insert(unique, line)
    else
      removed = removed + 1
    end
  end

  return unique, removed
end

---Change case of text
---@param text string Input text
---@param mode "upper"|"lower"|"title"|"sentence" Case mode
---@return string transformed
local function change_case(text, mode)
  if mode == "upper" then
    return text:upper()

  elseif mode == "lower" then
    return text:lower()

  elseif mode == "title" then
    -- Title case: capitalize first letter of each word
    local result = text:gsub("(%a)([%w_']*)", function(first, rest)
      -- Uppercase first character, lowercase the remaining word
      return first:upper() .. rest:lower()
    end)
    return result

  elseif mode == "sentence" then
    -- Sentence case: capitalize first letter after punctuation
    local result = text:lower()
    result = result:gsub("^%l", string.upper)
    result = result:gsub("([.!?]%s+)(%l)", function(punct, letter)
      return punct .. letter:upper()
    end)
    return result
  end

  return text
end

---Fix indentation based on configured settings
---@param lines string[] Lines to fix
---@param use_spaces boolean Use spaces instead of tabs
---@param width integer Indentation width
---@return string[] fixed
local function fix_indentation(lines, use_spaces, width)
  local fixed = {}

  for _, line in ipairs(lines) do
    if line:match("^%s*$") then
      -- Empty line: preserve
      table.insert(fixed, "")
    else
      -- Extract current indentation
      local indent_str = line:match("^%s*") or ""
      local content = line:sub(#indent_str + 1)

      -- Count indentation level (mixed tabs/spaces to level)
      local level = 0
      for char in indent_str:gmatch(".") do
        if char == "\t" then
          level = level + 1
        elseif char == " " then
          level = level + (1 / width)
        end
      end
      level = math.floor(level + 0.5)

      -- Build new indentation
      local new_indent
      if use_spaces then
        new_indent = string.rep(" ", level * width)
      else
        new_indent = string.rep("\t", level)
      end

      table.insert(fixed, new_indent .. content)
    end
  end

  return fixed
end

---Register all additional subcommands
---@param register_fn fun(name: string, def: table) Registration function
---@return nil
function M.register_subcommands(register_fn)
  -- Trim whitespace
  register_fn("trim", {
    ---@diagnostic disable-next-line: unused-local
    handler = function(args)
      local count = trim_whitespace()
      notify.info(string.format("[custom.format.trim] Trimmed %d lines", count))
    end,
    complete = function() return {} end,
    nargs = "0",
    desc = "Remove trailing whitespace from buffer",
  })

  -- Sort lines
  register_fn("sort", {
    handler = function(args)
      local reverse = vim.tbl_contains(args, "-r") or vim.tbl_contains(args, "--reverse")
      local ignore_case = vim.tbl_contains(args, "-i") or vim.tbl_contains(args, "--ignore-case")
      local numeric = vim.tbl_contains(args, "-n") or vim.tbl_contains(args, "--numeric")

      local buf = api.nvim_get_current_buf()
      local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local sorted = sort_lines(lines, reverse, ignore_case, numeric)

      api.nvim_buf_set_lines(buf, 0, -1, false, sorted)
      notify.info("[custom.format.sort] Buffer sorted")
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead)
      local opts = { "-r", "--reverse", "-i", "--ignore-case", "-n", "--numeric" }
      local matches = {}
      for _, opt in ipairs(opts) do
        if vim.startswith(opt, arg_lead) then
          table.insert(matches, opt)
        end
      end
      return matches
    end,
    nargs = "*",
    desc = "Sort lines: sort [-r] [-i] [-n]",
  })

  -- Remove duplicates
  register_fn("unique", {
    handler = function(args)
      local ignore_case = vim.tbl_contains(args, "-i") or vim.tbl_contains(args, "--ignore-case")

      local buf = api.nvim_get_current_buf()
      local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local unique, removed = unique_lines(lines, ignore_case)

      api.nvim_buf_set_lines(buf, 0, -1, false, unique)
      notify.info(string.format("[custom.format.unique] Removed %d duplicate lines", removed))
    end,
    complete = function(arg_lead)
      if vim.startswith("--ignore-case", arg_lead) then
        return { "--ignore-case" }
      end
      if vim.startswith("-i", arg_lead) then
        return { "-i" }
      end
      return {}
    end,
    nargs = "*",
    desc = "Remove duplicate lines: unique [-i]",
  })

  -- Change case
  register_fn("case", {
    handler = function(args)
      if #args == 0 then
        notify.error("[custom.format.case] Usage: case <upper|lower|title|sentence>")
        return
      end

      local mode = args[1]
      local valid_modes = { "upper", "lower", "title", "sentence" }
      if not vim.tbl_contains(valid_modes, mode) then
        notify.error("[custom.format.case] Invalid mode: " .. mode)
        return
      end

      local buf = api.nvim_get_current_buf()
      local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local new_lines = {}

      for _, line in ipairs(lines) do
        table.insert(new_lines, change_case(line, mode))
      end

      api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
      notify.info(string.format("[custom.format.case] Changed to %s case", mode))
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead)
      return { "upper", "lower", "title", "sentence" }
    end,
    nargs = "1",
    desc = "Change case: case <upper|lower|title|sentence>",
  })

  -- Fix indentation
  register_fn("indent", {
    handler = function(args)
      local use_spaces = vim.bo.expandtab
      local width = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or vim.bo.tabstop

      -- Override with args
      if vim.tbl_contains(args, "--spaces") then
        use_spaces = true
      end
      if vim.tbl_contains(args, "--tabs") then
        use_spaces = false
      end

      for _, arg in ipairs(args) do
        local w = tonumber(arg)
        if w then
          width = w
        end
      end

      local buf = api.nvim_get_current_buf()
      local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local fixed = fix_indentation(lines, use_spaces, width)

      api.nvim_buf_set_lines(buf, 0, -1, false, fixed)
      notify.info(string.format( "[custom.format.indent] Fixed indentation (%s, width=%d)", use_spaces and "spaces" or "tabs", width ))
    end,
    complete = function(arg_lead)
      local opts = { "--spaces", "--tabs", "2", "4", "8" }
      local matches = {}
      for _, opt in ipairs(opts) do
        if vim.startswith(opt, arg_lead) then
          table.insert(matches, opt)
        end
      end
      return matches
    end,
    nargs = "*",
    desc = "Fix indentation: indent [--spaces|--tabs] [width]",
  })
end

return M
