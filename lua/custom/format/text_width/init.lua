---@module 'custom.format.text_width'
--- Reflow (wrap) text in a buffer or a specified range.
--- Exports:
---   M.reflow_buffer(bufnr, width)        -- reflow entire buffer
---   M.reflow_range(bufnr, start, end, w) -- reflow only lines [start, end]
---   M.setup_user_command()               -- creates :SetTextWidth (whole buffer)
---   M.setup_range_command()              -- creates :SetTextWidthRange (range / visual)
--- Note: Hyphenation is not implemented. The algorithm preserves exact runs of blank
--- lines inside the affected region and simple list/bullet indentation heuristics.
local notify = require("lib.nvim.notify").create("[custom.format.text_width]")

local M = {}

-- Wrap a sequence of words into lines not exceeding `width`. The first line gets
-- `first_prefix` prepended; continuation lines get `cont_prefix`.
-- This routine attempts simple greedy wrapping without hyphenation.
local function wrap_words(words, width, first_prefix, cont_prefix)
  local out = {}
  local cur = first_prefix or ""
  local cur_len = #cur
  for _, w in ipairs(words) do
    local wlen = #w
    if cur_len == 0 then
      if wlen > width then
        -- word longer than width -> put on its own line (no hyphenation)
        table.insert(out, w)
      else
        cur = w
        cur_len = wlen
      end
    else
      if cur_len + 1 + wlen <= width then
        cur = cur .. " " .. w
        cur_len = cur_len + 1 + wlen
      else
        table.insert(out, cur)
        cur = cont_prefix .. w
        cur_len = #cur
        if cur_len > width then
          -- still too long -> emit and reset
          table.insert(out, cur)
          cur = ""
          cur_len = 0
        end
      end
    end
  end
  if cur ~= "" then
    table.insert(out, cur)
  end
  return out
end

-- Flatten paragraph lines into words (preserve punctuation).
-- simple whitespace tokenization.
local function paragraph_to_words(par_lines)
  local words = {}
  for _, ln in ipairs(par_lines) do
    for w in ln:gmatch("%S+") do
      table.insert(words, w)
    end
  end
  return words
end

-- Detect indentation / bullet leader for a paragraph's first line.
-- Returns (first_prefix, cont_prefix)
-- first_prefix is kept at start of wrapped first line; cont_prefix
-- is prepended to continuation lines to align text after bullets/indent.
local function detect_prefixes(first_line)
  if not first_line then
        notify.warn("[format.text_width] first_line is nil")
        return
    end
  local indent = first_line:match("^(%s*)") or ""
  local bullet = first_line:match("^%s*([%-%*%+]%s)") or first_line:match("^%s*(%d+[%.)]%s)")
  if bullet then
    local leader = indent .. bullet
    local cont = string.rep(" ", #leader)
    return leader, cont
  else
    return indent, indent
  end
end

-- Internal: reflow a list of lines (representing a contiguous region)
-- returns new list of lines with paragraphs wrapped to `width`.
local function reflow_lines_region(lines, width)
  local out = {}
  local paragraph = {}
  local para_first = nil

  local function flush_paragraph()
    if #paragraph == 0 then
      return
    end
    local first_prefix, cont_prefix = detect_prefixes(para_first)
    -- strip leading indentation/bullet from paragraph lines before tokenizing
    local stripped = {}
    for _, l in ipairs(paragraph) do
      local s = l:gsub("^%s*", "", 1)
      table.insert(stripped, s)
    end
    local words = paragraph_to_words(stripped)
    if #words == 0 then
      table.insert(out, "")
    else
      local wrapped = wrap_words(words, width, first_prefix, cont_prefix)
      vim.list_extend(out, wrapped)
    end
    paragraph = {}
    para_first = nil
  end

  local i = 1
  while i <= #lines do
    local ln = lines[i]
    if ln:match("^%s*$") then
      -- blank line -> flush para then preserve exact blank line(s)
      if #paragraph > 0 then
        flush_paragraph()
      end
      -- preserve contiguous blank lines exactly
      local j = i
      while j <= #lines and lines[j]:match("^%s*$") do
        table.insert(out, "")
        j = j + 1
      end
      i = j
    else
      if #paragraph == 0 then
        para_first = ln
      end
      table.insert(paragraph, ln)
      i = i + 1
    end
  end

  if #paragraph > 0 then
    flush_paragraph()
  end

  return out
end

-- Reflow the whole buffer to `width`. Keeps exact blank-line runs across the file.
-- this replaces the entire buffer contents atomically.
function M.reflow_buffer(bufnr, width)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  width = tonumber(width) or 0
  if width <= 0 then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local new_lines = reflow_lines_region(lines, width)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

-- Reflow only the range [start_line, end_line] (1-based, inclusive).
-- only lines inside the given range are inspected and replaced;
-- blank lines and paragraphs inside the range are preserved exactly as before except
-- for wrapping. Surrounding context outside the range is untouched.
function M.reflow_range(bufnr, start_line, end_line, width)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  start_line = tonumber(start_line) or 1
  end_line = tonumber(end_line) or start_line
  width = tonumber(width) or 0
  if width <= 0 or start_line < 1 or end_line < start_line then
    return
  end

  -- fetch the selected region (vim api uses 0-based start, end is exclusive)
  local region_lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local new_region = reflow_lines_region(region_lines, width)

  -- replace only the selected region
  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, new_region)
