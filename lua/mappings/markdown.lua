---@module 'mappings.markdown'

---@class MdMappingsCfg
---@field keep_inner_selection boolean  -- true: reselect inner text; false: reselect outer incl. markers
---@field restrict_to_markdown boolean  -- true: only operate in markdown buffers
---@field map_double_asterisk boolean   -- true: in Visual mode, "**" toggles bold

local M = {}

---@type MdMappingsCfg
M.cfg = {
  keep_inner_selection = true,
  restrict_to_markdown = true,
  map_double_asterisk = true,
}

-- -------------------------------------------------------------------------------------------------
-- Helpers
-- -------------------------------------------------------------------------------------------------

--- Feed raw keys with termcode translation in Normal/Visual context.
--- @param keys string
--- @return nil
local function feed(keys)
  local seq = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(seq, "nx", false)
end

--- Only run in markdown buffers (unless disabled).
--- @return boolean
local function ok_filetype()
  if not M.cfg.restrict_to_markdown then
    return true
  end
  local ft = vim.bo.filetype
  return ft == "markdown" or ft == "markdown.mdx"
end

--- Clamp a value into [lo, hi].
--- @param v integer
--- @param lo integer
--- @param hi integer
--- @return integer
local function clamp(v, lo, hi)
  if v < lo then
    return lo
  end
  if v > hi then
    return hi
  end
  return v
end

--- Reselect a single-line characterwise Visual range (0-based cols).
--- @param row integer
--- @param scol0 integer
--- @param ecol0 integer
--- @return nil
local function reselect_charwise(row, scol0, ecol0)
  -- setpos expects 1-based columns
  vim.fn.setpos("'<", { 0, row + 1, scol0 + 1, 0 })
  vim.fn.setpos("'>", { 0, row + 1, ecol0 + 1, 0 })
  -- Reselect previous Visual selection
  feed "<Esc>gv"
end

--- Get single-line Visual selection as normalized 0-based [row, scol0, ecol0].
--- Returns nil if selection spans multiple rows or is empty.
--- Handles reversed endpoints and 'selection' option (inclusive/exclusive).
--- @return integer|nil row, integer|nil scol0, integer|nil ecol0
local function get_visual_range_single_line()
  -- Get raw marks
  local p1 = vim.fn.getpos "'<" ---@type integer[]
  local p2 = vim.fn.getpos "'>" ---@type integer[]
  local srow = p1[2] - 1
  local erow = p2[2] - 1
  local scol0 = p1[3] - 1
  local ecol0 = p2[3] - 1

  if srow ~= erow then
    return nil, nil, nil
  end

  -- Normalize reversed selection
  if (erow < srow) or (erow == srow and ecol0 < scol0) then
    srow, erow = erow, srow
    scol0, ecol0 = ecol0, scol0
  end

  local row = srow
  -- Clamp columns against actual line length
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
  local len = #line
  if len == 0 then
    return nil, nil, nil
  end

  -- Convert possible exclusive selection to inclusive range on the same line
  -- (ecol0 can legally equal len-1; ensure scol0 <= ecol0)
  scol0 = clamp(scol0, 0, math.max(0, len - 1))
  ecol0 = clamp(ecol0, 0, math.max(0, len - 1))
  if ecol0 < scol0 then
    return nil, nil, nil
  end

  return row, scol0, ecol0
end

-- -------------------------------------------------------------------------------------------------
-- Core ops (unwrap/wrap) using nvim_buf_set_text
-- -------------------------------------------------------------------------------------------------

--- Try to unwrap N asterisks on both sides for a single-line selection.
--- The selection is assumed to cover only the inner text (without asterisks).
--- We check for exactly N '*' to the left and to the right and remove them.
--- @param count integer  -- 1 for italic, 2 for bold
--- @return boolean done  -- true if unwrap succeeded
local function try_unwrap_asterisks(count)
  local row, scol0, ecol0 = get_visual_range_single_line()
  if not row then
    return false
  end

  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
  local len = #line

  -- Boundaries for the markers directly outside the selection
  local left_start = scol0 - count
  local left_end = scol0 - 1
  local right_start = ecol0 + 1
  local right_end = ecol0 + count

  if left_start < 0 or right_end >= len then
    return false
  end

  local left = line:sub(left_start + 1, left_end + 1)
  local right = line:sub(right_start + 1, right_end + 1)
  local want = string.rep("*", count)
  if left ~= want or right ~= want then
    return false
  end

  -- Replace [left_start .. right_end] (exclusive end col is right_end+1) by the inner text
  local inner = line:sub(scol0 + 1, ecol0 + 1)
  vim.api.nvim_buf_set_text(0, row, left_start, row, right_end + 1, { inner })

  -- New selection: same inner text, shifted left by `count` columns
  local new_s = scol0 - count
  local new_e = new_s + (ecol0 - scol0)
  reselect_charwise(row, new_s, new_e)
  return true
end

--- Wrap current single-line Visual selection with N asterisks on both sides.
--- Uses set_text to update only the selected range.
--- @param count integer
--- @return nil
local function wrap_with_asterisks(count)
  local row, scol0, ecol0 = get_visual_range_single_line()
  if row then
    -- Extract current selected text
    local parts = vim.api.nvim_buf_get_text(0, row, scol0, row, ecol0 + 1, {})
    local mid = table.concat(parts, "\n") -- single line by contract
    local pad = string.rep("*", count)

    -- Replace selection with pad .. mid .. pad
    vim.api.nvim_buf_set_text(0, row, scol0, row, ecol0 + 1, { pad .. mid .. pad })

    if M.cfg.keep_inner_selection then
      local new_s = scol0 + count
      local new_e = new_s + (ecol0 - scol0)
      reselect_charwise(row, new_s, new_e)
    else
      local new_s = scol0
      local new_e = ecol0 + (2 * count)
      reselect_charwise(row, new_s, new_e)
    end
  else
    -- Multi-line or invalid: degrade gracefully via change operation + gv reselect
    local pad = string.rep("*", count)
    -- Wrap via a change; then reselect; optionally shrink by `count` on both sides
    feed("c" .. pad .. "<C-o>P" .. pad .. "<Esc>gv")
    if M.cfg.keep_inner_selection then
      feed("o" .. string.rep("l", count) .. "o" .. string.rep("h", count))
    end
  end
end

-- -------------------------------------------------------------------------------------------------
-- Public API
-- -------------------------------------------------------------------------------------------------

--- @param cfg MdMappingsCfg|nil
--- @return nil
function M.setup(cfg)
  M.cfg = vim.tbl_deep_extend("force", M.cfg, cfg or {})
  if M.cfg.map_double_asterisk then
    vim.keymap.set("x", "**", function()
      if not ok_filetype() then
        return
      end
      if not try_unwrap_asterisks(2) then
        wrap_with_asterisks(2)
      end
    end, { desc = "Markdown: Add ** to marked text (Visual) and reselect", silent = true })
  end
end

return M
