---@module 'custom.markdown.core.toc'

local M = {}

local function is_frontmatter_fence(line)
  return line and line:match("^%s*%-%-%-%s*$") ~= nil
end

-- Return index (1-based, last line of frontmatter) + 1 as insert start, or 0 if no fm
local function frontmatter_end(bufnr)
  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
  if not is_frontmatter_fence(first) then return 0 end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 1, -1, false)
  for i = 1, #lines do
    if is_frontmatter_fence(lines[i]) then
      return i + 1 -- after closing fence
    end
  end
  return 0
end

-- Fence (``` or ~~~) possibly with language: start/end marker line only.
local FENCE_LINE = "^%s*([`~]{3,})%S*%s*$"

local function slugify(title)
  local s = title:lower()
  s = s:gsub("`", ""):gsub("%s+", "-")
  s = s:gsub("[^%w%-_]", ""):gsub("%-+", "-")
  return s
end

function M.update_markdown_toc(header_line)
  local bufnr = vim.api.nvim_get_current_buf()
  header_line = header_line or "## Table of content"

  local start_after_fm = frontmatter_end(bufnr)
  local total = vim.api.nvim_buf_line_count(bufnr)

  -- Remove existing TOC block if present: it starts with `header_line`
  local existing_start, existing_end = nil, nil
  do
    local re = "^%s*" .. vim.pesc(header_line) .. "%s*$"
    for i = start_after_fm, total do
      local l = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
      if l and l:match(re) then
        existing_start = i
        -- Find end: until blank line or next heading or EOF
        for j = i + 1, total do
          local lj = vim.api.nvim_buf_get_lines(bufnr, j - 1, j, false)[1]
          if not lj or lj == "" or lj:match("^%s*#") then
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
  end

  -- Build fresh TOC skipping fenced code blocks
  local toc_lines = {}
  local in_fence = false
  local seen = {}  -- dedupe anchors

  for i = math.max(1, start_after_fm > 0 and (start_after_fm + 1) or 1), total do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1] or ""

    if line:match(FENCE_LINE) then
      in_fence = not in_fence
    elseif not in_fence then
      -- ATX headings only; H1..H6
      local hashes, title = line:match("^(%s*#+)%s+(.*%S)")
      if hashes and title then
        local level = #hashes:gsub("%s", "")
       if level == 1 then goto continue end
        local base = slugify(title)
        local n = (seen[base] or 0) + 1
        seen[base] = n
        local anchor = (n == 1) and base or (base .. "-" .. n)
        table.insert(toc_lines, string.rep("  ", math.max(0, level - 1)) .. string.format("- [%s](#%s)", title, anchor))
      end
    end
    ::continue::
  end

  if #toc_lines == 0 then
    vim.notify("[markdown.toc] No headings found for TOC", vim.log.levels.INFO)
    return
  end

  -- Insert just after H1 (or after frontmatter if no H1)
  local insert_at = start_after_fm > 0 and start_after_fm or 1
  -- find first H1
  for i = insert_at, total do
    local l = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    if l and l:match("^#%s+") then
      insert_at = i + 1
      break
    end
  end

  local block = {}
  block[#block + 1] = header_line
  block[#block + 1] = ""
  for _, l in ipairs(toc_lines) do block[#block + 1] = l end
  block[#block + 1] = ""

  vim.api.nvim_buf_set_lines(bufnr, insert_at - 1, insert_at - 1, false, block)
end

return M
