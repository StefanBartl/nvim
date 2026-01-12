---@module 'custom.markdown.core.headline_spacing'
--- Ensures proper spacing between H2+ heading sections in Markdown buffers.
--- Adds the pattern [empty line, "---", empty line] between H2+ heading sections.
--- Ignores headings inside fenced code blocks.

local api = vim.api
local M = {}

--- Check if a line is an H2 or higher heading (##, ###, etc.)
---@param line string The line to check
---@return boolean true if line starts with ## or more hashes
local function is_h2_or_more(line)
  -- Match lines starting with 2+ hashes followed by whitespace
  return line:match("^##+%s") ~= nil
end

--- Find the next H2+ heading after the given index
---@param lines string[] All buffer lines
---@param start_idx integer 1-based index to start searching from
---@return integer|nil next_heading_idx 1-based index of next H2+ heading, or nil if none found
local function find_next_h2_heading(lines, start_idx)
  local n = #lines
  local in_fence = false

  -- Start searching from next line after start_idx
  for i = start_idx + 1, n do
    local line = lines[i] or ""

    -- Track fence state to ignore headings in code blocks
    if line:match("^%s*```") or line:match("^%s*~~~") then
      in_fence = not in_fence
    end

    -- Return index of next H2+ heading outside of fences
    if not in_fence and is_h2_or_more(line) then
      return i
    end
  end

  -- No next H2+ heading found
  return nil
end

--- Find the end of a heading's section (last non-empty line before next H2+ heading or EOF)
---@param lines string[] All buffer lines
---@param heading_idx integer 1-based index of the heading line
---@param next_heading_idx integer|nil 1-based index of next H2+ heading, or nil if none
---@return integer section_end_idx 1-based index of last content line, or heading_idx if section is empty
local function find_section_end(lines, heading_idx, next_heading_idx)
  local search_end = next_heading_idx and (next_heading_idx - 1) or #lines

  -- Search backwards from end of section to find last non-empty content line
  for i = search_end, heading_idx + 1, -1 do
    local line = lines[i] or ""
    -- Skip separator pattern lines and empty lines
    if line ~= "---" and line:match("%S") then
      return i
    end
  end

  -- No content found in section - return heading index itself
  -- This ensures empty sections still get separators
  return heading_idx
end

--- Check if the required separator pattern exists after a section end
--- Pattern must be: empty line, "---", empty line
---@param lines string[] All buffer lines
---@param section_end_idx integer 1-based index of last content line (or heading if empty)
---@param next_heading_idx integer 1-based index of next heading
---@return boolean has_pattern true if complete and correct pattern exists
local function has_separator_after(lines, section_end_idx, next_heading_idx)
  -- Expected pattern: [content_line, empty, "---", empty, next_heading]
  -- So we need exactly 3 lines between section_end and next_heading
  local gap = next_heading_idx - section_end_idx
  if gap ~= 4 then
    return false
  end

  -- Check exact pattern
  local line1 = lines[section_end_idx + 1] or ""
  local line2 = lines[section_end_idx + 2] or ""
  local line3 = lines[section_end_idx + 3] or ""

  return line1 == "" and line2 == "---" and line3 == ""
end

--- Find all H2+ heading sections that need separator pattern
--- Processes all sections including empty ones (headings without content)
---@param lines string[] All buffer lines
---@return table[] sections Array of {heading_idx, section_end_idx, next_heading_idx} tables
function M.find_sections_needing_separator(lines)
  local n = #lines
  local result = {}
  local in_fence = false

  -- Iterate through all lines to find H2+ headings
  for i = 1, n do
    local line = lines[i] or ""

    -- Track fence state to skip headings inside code blocks
    if line:match("^%s*```") or line:match("^%s*~~~") then
      in_fence = not in_fence
    end

    -- Process H2+ headings outside of fences
    if not in_fence and is_h2_or_more(line) then
      -- Find the next H2+ heading to determine section boundary
      local next_heading = find_next_h2_heading(lines, i)

      -- Only process if there's a following heading (no separator after last section)
      if next_heading then
        -- Find where this heading's content section ends
        -- (returns heading_idx itself if section is empty)
        local section_end = find_section_end(lines, i, next_heading)

        -- Check if proper separator pattern already exists
        if not has_separator_after(lines, section_end, next_heading) then
          -- Add to list of sections needing separator
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

--- Apply separator pattern to buffer for all sections that need it
---@param bufnr integer Buffer number to modify
---@param opts table|nil Options: {notify: boolean, dry_run: boolean}
---@return integer count Number of sections modified
function M.apply_headl_separators(bufnr, opts)
  -- Parse options with defaults
  opts = opts or {}
  local notify_enabled = opts.notify ~= false
  local dry_run = opts.dry_run == true

  -- Read all lines from buffer
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find all sections that need separator pattern
  local sections = M.find_sections_needing_separator(lines)

  -- Nothing to do if all sections already have separators
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

  -- Return early if dry run (don't modify buffer)
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

  -- Define separator pattern to insert
  local separator = { "", "---", "" }

  -- Track cumulative offset as we insert lines (each insertion shifts subsequent indices)
  local offset = 0

  -- Process sections from top to bottom, adjusting for inserted lines
  for _, section in ipairs(sections) do
    -- Adjust indices by cumulative offset from previous insertions
    local adjusted_end = section.section_end_idx + offset
    local adjusted_next = section.next_heading_idx + offset

    -- Remove ALL lines between section end and next heading
    local lines_between = adjusted_next - adjusted_end - 1
    if lines_between > 0 then
      api.nvim_buf_set_lines(
        bufnr,
        adjusted_end, -- Start after last content line
        adjusted_end + lines_between, -- Remove until next heading
        false,
        {} -- Delete lines
      )

      -- Update offset for deleted lines
      offset = offset - lines_between
      -- Recalculate adjusted_next after deletion
      adjusted_next = section.next_heading_idx + offset
    end

    -- Insert the correct separator pattern (always exactly 3 lines)
    api.nvim_buf_set_lines(
      bufnr,
      adjusted_end, -- Insert after last content line (or heading if empty)
      adjusted_end, -- Insert at same position (no replacement)
      false,
      separator
    )

    -- Update offset for inserted lines
    offset = offset + 3
  end

  -- Notify user of changes
  if notify_enabled then
    vim.notify(
      string.format("headline_spacing: fixed %d sections", #sections),
      vim.log.levels.INFO,
      { title = "headline_spacing" }
    )
  end

  return #sections
end

return M
