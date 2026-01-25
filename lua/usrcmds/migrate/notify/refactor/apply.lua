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

  -- Convert to 0-based indices for API
  local start_idx = start_line - 1
  local end_idx = end_line  -- Exclusive end for nvim_buf_set_lines

  -- DEBUG: Print what we're doing
  -- print(string.format("[apply] Replacing lines [%d-%d] (0-based [%d-%d))",
  --   start_line, end_line, start_idx, end_idx))
  -- print(string.format("[apply] Replacement: %s", match.replacement))

  -- Get current line(s) for verification
  local lines = api.nvim_buf_get_lines(bufnr, start_idx, end_idx, false)

  if #lines == 0 then
    return false
  end

  -- The migrator already built the complete replacement line
  -- Replace the range [start_idx, end_idx) with the new line
  local replacement = match.replacement

  local ok = pcall(
    api.nvim_buf_set_lines,
    bufnr,
    start_idx,
    end_idx,
    false,
    { replacement }
  )

  return ok
end

return M
