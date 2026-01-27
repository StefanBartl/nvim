---@module 'autocmds.git.gitsigns_refresh'
--- Refresh gitsigns hunks on focus/enter to keep UI accurate.

---@class AutoCmds.Git.GitsignsRefresh
local M = {}

local api = vim.api

---@param cfg AutoCmds.Git.GitsignsRefreshCfg
---@param shared table
---@return nil
function M.enable(cfg, shared)
  if not (cfg and cfg.enable) then
    return
  end

  local events = shared.norm_events(cfg.events, { "BufEnter", "FocusGained" })
  api.nvim_create_autocmd(events, {
    group = shared.augroup("gitsigns_refresh"),
    callback = function()
      local ok, gs = pcall(require, "gitsigns")
      if ok and gs.refresh then
        pcall(gs.refresh)
      end
    end,
    desc = "Git: refresh gitsigns on focus/enter",
  })
end

return M
