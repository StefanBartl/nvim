---@module 'usrcmds.migrate.notify.refactor.apply'
---@brief Apply match replacements

local M = {}

local api = vim.api

---Apply single match replacement
---@param bufnr integer
---@param match MigrateNotify.Match
---@return boolean success
function M.apply_match(bufnr, match)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local start_line = match.line
  local end_line = match.end_line
  local start_col = match.col
  local end_col = match.end_col

  local start_idx = start_line - 1
  local end_idx = end_line

  local lines = api.nvim_buf_get_lines(bufnr, start_idx, end_idx, false)

  if #lines == 0 then
    return false
  end

  local replacement = match.replacement:gsub("\n", " ")

  if start_line == end_line then
    -- Single-line replacement
    local line = lines[1]
    local before = line:sub(1, start_col)
    local after = line:sub(end_col + 1)
    local new_line = before .. replacement .. after

    api.nvim_buf_set_lines(bufnr, start_idx, start_idx + 1, false, { new_line })
  else
    -- Multi-line replacement
    local first_line = lines[1]
    local last_line = lines[#lines]

    local before = first_line:sub(1, start_col)
    local after = last_line:sub(end_col + 1)

    local new_line = before .. replacement .. after

    api.nvim_buf_set_lines(bufnr, start_idx, end_idx, false, { new_line })
  end

  return true
end

return M
