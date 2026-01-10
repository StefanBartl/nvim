---@module 'custom.format.markdown.headlines.separators'
---@brief Ensures proper spacing between H2+ heading sections
---@description
--- Adds the pattern [empty line, "---", empty line] between H2+ heading sections.
--- Ignores headings inside fenced code blocks.
---
--- Core logic migrated from custom.markdown.core.headline_spacing

local M = {}
local api = vim.api

---Check if a line is an H2 or higher heading (##, ###, etc.)
---@param line string The line to check
---@return boolean true if line starts with ## or more hashes
local function is_h2_or_more(line)
  return line:match("^##+%s") ~= nil
end

---Find the next H2+ heading after the given index
---@param lines string[] All buffer lines
---@param start_idx integer 1-based index to start searching from
---@return integer|nil next_heading_idx 1-based index of next H2+ heading, or nil if none found
local function find_next_h2_heading(lines, start_idx)
  local n = #lines
  local in_fence = false

  for i = start_idx + 1, n do
    local line = lines[i] or ""

    if line:match("^%s*```") or line:match("^%s*~~~") then
      in_fence = not in_fence
    end

    if not in_fence and is_h2_or_more(line) then
      return i
    end
  end

  return nil
end

---Find the end of a heading's section (last non-empty line before next H2+ heading or EOF)
---@param lines string[] All buffer lines
---@param heading_idx integer 1-based index of the heading line
---@param next_heading_idx integer|nil 1-based index of next H2+ heading, or nil if none
---@return integer section_end_idx 1-based index of last content line, or heading_idx if section is empty
local function find_section_end(lines, heading_idx, next_heading_idx)
  local search_end = next_heading_idx and (next_heading_idx - 1) or #lines

  for i = search_end, heading_idx + 1, -1 do
    local line = lines[i] or ""
    if line ~= "---" and line:match("%S") then
      return i
    end
  end

  return heading_idx
end

---Check if the required separator pattern exists after a section end
---Pattern must be: empty line, "---", empty line
---@param lines string[] All buffer lines
---@param section_end_idx integer 1-based index of last content line (or heading if empty)
---@param next_heading_idx integer 1-based index of next heading
---@return boolean has_pattern true if complete and correct pattern exists
local function has_separator_after(lines, section_end_idx, next_heading_idx)
  local gap = next_heading_idx - section_end_idx
  if gap ~= 4 then
    return false
  end

  local line1 = lines[section_end_idx + 1] or ""
  local line2 = lines[section_end_idx + 2] or ""
  local line3 = lines[section_end_idx + 3] or ""

  return line1 == "" and line2 == "---" and line3 == ""
end

---Find all H2+ heading sections that need separator pattern
---Processes all sections including empty ones (headings without content)
---@param lines string[] All buffer lines
---@return Custom.Format.Markdown.Section[] sections Array of sections needing separators
function M.find_sections_needing_separator(lines)
  local n = #lines
  local result = {}
  local in_fence = false

  for i = 1, n do
    local line = lines[i] or ""

    if line:match("^%s*```") or line:match("^%s*~~~") then
      in_fence = not in_fence
    end

    if not in_fence and is_h2_or_more(line) then
      local next_heading = find_next_h2_heading(lines, i)

      if next_heading then
        local section_end = find_section_end(lines, i, next_heading)

        if not has_separator_after(lines, section_end, next_heading) then
          table.insert(result, {
            heading_idx = i,
            section_end_idx = section_end,
            next_heading_idx = next_heading,
          })
        end
      end
    end
  end

  return result
end

---Apply separator pattern to buffer for all sections that need it
---@param bufnr integer Buffer number to modify
---@param opts Custom.Format.Markdown.SeparatorOpts|nil Options
---@return integer count Number of sections modified
function M.apply_headl_separators(bufnr, opts)
  opts = opts or {}
  local notify_enabled = opts.notify ~= false
  local dry_run = opts.dry_run == true

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local sections = M.find_sections_needing_separator(lines)

  if #sections == 0 then
    if notify_enabled then
      vim.notify(
        "headline_spacing: all sections properly formatted",
        vim.log.levels.INFO,
        { title = "headline_spacing" }
      )
    end
    return 0
  end

  if dry_run then
    if notify_enabled then
      vim.notify(
        string.format("headline_spacing: would fix %d sections", #sections),
        vim.log.levels.INFO,
        { title = "headline_spacing" }
      )
    end
    return #sections
  end

  local separator = { "", "---", "" }
  local offset = 0

  for _, section in ipairs(sections) do
    local adjusted_end = section.section_end_idx + offset
    local adjusted_next = section.next_heading_idx + offset

    local lines_between = adjusted_next - adjusted_end - 1
    if lines_between > 0 then
      api.nvim_buf_set_lines(
        bufnr,
        adjusted_end,
        adjusted_end + lines_between,
        false,
        {}
      )

      offset = offset - lines_between
      adjusted_next = section.next_heading_idx + offset
    end

    api.nvim_buf_set_lines(
      bufnr,
      adjusted_end,
      adjusted_end,
      false,
      separator
    )

    offset = offset + 3
  end

  if notify_enabled then
    vim.notify(
      string.format("headline_spacing: fixed %d sections", #sections),
      vim.log.levels.INFO,
      { title = "headline_spacing" }
    )
  end

  return #sections
end

---Preview what would change without modifying buffer
---@param bufnr integer Buffer number to analyze
---@return Custom.Format.Markdown.Section[] sections Sections that would be modified
function M.preview(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return M.find_sections_needing_separator(lines)
end

return M
