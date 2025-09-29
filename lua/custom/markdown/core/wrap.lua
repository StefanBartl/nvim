---@module 'custom.markdown.core.wrap'
--- Visual wrap helpers (e.g., bold via **). Uses set_text for minimal edits.

---@class MarkdownWrap
local M = {}

local sel = require("custom.markdown.core.selection")
local cfg = require("custom.markdown.config").get

---@param count integer
---@return nil
local function wrap_with_asterisks(count)
  local row, scol0, ecol0 = sel.get_visual_range_single_line()

  if row ~= nil and scol0 ~= nil and ecol0 ~= nil then
    ---@cast row integer
    ---@cast scol0 integer
    ---@cast ecol0 integer

    -- Single-line visual selection path
    local parts = vim.api.nvim_buf_get_text(0, row, scol0, row, ecol0 + 1, {})
    local mid = table.concat(parts, "\n")
    local pad = string.rep("*", count)
    vim.api.nvim_buf_set_text(0, row, scol0, row, ecol0 + 1, { pad .. mid .. pad })

    if cfg().keep_inner_selection then
      sel.reselect_charwise(row, scol0 + count, scol0 + count + (ecol0 - scol0))
    else
      sel.reselect_charwise(row, scol0, ecol0 + 2 * count)
    end
    return
  end

  -- No (valid) visual selection path -> operator-pending trick
  local pad = string.rep("*", count)
  local seq = vim.api.nvim_replace_termcodes("c" .. pad .. "<C-o>P" .. pad .. "<Esc>gv", true, false, true)
  vim.api.nvim_feedkeys(seq, "nx", false)

  if cfg().keep_inner_selection then
    local adjust = vim.api.nvim_replace_termcodes("o" .. string.rep("l", count) .. "o" .. string.rep("h", count), true, false, true)
    vim.api.nvim_feedkeys(adjust, "nx", false)
  end
end

---@return nil
function M.toggle_visual_bold()
  wrap_with_asterisks(2)
end

return M
