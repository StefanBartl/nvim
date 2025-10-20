---@module 'custom.markdown.core.toc'

local M = {}

local function is_frontmatter_fence(line)
  return line and line:match("^%s*%-%-%-%s*$") ~= nil
end

-- Return index (1-based, last line of frontmatter) + 1 as insert start, or 0 if no fm
local function frontmatter_end(bufnr)
  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
  if not is_frontmatter_fence(first) then
    return 0
  end
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

  -- Suche existierenden TOC-Block anhand des Headers
  local existing_start, existing_end
  do
    local re = "^%s*" .. vim.pesc(header_line) .. "%s*$"
    for i = start_after_fm, total do
      local l = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
      if l and l:match(re) then
        existing_start = i
        -- Ende: bis zur nächsten H2 (##) oder EOF
        for j = i + 1, total do
          local lj = vim.api.nvim_buf_get_lines(bufnr, j - 1, j, false)[1]
          if not lj or lj:match("^##%s+") then
            existing_end = j - 1
            break
          end
        end
        existing_end = existing_end or total
        break
      end
    end
  end

  -- Alten TOC entfernen, falls vorhanden
  if existing_start and existing_end then
    vim.api.nvim_buf_set_lines(bufnr, existing_start - 1, existing_end, false, {})
    total = vim.api.nvim_buf_line_count(bufnr) -- Update total nach Löschung
  end

  -- Frischen TOC generieren, fenced code blocks ignorieren
  local toc_lines = {}
  local in_fence = false
  local seen = {}

  for i = math.max(1, start_after_fm > 0 and (start_after_fm + 1) or 1), total do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1] or ""

    if line:match(FENCE_LINE) then
      in_fence = not in_fence
    elseif not in_fence then
      local hashes, title = line:match("^(%s*#+)%s+(.*%S)")
      if hashes and title then
        local level = #hashes:gsub("%s", "")
        if level == 1 then
          goto continue
        end -- H1 ignorieren
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

  -- Insert TOC: entweder an alter TOC-Position oder nach H1 / Frontmatter
  local insert_at = existing_start or start_after_fm > 0 and start_after_fm or 1
  -- H1 suchen, falls kein bestehender TOC
  if not existing_start then
    for i = insert_at, total do
      local l = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
      if l and l:match("^#%s+") then
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