end

-- Create the original whole-buffer command `:SetTextWidth`
-- keeps existing behaviour for full-file reflow.
function M.setup_user_command()
  vim.api.nvim_create_user_command("FormatSetTextWidth", function(opts)
    local arg = opts.args
    if not arg or arg == "" then
      print("Usage: :SetTextWidth {N|max}")
      return
    end
    local width
    if arg == "max" or arg == "MAX" then
      width = vim.api.nvim_win_get_width(0)
    else
      width = tonumber(arg)
      if not width or width <= 0 then
        print("SetTextWidth: argument must be a positive integer or 'max'")
        return
      end
    end

    vim.bo.textwidth = width
    M.reflow_buffer(0, width)
    print("Set textwidth to " .. width .. " and reflowed buffer.")
  end, {
    nargs = 1,
    desc = "[custom.format.text_width] Set buffer-local textwidth and reflow entire buffer. Usage: :SetTextWidth {N|max}",
  })
end

-- Create the range / visual command `:SetTextWidthRange`
--
--   - This command accepts a range (e.g. `:10,20SetTextWidthRange 50`) and will only
--     reflow that line interval.
--   - It is intended to be used with a visual selection as `:'<,'>SetTextWidthRange 50`.
--   - If invoked without an explicit range, it will operate on the current line only.
function M.setup_range_command()
  vim.api.nvim_create_user_command("FormatSetTextWidthRange", function(opts)
    local arg = opts.args
    if not arg or arg == "" then
      print("Usage: :SetTextWidthRange {N|max} (use visual selection or give a range)")
      return
    end

    local width
    if arg == "max" or arg == "MAX" then
      width = vim.api.nvim_win_get_width(0)
    else
      width = tonumber(arg)
      if not width or width <= 0 then
        print("SetTextWidthRange: argument must be a positive integer or 'max'")
        return
      end
    end

    -- determine the target range (opts.line1 / opts.line2 are provided when range=true)
    local s = opts.line1 or vim.fn.line(".")
    local e = opts.line2 or vim.fn.line(".")

    -- set buffer-local textwidth (keeps behaviour consistent)
    vim.bo.textwidth = width

    M.reflow_range(0, s, e, width)
    print(string.format("Reflowed lines %d..%d to width %d", s, e, width))
  end, {
    nargs = 1,
    range = true,
    desc = "[custom.format.text_width] Set buffer-local textwidth and reflow only the given range (use visual).",
  })
end

-- Convenience: setup both commands when module is required
M.setup_user_command()
M.setup_range_command()

return M
