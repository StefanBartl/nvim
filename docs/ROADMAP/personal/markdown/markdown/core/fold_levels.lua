---@module 'custom.markdown.core.fold_levels'
--- Helpers to quickly set fold visibility by heading levels.
--- Example: fold H2+ by setting 'foldlevel' to 1 (H1 open, others closed).

---@class MarkdownFoldLevels
local M = {}

local api, fn, cmd = vim.api, vim.fn, vim.cmd

--- Compute a safe foldlevel (open levels) from a list of levels to fold.
--- If levels_to_fold contains 2..6, result is 1 (only H1 stays open).
---@param levels_to_fold integer[]|nil
---@return integer
local function compute_foldlevel(levels_to_fold)
  if type(levels_to_fold) ~= "table" or #levels_to_fold == 0 then
    return 0
  end
  local min_fold = 7
  for i = 1, #levels_to_fold do
    local lv = tonumber(levels_to_fold[i]) or 7
    if lv >= 1 and lv <= 6 and lv < min_fold then
      min_fold = lv
    end
  end
  if min_fold == 7 then
    return 0
  end
  -- Keep all levels < min_fold open → foldlevel = min_fold - 1
  return math.max(0, min_fold - 1)
end

--- Apply folding such that the given heading levels are folded.
--- Example: fold_levels({2,3,4,5,6}) collapses all but H1 (foldlevel=1).
---@param levels_to_fold integer[]|nil
---@return nil
function M.fold_levels(levels_to_fold)
  if vim.bo.filetype ~= "markdown" then
    return
  end
  local buf = api.nvim_get_current_buf()
  if not (buf and api.nvim_buf_is_valid(buf)) then
    return
  end

  -- Ensure expr folding is active (non-invasive; respects existing expr).
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldenable = true

  local lvl = compute_foldlevel(levels_to_fold)
  vim.opt_local.foldlevel = lvl
  vim.opt_local.foldlevelstart = lvl

  -- Recompute folds to reflect level change; keep cursor stable.
  local view = fn.winsaveview()
  cmd("silent! normal! zx")
  fn.winrestview(view)
end

--- Convenience: fold H2+ (equivalent to fold_levels({2,3,4,5,6})).
---@return nil
function M.fold_h2_plus()
  M.fold_levels({ 2, 3, 4, 5, 6 })
end

return M
