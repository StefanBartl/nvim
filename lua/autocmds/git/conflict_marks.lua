---@module 'autocmds.git.conflict_marks'
--- Highlight conflict markers (<<<<<<< / ======= / >>>>>>>) per-window and clear on leave.

---@class AutoCmds.Git.ConflictMarks
local M = {}

local api, fn = vim.api, vim.fn

---@param cfg AutoCmds.Git.ConflictMarksCfg
---@param shared table
---@return nil
function M.enable(cfg, shared)
  if not (cfg and cfg.enable) then
    return
  end

  api.nvim_create_autocmd("BufWinEnter", {
    group = shared.augroup("conflict_marks_on"),
    callback = function()
      local id_a = fn.matchadd(cfg.hl_a or "DiffDelete", [[^<<<<<<< .\+$]])
      local id_b = fn.matchadd(cfg.hl_b or "DiffChange", [[^=======\s*$]])
      local id_c = fn.matchadd(cfg.hl_c or "DiffAdd", [[^>>>>>>> .\+$]])
      vim.w._git_conflict_match_ids = { id_a, id_b, id_c }
    end,
    desc = "Git: highlight conflict markers",
  })

  api.nvim_create_autocmd("BufWinLeave", {
    group = shared.augroup("conflict_marks_off"),
    callback = function()
      local ids = vim.w._git_conflict_match_ids
      if type(ids) == "table" then
        for _, id in ipairs(ids) do
          pcall(vim.fn.matchdelete, id)
        end
      end
      vim.w._git_conflict_match_ids = nil
    end,
    desc = "Git: clear conflict marker highlights",
  })
end

return M
