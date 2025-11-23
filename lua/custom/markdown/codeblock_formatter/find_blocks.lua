---@module 'custom.markdown.codeblock_formatter.find_blocks'
--- Functions to find fenced codeblocks using Tree-sitter with a regex fallback.
--- Exposes `find_blocks_in_range(bufnr, srow, erow, supported_set, aliases, cfg)`.
--- Returns list of blocks { start_row, end_row, lang, fence_start, fence_end }.
local M = {}

local api = vim.api
local ts = vim.treesitter

-- Tree-sitter based finder: returns content-only 1-based ranges.
local function find_with_treesitter(bufnr)
  local ok, parser = pcall(ts.get_parser, bufnr, "markdown")
  if not ok or not parser then
    return nil, "no_treesitter_parser"
  end
  local tree = parser:parse()[1]
  if not tree then
    return nil, "no_tree"
  end
  local root = tree:root()
  local query_ok, query = pcall(ts.query.parse, "markdown", "(fenced_code_block) @block")
  if not query_ok or not query then
    return nil, "no_query"
  end

  local out = {}
  for _, node, _ in query:iter_captures(root, bufnr, 0, -1) do
    if node and node:type() == "fenced_code_block" then
      -- node:range returns 0-based start_row, start_col, end_row, end_col
      local s_row, _, e_row, _ = node:range()
      -- Read the whole block including fences (0-based indices)
      local lines = api.nvim_buf_get_lines(bufnr, s_row, e_row + 1, false)
      if #lines >= 1 then
        local first = lines[1]
        -- accept common chars for language id (letters, digits, -, _, +, #)
        local fence_lang = first:match("^%s*```%s*([%w_%-%+%#]+)%s*$")
        -- compute content-only indices (0-based)
        local content_start = s_row + 1
        local content_end = e_row - 1
        if content_start <= content_end then
          table.insert(out, {
            -- convert to 1-based inclusive content range
            start_row = content_start + 1,
            end_row = content_end + 1,
            lang = fence_lang and fence_lang:lower() or nil,
            fence_start = s_row + 1, -- 1-based fence line index
            fence_end = e_row + 1,   -- 1-based fence line index
          })
        end
      end
    end
  end
  return out
end

-- Regex fallback finder: returns content-only 1-based ranges.
local function find_with_regex(bufnr, srow, erow)
  srow = srow or 1
  erow = erow or api.nvim_buf_line_count(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
  local res = {}
  local i = 1
  while i <= #lines do
    local ln = lines[i]
    local lang = ln:match("^%s*```%s*([%w_%-%+%#]+)%s*$")
    if lang then
      local start_fence = srow + i - 1 -- 1-based fence line index
      local j = i + 1
      while j <= #lines and not lines[j]:match("^%s*```%s*$") do
        j = j + 1
      end
      if j <= #lines then
        local end_fence = srow + j - 1 -- 1-based fence line index
        local content_start = start_fence + 1
        local content_end = end_fence - 1
        if content_start <= content_end then
          table.insert(res, {
            start_row = content_start,
            end_row = content_end,
            lang = lang:lower(),
            fence_start = start_fence,
            fence_end = end_fence,
          })
        end
        i = j + 1
      else
        break
      end
    else
      i = i + 1
    end
  end
  return res
end

--- Public: find blocks in range with fallback and apply alias mapping + filtering by supported set.
--- supported_set: table where keys are canonical langs (true)
--- aliases: table mapping fence alias -> canonical lang
--- cfg: config table with prefer_treesitter boolean
function M.find_blocks_in_range(bufnr, srow, erow, supported_set, aliases, cfg)
  bufnr = bufnr or api.nvim_get_current_buf()
  srow = srow or 1
  erow = erow or api.nvim_buf_line_count(bufnr)
  cfg = cfg or { prefer_treesitter = true }

  local found
  if cfg.prefer_treesitter then
    found, _ = find_with_treesitter(bufnr)
    if not found then
      found = find_with_regex(bufnr, srow, erow)
    end
  else
    found = find_with_regex(bufnr, srow, erow)
  end

  local out = {}
  found = found or {}
  for _, b in ipairs(found) do
    if b.lang then
      local canonical = aliases[b.lang] or aliases[b.lang:lower()] or b.lang:lower()
      if supported_set[canonical] then
        -- clamp to requested range (content-only indexes are already 1-based)
        local s = math.max(b.start_row, srow)
        local e = math.min(b.end_row, erow)
        if s <= e then
          table.insert(out, {
            start_row = s,
            end_row = e,
            lang = canonical,
            fence_start = b.fence_start,
            fence_end = b.fence_end,
          })
        end
      end
    end
  end

  return out
end

return M
