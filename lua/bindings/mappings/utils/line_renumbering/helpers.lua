---@module 'bindings.mappings.utils.line_renumbering.helpers'
-- ── Helpers ──────────────────────────────────────────────────

local renumber = require("bindings.mappings.utils.line_renumbering")

local HELPERS = {}

function HELPERS.maybe_renumber()
  local ft = vim.bo.filetype
  if ft == "markdown" or ft == "markdown.mdx" or ft == "mdx" then
    renumber.renumber_list_at_cursor()
  end
end

--- Indent or outdent a single line by the buffer's current shiftwidth.
---@param bufnr integer
---@param lnum integer   1-based
---@param direction 1|-1
function HELPERS.shift_line(bufnr, lnum, direction)
  local w    = vim.bo[bufnr].shiftwidth
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  if direction == 1 then
    line = string.rep(" ", w) .. line
  else
    local remove = math.min(#(line:match("^(%s*)")), w)
    line = line:sub(remove + 1)
  end
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { line })
end

--- Indent or outdent a range of lines (visual mode).
---@param start_ln integer  1-based
---@param end_ln integer    1-based
---@param direction 1|-1
function HELPERS.shift_range(start_ln, end_ln, direction)
  local bufnr = vim.api.nvim_get_current_buf()
  for lnum = start_ln, end_ln do
    HELPERS.shift_line(bufnr, lnum, direction)
  end
end

return HELPERS
