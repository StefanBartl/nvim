---@module 'autocmds.git.conflicts_qf'
--- Populate quickfix with files that have unresolved conflicts on startup/focus.

local notify = require("lib.nvim.notify").create("[autocmds.git.conflicts_qf]")

local M = {}

local api, fn = vim.api, vim.fn

---Register autocmds for unresolved-conflicts → quickfix population.
---@param cfg AutoCmds.Git.Conflicts.QfCfg
---@param shared table
---@return nil
function M.enable(cfg, shared)
  if not (cfg and cfg.enable) then
    return
  end

  local events = shared.norm_events(cfg.events, { "VimEnter" })
  api.nvim_create_autocmd(events, {
    group = shared.augroup("conflicts_qf"),
    callback = function()
      local git = cfg.git_cmd or "git"
      if not shared.in_git_repo(git) then
        return
      end

      local filter = cfg.diff_filter or "U"
      local cmd = string.format("%s diff --name-only --diff-filter=%s", git, filter)
      local conflicts = fn.systemlist(cmd)
      if type(conflicts) ~= "table" or #conflicts == 0 then
        return
      end

      -- Build qf items (safe array push)
      local qf = { [#conflicts] = {} }
      for i = 1, #conflicts do
        qf[i] = { filename = conflicts[i], lnum = 1, col = 1, text = "Git conflict" }
      end
      fn.setqflist(qf, "r")
      if cfg.open_qf ~= false then
        vim.cmd("copen")
      end
      if cfg.notify ~= false then
        notify.warn("Git conflicts detected:\n" .. table.concat(conflicts, "\n"))
      end
    end,
    desc = "Git: populate quickfix with unresolved conflicts",
  })
end

---@class AutoCmds.Git.ConflictsQf
return M
