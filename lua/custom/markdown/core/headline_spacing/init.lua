---@module 'custom.markdown.core.headline_spacing'
--- Ensures proper spacing between H2+ heading sections in Markdown buffers.
--- Adds the pattern [empty line, "---", empty line] between H2+ heading sections
--- that have actual content. Ignores headings inside fenced code blocks.

local api = vim.api
local M = {}

--- Check if a line is an H2 or higher heading (##, ###, etc.)
---@param line string The line to check
---@return boolean true if line starts with ## or more hashes
local function is_h2_or_more(line)
  -- Match lines starting with 2+ hashes followed by whitespace
  return line:match("^##+%s") ~= nil
end

--- Check if a line is any heading (including H1)
---@param line string The line to check
---@return boolean true if line starts with # followed by whitespace
local function is_heading(line)
  -- Match lines starting with any number of hashes followed by whitespace
  return line:match("^#+%s") ~= nil
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
---@return integer|nil section_end_idx 1-based index of last content line, or nil if section is empty
local function find_section_end(lines, heading_idx, next_heading_idx)
  local search_end = next_heading_idx and (next_heading_idx - 1) or #lines

  -- Search backwards from end of section to find last non-empty content line
  for i = search_end, heading_idx + 1, -1 do
    local line = lines[i] or ""
    -- Found a line with actual content (non-whitespace characters)
    if line:match("%S") then
      return i
    end
  end

  -- No content found in section (heading is followed only by empty lines)
  return nil
end

--- Check if the required separator pattern exists after a section end
--- Pattern must be: empty line, "---", empty line
---@param lines string[] All buffer lines
---@param section_end_idx integer 1-based index of last content line
---@param next_heading_idx integer|nil 1-based index of next heading (to avoid false positives)
---@return boolean has_pattern true if complete and correct pattern exists
local function has_separator_after(lines, section_end_idx, next_heading_idx)
  local desired = { "", "---", "" }

  -- Check each line of the pattern
  for i = 1, 3 do
    local line_idx = section_end_idx + i
    local line = lines[line_idx] or ""

    -- Pattern line doesn't match expected value
    if line ~= desired[i] then
      return false
    end
  end

  -- If there's a next heading, verify it comes right after the separator
  if next_heading_idx then
    local expected_heading_pos = section_end_idx + 4
    if next_heading_idx ~= expected_heading_pos then
      return false
    end
  end

  return true
end

--- Find all H2+ heading sections that need separator pattern
--- Only returns sections with actual content that lack proper separator
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

      -- Find where this heading's content section ends
      local section_end = find_section_end(lines, i, next_heading)

      -- Only process sections with actual content
      if section_end then
        -- Only add separator if there's a next heading (no separator after last section)
        if next_heading then
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
  end

  return result
end

--- Apply separator pattern to buffer for all sections that need it
---@param bufnr integer Buffer number to modify
---@param opts table|nil Options: {notify: boolean, dry_run: boolean}
---@return integer count Number of sections modified
function M.ensure_buffer(bufnr, opts)
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
    -- Adjust section_end_idx by cumulative offset from previous insertions
    local adjusted_end = section.section_end_idx + offset

    -- Calculate how many lines currently exist between section end and next heading
    local current_gap = section.next_heading_idx - section.section_end_idx - 1

    -- Determine lines of separator pattern that are missing
    local to_insert = {}

    -- Check what's already there in the gap
    local existing_pattern = {}
    for i = 1, math.min(3, current_gap) do
      local check_idx = adjusted_end + i
      existing_pattern[i] = lines[check_idx] or ""
    end

    -- Build list of missing separator lines
    for i = 1, 3 do
      if existing_pattern[i] ~= separator[i] then
        table.insert(to_insert, separator[i])
      else
        -- If this line matches, all subsequent must also match (or we rebuild entire pattern)
        -- For simplicity: if any line is wrong, insert complete pattern
        to_insert = vim.deepcopy(separator)
        break
      end
    end

    -- Remove any existing incorrect lines between section end and next heading
    local lines_to_remove = current_gap
    if lines_to_remove > 0 then
      api.nvim_buf_set_lines(
        bufnr,
        adjusted_end, -- Start removing after last content line
        adjusted_end + lines_to_remove, -- Remove all lines until next heading
        false,
        {} -- Delete lines
      )

      -- Update local lines array to reflect deletion
      for _ = 1, lines_to_remove do
        table.remove(lines, adjusted_end + 1)
      end

      -- Adjust offset for deleted lines
      offset = offset - lines_to_remove
    end

    -- Insert the correct separator pattern
    if #to_insert > 0 then
      api.nvim_buf_set_lines(
        bufnr,
        adjusted_end, -- Insert after last content line
        adjusted_end,
        false,
        to_insert
      )

      -- Update local lines array to reflect insertion
      for j = 1, #to_insert do
        table.insert(lines, adjusted_end + j, to_insert[j])
      end

      -- Adjust offset for inserted lines
      offset = offset + #to_insert
    end
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

--- Preview what would change without modifying buffer
---@param bufnr integer Buffer number to analyze
---@return table[] sections Array of sections that would be modified
function M.preview(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return M.find_sections_needing_separator(lines)
end

return M
