---@module 'usrcmds.migrate.notify.refactor'
---@brief Statement-safe application layer for notify migration
---@description
--- This refactor intentionally mirrors the old working behaviour:
---   - whole-call replacement only
---   - no partial line edits
---   - multiline replacement via exact range
---   - descending application order

require("usrcmds.migrate.notify.@types")

local M = {}

local api = vim.api

--------------------------------------------------------------------------------
-- Import handling
--------------------------------------------------------------------------------

---@param bufnr integer
---@return boolean
local function has_import(bufnr)
  for _, line in ipairs(api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
    if line:match('require%s*%(%s*["\']lib%.notify["\']%s*%)') then
      return true
    end
  end
  return false
end

---@param bufnr integer
function M.inject_import(bufnr)
  if has_import(bufnr) then
    return
  end

  api.nvim_buf_set_lines(
    bufnr,
    0,
    0,
    false,
    { 'local notify = require("lib.notify")', "" }
  )
end

--------------------------------------------------------------------------------
-- Replacement
--------------------------------------------------------------------------------

---@param bufnr integer
---@param match MigrateNotify.Match
---@return boolean
function M.apply_match(bufnr, match)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  api.nvim_buf_set_text(
    bufnr,
    match.line - 1,
    match.col,
    match.end_line - 1,
    match.end_col,
    { match.replacement }
  )

  return true
end

return M
