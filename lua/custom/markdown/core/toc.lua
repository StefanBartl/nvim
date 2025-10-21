---@module 'custom.markdown.core.toc'
--- Generate or update a Markdown Table of Contents (TOC).
--- Respects YAML frontmatter and fenced code blocks. Produces GitHub/GFM-like
--- anchors (lowercase, punctuation removed, spaces to hyphens, collapse hyphens),
--- and appends numeric suffixes for duplicate headings using the GitHub convention:
---   first occurrence -> "slug"
---   second occurrence -> "slug-1"
---   third occurrence -> "slug-2"

---@class toc_module
---@field update_markdown_toc fun(header_line: string|nil, opts: table|nil): nil
local M = {}

---@type number
local DEFAULT_MIN_LEVEL = 2
---@type number
local DEFAULT_MAX_LEVEL = 6

--- Return true if a line is a YAML frontmatter fence (---).
---@param line string|nil
---@return boolean|nil
local function is_frontmatter_fence(line)
  return line and line:match("^%s*%-%-%-%s*$") ~= nil
end

--- Return index (1-based, last line of frontmatter) + 1 as insert start, or 0 if no frontmatter.
---@param bufnr number
---@return number
local function frontmatter_end(bufnr)
  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
  if not is_frontmatter_fence(first) then
    return 0
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 1, -1, false)
  for i = 1, #lines do
    if is_frontmatter_fence(lines[i]) then
      return i + 1
    end
  end
  return 0
end

--- Pattern for fenced code block delimiter (``` or ~~~).
---@type string
local FENCE_LINE = "^%s*([`~]{3,})%S*%s*$"

--- GitHub/GFM-like slug generator.
--- Rules implemented (approximation):
---  - Convert to lowercase.
---  - Replace spaces/tab sequences with a single hyphen.
---  - Remove punctuation and symbols (keep alphanumerics, hyphen and underscore).
---  - Collapse multiple hyphens and trim leading/trailing hyphens.
---  - Note: does not perform full unicode normalization; adequate for common ASCII/latin headings.
---@param title string
---@return string
local function slugify_gfm(title)
  -- Lowercase
  local s = title:lower()
  -- Replace any sequence of whitespace with single hyphen
  s = s:gsub("%s+", "-")
  -- Remove characters that are not letters, numbers, hyphen or underscore
  s = s:gsub("[^%w%-%_]", "")
  -- Collapse multiple hyphens
  s = s:gsub("%-+", "-")
  -- Trim leading/trailing hyphens or underscores
  s = s:gsub("^[-_]+", ""):gsub("[-_]+$", "")
  return s
end

--- Update or insert a Markdown Table of Contents.
--- header_line: the header that marks the TOC block (e.g. "## Table of content").
--- opts: optional table with fields:
---   - min_level (number) minimal heading level to include (1..6)
---   - max_level (number) maximal heading level to include (1..6)
---@param header_line string|nil
---@param opts table|nil
---@return nil
function M.update_markdown_toc(header_line, opts)
  header_line = header_line or "## Table of content"
  opts = opts or {}
  local min_level = opts.min_level or DEFAULT_MIN_LEVEL
  local max_level = opts.max_level or DEFAULT_MAX_LEVEL
  if min_level < 1 then min_level = 1 end
  if max_level > 6 then max_level = 6 end
  if min_level > max_level then
    local t = min_level
    min_level = max_level
    max_level = t
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local start_after_fm = frontmatter_end(bufnr)
  local total = vim.api.nvim_buf_line_count(bufnr)

  -- Find existing TOC block (start and end). Match header_line exactly,
  -- then remove until the next header of any level (# ...) or EOF.
  local existing_start, existing_end
  do
    local re = "^%s*" .. vim.pesc(header_line) .. "%s*$"
    for i = math.max(1, start_after_fm > 0 and (start_after_fm + 1) or 1), total do
      local l = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
      if l and l:match(re) then
        existing_start = i
        for j = i + 1, total do
          local lj = vim.api.nvim_buf_get_lines(bufnr, j - 1, j, false)[1]
          if not lj or lj:match("^%s*#%s+") then
            existing_end = j - 1
            break
          end
        end
        existing_end = existing_end or total
        break
      end
    end
  end

  if existing_start and existing_end then
    vim.api.nvim_buf_set_lines(bufnr, existing_start - 1, existing_end, false, {})
    total = vim.api.nvim_buf_line_count(bufnr)
  end

  local toc_lines = {}
  local in_fence = false
  -- seen_count stores how many times we have produced the base slug so far.
  -- We use GitHub-style numbering: first => base, second => base-1, third => base-2, ...
  local seen_count = {}

  local scan_start = math.max(1, start_after_fm > 0 and (start_after_fm + 1) or 1)
  for i = scan_start, total do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1] or ""

    if line:match(FENCE_LINE) then
      in_fence = not in_fence
    elseif not in_fence then
      local hashes, title = line:match("^(%s*#+)%s+(.*%S)")
      if hashes and title then
        local level = #hashes:gsub("%s", "")
        if level >= min_level and level <= max_level then
          local base = slugify_gfm(title)
          if base == "" then
            -- fallback: use numeric index to avoid empty anchors
            base = "section-" .. tostring(i)
          end
          local count = seen_count[base] or 0
          local anchor
          if count == 0 then
            anchor = base
          else
            -- GitHub style: second occurrence gets "-1", third gets "-2", ...
            anchor = base .. "-" .. tostring(count)
          end
          seen_count[base] = count + 1
          local indent = string.rep("  ", math.max(0, level - 1))
          table.insert(toc_lines, indent .. string.format("- [%s](#%s)", title, anchor))
        end
      end
    end
  end

  if #toc_lines == 0 then
    vim.notify("[markdown.toc] No headings found for TOC in the requested level range", vim.log.levels.INFO)
    return
  end

  local insert_at = existing_start or (start_after_fm > 0 and start_after_fm or 1)

  if not existing_start then
    for i = insert_at, total do
      local l = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
      if l and l:match("^%s*#%s+") then
        insert_at = i + 1
        break
      end
    end
  end

  local block = { header_line, "" }
  for _, l in ipairs(toc_lines) do
    block[#block + 1] = l
  end
  block[#block + 1] = ""
  block[#block + 1] = "---"
  block[#block + 1] = ""

  vim.api.nvim_buf_set_lines(bufnr, insert_at - 1, insert_at - 1, false, block)
end

return M
