---@module 'config.translate.filter'
---Provides functions to determine which line ranges may be safely translated
---when the user requests to skip code (fenced code blocks and inline code).
---
---This module focuses on a single responsibility:
---- given a buffer and a start/end line, return a list of contiguous line-range
---  tuples that do NOT belong to fenced code blocks and do NOT contain inline
---  code markers (backticks).
---
---Notes / design choices:
---- Fenced code blocks are detected by lines starting with optional whitespace
---  followed by triple backticks: '^%s*```'. This toggles a fenced-code state.
---- Inline code is detected conservatively by the presence of a backtick character
---  anywhere on the line. If a line contains inline code, the whole line is
---  skipped. (Fine-grained inline-segment translation would require per-substring
---  translation and is more complex.)
---- Returned ranges are 1-based line numbers compatible with other Neovim APIs.
local M = {}

---@param bufnr number Buffer handle
---@param start_line number 1-based start line (inclusive)
---@param end_line number 1-based end line (inclusive)
-- ---@return { {start:number, ["end"]:number} }[] list of ranges safe to translate FIX: return signatur fixen
M.get_translatable_line_ranges = function(bufnr, start_line, end_line)
  -- Validate arguments
  if not bufnr or not start_line or not end_line then
    return {}
  end

  -- fetch lines from buffer (0-indexed for api)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  local ranges = {}
  local in_fence = false
  local current_range_start = nil
  local current_range_end = nil

  for i, line in ipairs(lines) do
    local lineno = start_line + i - 1

    -- detect fenced code block delimiter (``` with optional leading spaces)
    if line:match("^%s*```") then
      -- toggle fenced state
      in_fence = not in_fence
      -- encountering fence closes any open translatable range
      if current_range_start then
        current_range_end = lineno - 1
        if current_range_end >= current_range_start then
          table.insert(ranges, { start = current_range_start, ["end"] = current_range_end })
        end
        current_range_start = nil
        current_range_end = nil
      end
      goto continue
    end

    -- skip lines inside fenced code blocks
    if in_fence then
      goto continue
    end

    -- skip lines containing inline backticks (conservative)
    if line:find("`", 1, true) then
      -- close any open range before skipping this line
      if current_range_start then
        current_range_end = lineno - 1
        if current_range_end >= current_range_start then
          table.insert(ranges, { start = current_range_start, ["end"] = current_range_end })
        end
        current_range_start = nil
        current_range_end = nil
      end
      goto continue
    end

    -- non-code line -> start or extend current range
    if not current_range_start then
      current_range_start = lineno
      current_range_end = lineno
    else
      current_range_end = lineno
    end

    ::continue::
  end

  -- close open range at end
  if current_range_start then
    if current_range_end >= current_range_start then
      table.insert(ranges, { start = current_range_start, ["end"] = current_range_end })
    end
  end

  return ranges
end

return M
